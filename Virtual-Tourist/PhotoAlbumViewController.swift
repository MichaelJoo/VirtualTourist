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
        
        // it must be noted that "pinData", which is variable using Pin entity data structure was sufficient to identify the exact Pin within fetchedResultsObjects although it is questionnable whether Pindata.id should be used, Xcode didn't have such feature.
        
        //let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        //let predicate = NSPredicate(format: "pin == %@", pinData)
        //fetchRequest.predicate = predicate
        
        //let objects = try? DataController.shared.viewContext.fetch(fetchRequest)
        
        //for obj in objects! {
            //DataController.shared.viewContext.delete(obj)
        //}
        
        //try? DataController.shared.viewContext.save()
        
    }
    
    @IBAction func newCollection(_ sender: UIBarButtonItem) {
        //add codes to "refresh" images in the collectionView
        
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pinData)
        fetchRequest.predicate = predicate
        
        let objects = try? DataController.shared.viewContext.fetch(fetchRequest)
        
        for obj in objects! {

            DataController.shared.viewContext.delete(obj)
            try? DataController.shared.viewContext.save()
            print("delete photo completed")
            
        }
        self.photoCollectionView.reloadData()
        print("refresh photo triggered")
        
       addPhotos(Pin: pinData, longitude: pinData.longitude, latitude: pinData.latitude)
        
       
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
    
    func addPhotos (Pin: Pin, longitude: Double, latitude: Double) {
        
        
        VirtualTouristClient.SearchPhoto(longitude: longitude, Latitude: latitude) { (photo, error) in
            
            print("SearchPhoto API Executed")
            
            if photo.count == 0 {
                
                let alertVC = UIAlertController(title: "No Images", message: "No Image to display", preferredStyle: .alert)
                self.present(alertVC, animated: true, completion: nil)
                
            } else {
                
                for images in photo {
                
                let photoData = Photo(context: DataController.shared.viewContext)
                
                //let rawflickerImageURLAddress = "https://farm{\(images.farm)}.staticflickr.com/{\(images.server)}/{\(images.id)}_{\(images.secret)}.jpg"
                    
                let flickerImageURLAddress = URL(string:"https://farm\(images.farm).staticflickr.com/\(images.server)/\(images.id)_\(images.secret).jpg")!

                photoData.pin = Pin
                photoData.creationDate = Pin.creationDate
                photoData.imageURL = flickerImageURLAddress
                  
                    
                try? DataController.shared.viewContext.save()
                self.photoCollectionView.reloadData()
                
                }
                
            }
        }
        
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
        
        print("number of items in section", section, photoData!.count)
        
        return photoData!.count
            
        }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! PhotoCell
        
        let photoForCells = fetchedResultsController.object(at: indexPath)
        
        let data = try? Data(contentsOf: photoForCells.imageURL!)
    
        cell.photoImageView.image = UIImage(data: data!)
        cell.photoImageView.contentMode = UIView.ContentMode.scaleAspectFill
        
        //image size issue is solved by using "CustomLayout" which can be a boilerplate
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

    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            photoCollectionView.insertItems(at: [newIndexPath!])
        case .delete:
            photoCollectionView.deleteItems(at: [indexPath!])
        case .move:
            photoCollectionView.moveItem(at: indexPath!, to: newIndexPath!)
        case .update:
            photoCollectionView.reloadItems(at: [newIndexPath!])
        @unknown default:
            fatalError("")
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let indexSet = IndexSet(integer: sectionIndex)
        switch type {
        case .insert: photoCollectionView.insertSections(indexSet)
        case .delete: photoCollectionView.deleteSections(indexSet)
        case .update, .move:
            fatalError("Invalid change type in controller(_:didChange:atSectionIndex:for:). Only .insert or .delete should be possible.")
        }
    }

    
    fileprivate func setupFetchedResultsController() {
        
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        
        // it must be noted that "pinData", which is variable using Pin entity data structure was sufficient to identify the exact Pin within fetchedResultsObjects although it is questionnable whether Pindata.id should be used, Xcode didn't have such feature.
  
        let predicate = NSPredicate(format: "pin == %@", pinData)
        fetchRequest.predicate = predicate
        
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
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
        
        NSFetchedResultsController<NSFetchRequestResult>.deleteCache(withName: nil)
        
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
    }
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        //Below lines of code never called as this method was never triggered.
        
        let pin = MKPointAnnotation()
        
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

