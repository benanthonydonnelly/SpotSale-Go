//
//  ViewController.swift
//  SpotSale Go
//
//  Created by Ben-Anthony Donnelly on 03/09/2022.
//

import UIKit
import Contacts
import MapKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {
    let backgroundQueue = DispatchQueue(label: "backgroundQueue")
    let contactManager = ContactManager()
    var map:MainMapView?
    var justLoaded = true
    var routeMode = false
    var routeOverlay:MKPolyline?
    var selectedPlaces:[SGAnnotation] = []
    private var locationManager: CLLocationManager!
    private var currentLocation: CLLocation?
    
    var areaSlider:UISlider?
    
    var routeViewController:RouteViewController?
    var toolController:ToolController?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        createUIElements()
        setupManagers()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presentToolController()
    }
    
    func presentToolController() {
        toolController = ToolController(nibName: nil, bundle: nil)
        toolController!.delegate = self
        
        let toolNC = SheetNavigationController(rootViewController: toolController!)
        toolNC.modalPresentationStyle = .pageSheet
        present(toolNC, animated: true, completion: nil)
    }
    
    func createUIElements() {
        map = MainMapView(frame: view.bounds)
        map!.delegate = self
        map!.sgDelegate = self
        map!.showsUserLocation = true
        contactManager.getContacts() { contacts in
            self.map!.setContacts(contacts)
        }
        view.addSubview(map!)
        
        let locationButton = UIButton(frame: CGRect(x: view.frame.width - 60,
                                                    y: UIApplication.shared.statusBarFrame.height + 60,
                                                    width: 50,
                                                    height: 50))
        locationButton.layer.cornerRadius = 25
        locationButton.backgroundColor = .white
        locationButton.tintColor = .systemBlue
        locationButton.addTarget(self, action: #selector(moveToCurrentLocation), for: .touchUpInside)
        view.addSubview(locationButton)
        
        let largeConfig = UIImage.SymbolConfiguration(pointSize: 15, weight: .bold, scale: .large)
        let largeBoldDoc = UIImage(systemName: "location", withConfiguration: largeConfig)
        locationButton.setImage(largeBoldDoc, for: .normal)
    }
    
    @objc func moveToCurrentLocation() {
        if let location = map?.userLocation.coordinate {
            let region = MKCoordinateRegion(center: location,
                                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            map?.setRegion(region, animated: true)
        }
    }
    
    @objc func createRoute() {
        print("createRoute")
        toolController?.dismiss(animated: true)
        
        routeMode = true
        map?.setRouteMode(state: true)
        routeViewController = RouteViewController(startCoordinate: map!.centerCoordinate)
        routeViewController?.delegate = self
        routeViewController?.updateUserLocation(userLocation: map?.userLocation)
        
        let routeNC = SheetNavigationController(rootViewController: routeViewController!)
        routeNC.modalPresentationStyle = .pageSheet
        present(routeNC, animated: true, completion: nil)
        
        guard let presentationController = routeNC.presentationController as? UISheetPresentationController else { return }
        presentationController.animateChanges {
            presentationController.selectedDetentIdentifier = .medium
        }
    }
    
    func setupManagers() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest

        // Check for Location Services
        backgroundQueue.async {
            if CLLocationManager.locationServicesEnabled() {
                self.locationManager.requestWhenInUseAuthorization()
                self.locationManager.startUpdatingLocation()
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        map?.updateCircle()
        routeViewController?.startCoordinate = mapView.centerCoordinate
    }
}

// MARK: ToolControllerDelegate

extension ViewController: ToolControllerDelegate {
    func toolControllerDidPressRoute() {
        createRoute()
    }
}

// MARK: RouteControllerDelegate

extension ViewController: RouteControllerDelegate {
    func routeVCDidStartRoute(first: CLLocationCoordinate2D, second: CLLocationCoordinate2D) {
        showRouteOnMap(pickupCoordinate: first, destinationCoordinate: second)
    }
    
    func routeVCDidToggleAutoMode(state: Bool) {
        map?.setAutoRouteMode(state: state)
    }
    
    func routeVCDidDismiss() {
        map?.setRouteMode(state: false)
        routeMode = false
        presentToolController()
        
        if routeOverlay != nil {
            map?.removeOverlay(routeOverlay!)
        }
    }
}

// MARK: SheetViewControllerDelegate

extension ViewController: ContactViewControllerDelegate {
    func didDismissSheet() {
        map?.deselectAnnotation(map?.selectedAnnotation, animated: true)
    }
}

// MARK: Map Delegate

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let a = view.annotation as? SGAnnotation else {return}
        guard let contact = contactManager.getContact(identifier:a.contactIdReference) else {return}
        map?.selectedAnnotation = a
        
        if routeMode {
            routeViewController?.addStop(a)
        }else{
            map?.setCenter(a.coordinate, animated: true)
            
            if toolController != nil {
                toolController!.openContact(contact: contact)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last, justLoaded == true {
            let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            let region = MKCoordinateRegion(center: center,
                                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            map?.setRegion(region, animated: true)
            
            justLoaded = false
        }
    }
    
    func drawRoute(routeData: [SGAnnotation]) {
        if selectedPlaces.count == 0 {
            print("🟡 No Coordinates to draw")
            return
        }

        var coordinates:[CLLocationCoordinate2D] = []
        for place in selectedPlaces {
            coordinates.append(place.coordinate)
        }
        
        if coordinates.count == 2 {
            showRouteOnMap(pickupCoordinate: coordinates[0], destinationCoordinate: coordinates[1])
        }
    }
    
    func showRouteOnMap(pickupCoordinate: CLLocationCoordinate2D, destinationCoordinate: CLLocationCoordinate2D) {
        let sourcePlacemark = MKPlacemark(coordinate: pickupCoordinate, addressDictionary: nil)
        let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate, addressDictionary: nil)

        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)

        let directionRequest = MKDirections.Request()
        directionRequest.source = sourceMapItem
        directionRequest.destination = destinationMapItem
        directionRequest.transportType = .automobile

        // Calculate the direction
        let directions = MKDirections(request: directionRequest)

        directions.calculate {
            (response, error) -> Void in

            guard let response = response else {
                if let error = error {
                    print("Error: \(error)")
                }

                return
            }

            let route = response.routes[0]
            self.routeOverlay = route.polyline
            self.map!.addOverlay(self.routeOverlay!, level: MKOverlayLevel.aboveRoads)

            let rect = route.polyline.boundingMapRect
            self.map!.setRegion(MKCoordinateRegion(rect), animated: true)
        }
    }

    // MARK: - MKMapViewDelegate

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = UIColor(red: 17.0/255.0, green: 147.0/255.0, blue: 255.0/255.0, alpha: 1)
            renderer.lineWidth = 5.0
            return renderer
        }else if overlay is MKCircle {
            let renderer = MKCircleRenderer(overlay: overlay)
//            renderer.strokeColor = UIColor(named: "voltGreenColor") ?? .yellow
            renderer.strokeColor = .black
            renderer.fillColor = UIColor(named: "voltGreenColor")?.withAlphaComponent(0.3) ?? .yellow.withAlphaComponent(0.3)
            return renderer
        }else{
            return MKOverlayRenderer()
        }
    }
}


extension ViewController:SGMapDelegate {
    func didUpdate(radius: Double, center: CLLocationCoordinate2D) {
        var valid:[RouteObject] = []
        
        for annotation in map!.sgAnnotations {
            guard let location = annotation.location else {print("no location"); return}
            if let contact = contactManager.getContact(identifier: annotation.contactIdReference) {
                let center = CLLocation(latitude: center.latitude, longitude: center.longitude)
                let distance = center.distance(from: location)
                
                if distance < radius {
                    let object = RouteObject(contact: contact, annotation: annotation, distance: distance/1000)
                    valid.append(object)
                }
            }
        }
        routeViewController?.updateAutoRoute(objects: valid)
    }
}
