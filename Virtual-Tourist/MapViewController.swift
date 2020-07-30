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


class MapViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate, NSFetchedResultsControllerDelegate {

    
    @IBOutlet weak var mapView: MKMapView!
    
    var fetchedResultsController: NSFetchedResultsController<Pin>!

    
    let locationManager = CLLocationManager()
    let geoCoder = CLGeocoder()
    let regioninMeters: Double = 10000
    let places = CLLocation()
    
    fileprivate func setupFetchedResultsController() {
        
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: "Pin")
        
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetched could not be executed: \(error.localizedDescription)")
        }
        
    }
    
    
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
        
        setupFetchedResultsController()
        
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil

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
            
        findAddress(annotation: annotation)
        
        }
        
    }
    

    func findAddress(annotation: MKPointAnnotation) {
        
        let locationforAdress = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
        
        geoCoder.reverseGeocodeLocation(locationforAdress, completionHandler: { (placemarks, error) -> Void in
        
            if (error) == nil {

                // Place details
                var placeMark: CLPlacemark!
                placeMark = placemarks?[0]
                
                let address = "\(placeMark?.country ?? ""),\(placeMark?.subAdministrativeArea ?? ""), \(placeMark?.thoroughfare ?? ""), \(placeMark?.postalCode ?? "")"
                
                annotation.title = address
                
                }
            }
        )
    }
    
    func addPin(annotation: MKPointAnnotation) {
            
        let pinData = Pin(context: DataController.shared.viewContext)
        
        pinData.title = annotation.title
        pinData.subtitle = annotation.subtitle
        pinData.latitude = annotation.coordinate.latitude
        pinData.longitude = annotation.coordinate.longitude
        pinData.creationDate = Date()
        
        try? DataController.shared.viewContext.save()
        
        print(pinData.latitude)
        print(pinData.longitude)
        print(pinData.creationDate!)
        print(pinData.self)
        
       
            VirtualTouristClient.SearchPhoto(longitude: pinData.longitude, Latitude: pinData.latitude) { (photo, error) in
                
                print("SearchPhoto API Executed")
                
                if photo.count == 0 {
                    
                    let alertVC = UIAlertController(title: "No Images", message: "No Image to display", preferredStyle: .alert)
                    self.present(alertVC, animated: true, completion: nil)
                    
                } else {
                    
                    for images in photo {
                    
                    let photoData = Photo(context: DataController.shared.viewContext)
                    
                    //let rawflickerImageURLAddress = "https://farm{\(images.farm)}.staticflickr.com/{\(images.server)}/{\(images.id)}_{\(images.secret)}.jpg"
                        
                    let flickerImageURLAddress = URL(string:"https://farm\(images.farm).staticflickr.com/\(images.server)/\(images.id)_\(images.secret).jpg")!
                    
                  
                    print(images.id)

                    photoData.pin = pinData
                        
                    photoData.creationDate = pinData.creationDate
                    photoData.imageURL = flickerImageURLAddress
                        
                    try? DataController.shared.viewContext.save()
                    print(photoData)
                    
                    }
                    
                }
 
        }

    
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
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        
            
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
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        //TBD to segue to PhotoAlbumView Controller
        
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let PhotoAlbumViewController = storyBoard.instantiateViewController(withIdentifier: "PhotoAlbumView") as! PhotoAlbumViewController
        self.present(PhotoAlbumViewController, animated: true, completion: nil)
        
        //pass the parameters of the selected/clicked pin to PhotoAlbumViewController upon clicking on disclosure detail
        
            let pins = fetchedResultsController.fetchedObjects
                
            let annotation = mapView.selectedAnnotations[0]
                
            guard let indexPath = pins!.firstIndex(where: { (pinData) -> Bool in
                    
                    pinData.latitude == annotation.coordinate.latitude && pinData.longitude == annotation.coordinate.longitude
                    
                }) else {
                print("pin data not passed")
                    return
                }
            
            PhotoAlbumViewController.pinData = pins![indexPath]
            
            print("pin data passed")
        
    
    }

}

