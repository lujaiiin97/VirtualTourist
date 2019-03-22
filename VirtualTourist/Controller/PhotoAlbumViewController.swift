//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by MAC on 26/01/2019.
//  Copyright © 2019 MAC. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController , UICollectionViewDataSource , UICollectionViewDelegate {
    
    var reachability : Reachability!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var noImageLable: UILabel!
    var dataController: DataController!
    
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    var pin: Pin!
    var page = 0
    var UrlArray = [URL]()
    var photos: [Photo] = [Photo]()
    var selectedPhotos = [IndexPath]()
    var totalPages: Int? = nil
    private var blockOperations: [BlockOperation] = []
    
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", self.pin)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
            
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        newCollectionButton.isEnabled = false
        setupFetchedResultsController()
        if self.fetchedResultsController.fetchedObjects?.count == 0 {
            getPhotosFromFlikr()
        }
        else {
            self.newCollectionButton.isEnabled = true
        }
        createAnnotation()
        setFlowLayout()
        collectionView.allowsMultipleSelection = true
    }
    
    func setFlowLayout(){
        let space:CGFloat = 3.0
        let dimension = (view.frame.size.width - (2 * space)) / 3.0
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
    }
    
    func getPhotosFromFlikr() {
        self.reachability = Reachability.init()
        if((self.reachability!.connection) == .none){
            debugPrint ("No Internet Connection!")
            self.showInfo(withTitle: "No Internet Connection", withMessage: "Please Try again!")
        }
        activityIndicator.hidesWhenStopped = true
        activityIndicator.center = self.view.center
        activityIndicator.startAnimating()
        

        page = page + 1
        FlickrClient.sharedInstance().FlickerPhotos(latitude: pin.latitude, longitude: pin.longitude,totalPages: page) { ( success, photoData,NoPhotoMessage, errorString , data)  in
            
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
            }
            
            if success {
                if NoPhotoMessage == nil {
                    DispatchQueue.main.async {
                        self.noImageLable.isHidden = true
                    }
                    if let photo = photoData as? [PhotoParse] {
                        for i in photo {
                            self.UrlArray.append(URL(string: i.url_m)!)
                            self.addPhotosToCoreData(url: i.url_m)
                        }
                    }
                }else {
                    DispatchQueue.main.async {
                        self.noImageLable.isHidden = false
                        self.noImageLable.text = NoPhotoMessage
                    }
                }
            }
            
        }
    }
    
    
    @IBAction func newCollectionTapped(_ sender: UIButton) {
        if sender.currentTitle == "New Collection" {
            guard let fetchedResults = self.fetchedResultsController.fetchedObjects else {
                return
            }
            
            UrlArray.removeAll()
            
            for i in fetchedResults {
                dataController.viewContext.delete(i)
                try? dataController.viewContext.save()
            }
            
            getPhotosFromFlikr()
            
        } else if sender.currentTitle == "Remove Selected Pictures" {
            
            sender.setTitle("New Collection", for: .normal)
            deletePhotos()
        }
        
    }
    
    
    func createAnnotation(){
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2DMake(pin.latitude, pin.longitude)
        self.mapView.addAnnotation(annotation)
        
        
        
        let coredinate:CLLocationCoordinate2D = CLLocationCoordinate2DMake(pin.latitude, pin.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.07, longitudeDelta: 0.07)
        let region = MKCoordinateRegion(center: coredinate, span: span)
        self.mapView.setRegion(region, animated: true)
        
    }
    
    
    func addPhotosToCoreData(url:String) {
        var arrayData = self.fetchedResultsController.fetchedObjects!
        DispatchQueue.main.async {
            let photo = Photo(context: self.dataController.viewContext)
            photo.pin = self.pin
            photo.date = Date()
            photo.imageURL = url
            arrayData.append(photo)
        }
        do
        {
            try dataController.viewContext.save()
        }
        catch
        {
            print(error)
        }
    }
    
    
    func deletePhotos() {
        var photosToDelete: [Photo] = [Photo]()
        for i in selectedPhotos {
            photosToDelete.append(fetchedResultsController.object(at: i))
        }
        
        for i in photosToDelete {
            dataController.viewContext.delete(i)
            try? dataController.viewContext.save()
        }
        selectedPhotos.removeAll()
    }
    
    deinit {
        for operation: BlockOperation in blockOperations {
            operation.cancel()
        }
        blockOperations.removeAll(keepingCapacity: false)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if let sectionInfo = self.fetchedResultsController.sections?[section] {
            return sectionInfo.numberOfObjects
            
        }
        return 0
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photosCell", for: indexPath) as! PhotoCell
        cell.imageFlikr.image = nil
        cell.activityIndicator.startAnimating()
        
        
        cell.selectedView.isHidden = true
        let photo = fetchedResultsController.object(at: indexPath)
        DispatchQueue.main.async {
            cell.activityIndicator.startAnimating()
        }
        if let data = photo.imageData {
            DispatchQueue.main.async {
                cell.imageFlikr.image = UIImage(data: data)
                cell.activityIndicator.stopAnimating()
            }
            
            
        } else {
            FlickrClient.sharedInstance().downloadImage(url: URL(string: photo.imageURL!)!) { (data, error) in
                if let _ = error {
                    cell.activityIndicator.stopAnimating()
                } else{
                    DispatchQueue.main.async {
                        photo.imageData = data
                    }
                    try? self.dataController.viewContext.save()
                    DispatchQueue.main.async {
                        cell.imageFlikr.image =  UIImage(data: data!)
                        cell.activityIndicator.stopAnimating()
                    }
                }
            }
        }
        return cell
    }
    
    
    func showInfo(withTitle: String = "Info", withMessage: String, action: (() -> Void)? = nil) {
        performUIUpdatesOnMain {
            let alert = UIAlertController(title: withTitle, message: withMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {(alertAction) in
                action?()
            }))
            self.present(alert, animated: true)
        }
    }
    
    func performUIUpdatesOnMain(_ updates: @escaping () -> Void) {
        DispatchQueue.main.async {
            updates()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let cell = collectionView.cellForItem(at: indexPath) as! PhotoCell
        cell.selectedView.isHidden = false
        newCollectionButton.setTitle("Remove Selected Pictures", for: .normal)
        selectedPhotos.append(indexPath)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! PhotoCell
        cell.selectedView.isHidden = true
        selectedPhotos.remove(at: indexPath.startIndex)
        
        if selectedPhotos.count == 0 {
            newCollectionButton.setTitle("New Collection", for: .normal)
        }
    }
}

extension PhotoAlbumViewController:NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        blockOperations.removeAll(keepingCapacity: false)
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        
        let op: BlockOperation
        switch type {
        case .insert:
            guard let newIndexPath = newIndexPath else { return }
            op = BlockOperation { self.collectionView.insertItems(at: [newIndexPath]) }
            
        case .delete:
            guard let indexPath = indexPath else { return }
            op = BlockOperation { self.collectionView.deleteItems(at: [indexPath]) }
        case .move:
            guard let indexPath = indexPath,  let newIndexPath = newIndexPath else { return }
            op = BlockOperation { self.collectionView.moveItem(at: indexPath, to: newIndexPath) }
        case .update:
            guard let indexPath = indexPath else { return }
            op = BlockOperation { self.collectionView.reloadItems(at: [indexPath]) }
        }
        
        blockOperations.append(op)
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.performBatchUpdates({
            self.blockOperations.forEach { $0.start() }
        }, completion: { finished in
            self.blockOperations.removeAll(keepingCapacity: false)
        })
    }
    
    
}


