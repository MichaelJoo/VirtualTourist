//
//  MapViewController.swift
//  Virtual-Tourist
//
//  Created by Do Hyung Joo on 14/6/20.
//  Copyright © 2020 Do Hyung Joo. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreLocation
import CoreData


class MapViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate {

    
    @IBOutlet weak var mapView: MKMapView!
    
    var dataController: DataController!
    
    let locationManager = CLLocationManager()
    let regioninMeters: Double = 10000
    let places = CLLocation()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.handleTap(gestureRecognizer:)))
        
        gestureRecognizer.minimumPressDuration = 1.5
        gestureRecognizer.delegate = self
        mapView.addGestureRecognizer(gestureRecognizer)
        
        mapView.delegate = self
        checkLocationServices()
        print("viewDidload")
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        print("setupLocationManager")
    }
    
    func centerViewUserLocation() {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion.init(center:location, latitudinalMeters: regioninMeters, longitudinalMeters: regioninMeters)
            mapView.setRegion(region, animated: true)
            
            print("centerViewUserLocation")
        }
    }
    
    
    func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            setupLocationManager()
            checkLocationAuthorization()
            print("checkLocationServices")
        } else {
            //show alert to user to inform they have to turn location manager on
        }
    }
    
    func checkLocationAuthorization() {
        switch CLLocationManager.authorizationStatus() {
            
        case .authorizedWhenInUse:
            //make changes to fix the initial location for the app here
            //mapView.showsUserLocation = true
            centerViewUserLocation()
            locationManager.startUpdatingLocation()
            print("checkLocationAuthorization")
            break
        case .denied:
            // show alert instructing them how to turn on permission
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            break
        case .restricted:
            //show alert instruction them how to turn on permission
            break
        case .authorizedAlways:
            break
            
        @unknown default:
            fatalError()
            break
        }
    }
    
    @objc func handleTap(gestureRecognizer: UILongPressGestureRecognizer) {
        
        if gestureRecognizer.state == UIGestureRecognizer.State.ended {
        
        let location = gestureRecognizer.location(in: mapView)
        let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
        
        // Add annotation:
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        
        //Add annotation to Pin Data model
            
        addPin(annotation: annotation)
            
        }
        
    }
    
    func addPin(annotation: MKPointAnnotation) {
        
        let pinData = Pin(context: dataController.viewContext)
        
        annotation.coordinate = CLLocationCoordinate2DMake(pinData.latitude, pinData.longitude)
        try? dataController.viewContext.save()
        
        print(pinData.latitude)
        print(pinData.longitude)
    
    }

}

extension MapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion.init(center: center, latitudinalMeters: regioninMeters, longitudinalMeters: regioninMeters)
        mapView.setRegion(region, animated: true)
        
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
        print("checkLocationAuthorization2")
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let pin = MKPointAnnotation()
        
        let reuseID = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKPinAnnotationView

        if pinView == nil {
            
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
            pinView!.pinTintColor = .red
            pinView!.animatesDrop = true
            pinView!.isDraggable = true
            pinView!.canShowCallout = true
            
        } else {
            
            pinView!.annotation = annotation
        }
            
        mapView.addAnnotation(pin)
        return pinView

    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationView.DragState, fromOldState oldState: MKAnnotationView.DragState) {
        
        if newState == MKAnnotationView.DragState.ending && newState ==  MKAnnotationView.DragState.canceling {
            
            view.dragState = MKAnnotationView.DragState.none
            
        }
        
    }
    
    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, didChangeDragState newState: MKAnnotationView.DragState, fromOldState oldState: MKAnnotationView.DragState) {
        switch (newState) {
        case .starting:
            view.dragState = .dragging
        case .ending, .canceling:
            view.dragState = .none
        default: break
        }
    }

}

