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

class PhotoAlbumViewController: UIViewController, UICollectionViewDelegate, NSFetchedResultsControllerDelegate, UICollectionViewDataSource {
    
    
    var pinData: Pin!
    
    @IBOutlet weak var photoMapView: MKMapView!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var photoAlbumFlowLayout: UICollectionViewFlowLayout!
    
    
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupFetchedResultsController()
        
        photoCollectionView.delegate = self
        photoCollectionView.dataSource = self
        
        setupCollectionViewLayout()
     
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = false
        photoCollectionView.reloadData()

    }
    

    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil

    }
    
    func setupCollectionViewLayout() {
                let spacing: CGFloat = 3
                let width = UIScreen.main.bounds.width
                let layout = UICollectionViewFlowLayout()
                layout.sectionInset = UIEdgeInsets(top: spacing, left: spacing, bottom: 50, right: spacing)
                let numberOfItems: CGFloat = 3
                let itemSize = (width - (spacing * (numberOfItems+1))) / numberOfItems
                layout.itemSize = CGSize(width: itemSize, height: itemSize)
                layout.minimumInteritemSpacing = spacing
                layout.minimumLineSpacing = spacing
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
        
        cell.backgroundColor = .white
        
        return cell
        
    }

  
}
