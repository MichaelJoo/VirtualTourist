//
//  PhotoAlbumViewController.swift
//  Virtual-Tourist
//
//  Created by Do Hyung Joo on 26/7/20.
//  Copyright © 2020 Do Hyung Joo. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var pinData: Pin!
    var pinfetchedResultsController: NSFetchedResultsController<Pin>!
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    let locationManager = CLLocationManager()
    let regioninMeters: Double = 10000
    
    @IBOutlet weak var photoMapView: MKMapView!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var photoAlbumFlowLayout: UICollectionViewFlowLayout!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPinFetchedResultsController()
        setupFetchedResultsController()
        
        photoMapView.delegate = self
        
        photoCollectionView.delegate = self
        photoCollectionView.dataSource = self
        
        //setupCollectionViewLayout()
     
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = false
        photoCollectionView.reloadData()
        
        print(pinData!)
        

    }
    

    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        pinfetchedResultsController = nil
        fetchedResultsController = nil

    }
    
    
    func setupCollectionViewLayout() {
        let layout = UICollectionViewFlowLayout()

        // Always use an item count of at least 1 and convert it to a float to use in size calculations
        let numberOfItemsPerRow: Int = 3
        let itemsPerRow = CGFloat(max(numberOfItemsPerRow,1))
        
        // Calculate the sum of the spacing between cells
        let totalSpacing = layout.minimumInteritemSpacing * (itemsPerRow - 1.0)
        
        // Calculate how wide items should be
        var newItemSize = layout.itemSize
        
        newItemSize.width = (photoCollectionView.bounds.size.width - layout.sectionInset.left - layout.sectionInset.right - totalSpacing) / itemsPerRow
        
        // Use the aspect ratio of the current item size to determine how tall the items should be
        if layout.itemSize.height > 0 {
            let itemAspectRatio = layout.itemSize.width / layout.itemSize.height
            newItemSize.height = newItemSize.width / itemAspectRatio
        }
        
        layout.itemSize = newItemSize
      
        photoCollectionView.collectionViewLayout = layout
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
        }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return pinData.photo!.count
            
        }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! PhotoCell
        
        //let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        
        //let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        //fetchRequest.sortDescriptors = [sortDescriptor]
        
        let photoForCells = fetchedResultsController.object(at: indexPath)
        
        let data = try? Data(contentsOf: photoForCells.imageURL!)
    
        cell.photoImageView.image = UIImage(data: data!)
        cell.photoImageView.contentMode = UIView.ContentMode.scaleAspectFill
        //cell.photoImageView.clipsToBounds = true
        //cell.photoImageView.translatesAutoresizingMaskIntoConstraints = true
        //cell.photoImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        cell.backgroundColor = .white
        
        return cell
        
    }

}

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    
    fileprivate func setupFetchedResultsController() {
        
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: "Photo")
        
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetched could not be executed: \(error.localizedDescription)")
        }
        
    }
    
    fileprivate func setupPinFetchedResultsController() {
        
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        pinfetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        pinfetchedResultsController.delegate = self
        
        do {
            try pinfetchedResultsController.performFetch()
        } catch {
            fatalError("The fetched could not be executed: \(error.localizedDescription)")
        }
        
    }
    
}


extension PhotoAlbumViewController: MKMapViewDelegate, CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        let center = CLLocationCoordinate2D(latitude: pinData.latitude, longitude: pinData.longitude)
        let region = MKCoordinateRegion.init(center: center, latitudinalMeters: regioninMeters, longitudinalMeters: regioninMeters)
        photoMapView.setRegion(region, animated: true)
        
    }
    
    
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        print("setupLocationManager")
    }
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let pin = MKPointAnnotation()
        photoMapView = mapView
        
        let reuseID = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKPinAnnotationView
        
        //piece of code under "if" is largely redundant as there is no long press feature to add any new pin, but it is copy-and-pasted to ensure consistency in pin design - to test
        if pinView == nil {
            
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
            pinView!.pinTintColor = .red
            pinView!.isDraggable = false
            pinView!.canShowCallout = false
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        
            
        } else {
            
            pinData.title = annotation.title!
            pinData.subtitle = annotation.subtitle!
            pinData.latitude = annotation.coordinate.latitude
            pinData.longitude = annotation.coordinate.longitude
            pinData.creationDate = Date()
            pinView!.annotation = annotation
        }
        
        mapView.addAnnotation(pin)
        print(pin)
        return pinView
        
    }
    
    
}

