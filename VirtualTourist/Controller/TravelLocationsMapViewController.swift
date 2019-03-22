//
//  TravelLocationsMapViewController.swift
//  VirtualTourist
//
//  Created by MAC on 26/01/2019.
//  Copyright © 2019 MAC. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController , NSFetchedResultsControllerDelegate  , MKMapViewDelegate{
    
    
    @IBOutlet weak var mapView: MKMapView!
    var dataController: DataController!
    var annotations = [MKAnnotation]()
    var pinSelected: Pin!
    var reachability: Reachability?
    var fetchedResultsController: NSFetchedResultsController<Pin>!
    
    fileprivate func setUpFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "PinData")
        fetchedResultsController.delegate = self
        do{
            try fetchedResultsController.performFetch()
        }catch{
            fatalError("The fetch could not be performed : \(error.localizedDescription)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let longGesture = UILongPressGestureRecognizer(target: self, action:
            #selector(longTap(_:)))
        mapView.addGestureRecognizer(longGesture)
        setUpFetchedResultsController()
        ShowSavedPin()
        
        self.reachability = Reachability.init()
        
        if ((self.reachability!.connection) != .none){
        }else {
            self.showInfo(withTitle: "No Internet Connection", withMessage: "Please Try again!")
            
        }
        
        
        
        switch self.reachability!.connection{
        case .wifi:
            debugPrint("via Wi-Fi")
        case .cellular:
            debugPrint (" via cellular")
        case .none:
            debugPrint ("not available")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpFetchedResultsController()
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if (segue.identifier == "Photos" ) {
            if let vc = segue.destination as? PhotoAlbumViewController {
                vc.dataController = dataController
                vc.pin = pinSelected
            }
        }
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
    func ShowSavedPin(){
        if let lastPin = fetchedResultsController.fetchedObjects?.first {
            zoomToLastPin(lastPin: lastPin)
        }
        for L in fetchedResultsController.fetchedObjects! {
            
            let latitude = L.latitude
            let longitude = L.longitude
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            self.annotations.append(annotation)
        }
        DispatchQueue.main.async {
            self.mapView.addAnnotations(self.annotations)
        }
    }
    
    func zoomToLastPin(lastPin:Pin){
        let center:CLLocationCoordinate2D = CLLocationCoordinate2DMake(lastPin.coordinate.latitude, lastPin.coordinate.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 3.0, longitudeDelta: 3.0)
        let region = MKCoordinateRegion(center: center, span: span)
        self.mapView.setRegion(region, animated: true)
        
    }
    
    func addPinToCData(longitude: Double , latitude: Double) {
        let pin = Pin(context: dataController.viewContext)
        
        pin.latitude = latitude
        pin.longitude = longitude
        pin.date = Date()
        
        do
        {
            try dataController.viewContext.save()
        }
        catch
        {
            print(error)
        }
    }
    
    @objc func longTap(_ sender: UIGestureRecognizer){
        if sender.state == .ended {
            
            let touched = sender.location(in: mapView)
            let coordinate = mapView.convert( touched, toCoordinateFrom: mapView)
            
            addPinToCData(longitude: coordinate.longitude , latitude: coordinate.latitude)
            
        }
        
    }
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.pinTintColor = .red
        }
        else {
            pinView!.annotation = annotation
        }
        
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        
        let annotation = view.annotation
        let annotationLat = annotation?.coordinate.latitude
        let annotationLong = annotation?.coordinate.longitude
        if let result = fetchedResultsController.fetchedObjects {
            for pin in result {
                if pin.latitude == annotationLat && pin.longitude == annotationLong {
                    pinSelected = pin
                    performSegue(withIdentifier: "Photos", sender: self)
                    
                    break
                }
            }
        }
    }
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        guard let pin = anObject as? Pin else {
            preconditionFailure("All changes observed in the map view controller should be for Point instances")
        }
        
        
        switch type {
        case .insert:
            DispatchQueue.main.async {
                self.mapView.addAnnotation(pin)
            }
        case .delete:
            mapView.removeAnnotation(pin)
        case .update:
            mapView.removeAnnotation(pin)
            mapView.addAnnotation(pin)
            
        case .move: break
            
        }
    }
}

extension Pin: MKAnnotation {
    public var coordinate: CLLocationCoordinate2D {
        let latDegrees = CLLocationDegrees(latitude)
        let longDegrees = CLLocationDegrees(longitude)
        return CLLocationCoordinate2D(latitude: latDegrees, longitude: longDegrees)
        
    }
}


