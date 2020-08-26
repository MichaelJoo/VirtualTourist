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

    
    @IBAction func backButton(_ sender: UIBarButtonItem) {
        //dismiss current viewcontroller to return to the previous one, this method is used to return to previous viewcontroller if you used self.present(yourViewController, animated: true, completion: nil)to present the current viewcontroller. This method of programmatically presenting previous view controller ensures that data/pin are retained
        
        //Another method of presenting the previous viewcontroller is using self.navigationController?.popViewController(animated: true) if one used self.navigationController?.pushViewController(yourViewController, animated: true) to present the current viewcontroller.
        
        //If these methods of going 1 view controller back is not sufficient, one can use "for _ in" methods to loop through all view controllers and pop to the specific viewcontroller one wants to go over
        
        self.dismiss(animated: true, completion: nil)
        
        //Method to remove photos related to currently selected pin. Need to check whether this method should be at this backbutton or ViewDidDisappear()
        
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        
        // it must be noted that "pinData", which is variable using Pin entity data structure was sufficient to identify the exact Pin within fetchedResultsObjects although it is questionnable whether Pindata.id should be used, Xcode didn't have such feature.
        let predicate = NSPredicate(format: "pin == %@", pinData)
        fetchRequest.predicate = predicate
        
        let objects = try? DataController.shared.viewContext.fetch(fetchRequest)
        
        for obj in objects! {
            DataController.shared.viewContext.delete(obj)
        }
        
        try? DataController.shared.viewContext.save()
        
        print("before delete")
        print(pinData.photo!)
        print("Delete photo executed")
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPinFetchedResultsController()
        setupFetchedResultsController()
       
        setupLocationManager()
        locationManager.startUpdatingLocation()
        
        photoMapView.delegate = self
        photoCollectionView.delegate = self
        photoCollectionView.dataSource = self
        
        //setupCollectionViewLayout()
        print(pinData!.self)
        print("photoalbumview loaded")
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: pinData.latitude, longitude: pinData.longitude)
        photoMapView.addAnnotation(annotation)
     
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        photoCollectionView.reloadData()
        

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
        return fetchedResultsController.sections?.count ?? 1
        }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        let photoData = fetchedResultsController.fetchedObjects
        
        print(photoData!.count)
        
        return photoData!.count
            
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            
        deletePhoto(at: indexPath)
        print("delete selected photo")
    
    }

}

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    
    func deletePhoto(at indexPath: IndexPath) {
        
        let photoToDelete = fetchedResultsController.object(at: indexPath)
        DataController.shared.viewContext.delete(photoToDelete)
        try? DataController.shared.viewContext.save()
        
    }
    
    fileprivate func setupFetchedResultsController() {
        
        var fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        
        // it must be noted that "pinData", which is variable using Pin entity data structure was sufficient to identify the exact Pin within fetchedResultsObjects although it is questionnable whether Pindata.id should be used, Xcode didn't have such feature. 
        let predicate = NSPredicate(format: "pin == %@", pinData)
        fetchRequest.predicate = predicate
        
        fetchRequest = Photo.fetchRequest()
        fetchRequest.returnsObjectsAsFaults = false
        
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: "\(pinData!)-Photo")
        
        fetchedResultsController.delegate = self

        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetched could not be executed: \(error.localizedDescription)")
        }
        
        print(pinData!.self)
        print("pindata printed")
        print(pinData!.photo!.self)
        print("photo printed")
        print(pinData!.photo!.count)
        
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
        
        //Below lines of code never called as this method was never triggered.
        
        let pin = MKPointAnnotation()
        
        setupPinFetchedResultsController()
        
        let reuseID = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKPinAnnotationView
        
        //piece of code under "if" is largely redundant as there is no long press feature to add any new pin, but it is copy-and-pasted to ensure consistency in pin design - to test
        if pinView == nil {
            
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
            pinView!.pinTintColor = .red
            pinView!.isDraggable = false
            pinView!.canShowCallout = false
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            
            print("pinView nil")
            

            pinView!.annotation = pin

            
        } else {

            print("pinView not nil")
        }

        print("mapView Viewfor Annotation")
        return pinView
        
    }
    
    
}

