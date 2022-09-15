//
//  MainMapView.swift
//  SpotSale Go
//
//  Created by Ben-Anthony Donnelly on 04/09/2022.
//

import Foundation
import MapKit
import Contacts

protocol SGMapDelegate {
    func didUpdate(radius:Double, center:CLLocationCoordinate2D)
}

class MainMapView: MKMapView {
    var sgDelegate:SGMapDelegate?
    var selectedAnnotation:MKPointAnnotation?
    var sgAnnotations:[SGAnnotation] = []
    private var autoRouteMode:Bool = false
    private var routeMode:Bool = false
    var radiusCircle:MKCircle?
    var centerMark:MKCircle?
    var radius:Float = 100
    var centerPointView:UIView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        centerPointView = UIView(frame: CGRect(x: self.center.x-5, y: self.center.y-5, width: 10, height: 10))
        centerPointView?.backgroundColor = .black
        centerPointView?.layer.cornerRadius = 5
        centerPointView?.isHidden = true
        self.addSubview(centerPointView!)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setContacts(_ contacts:[CNContact]) {
        for i in 0..<contacts.count {
            let contact = contacts[i]
            guard contact.postalAddresses.count > 0 else {print("no address"); continue}
            
            let values = contact.postalAddresses[0].value
            let address = "\(values.street), \(values.city), \(values.state), \(values.postalCode), \(values.country)"
            let id = contact.identifier
            
            let geoCoder = CLGeocoder()
            geoCoder.geocodeAddressString(address) { (placemarks, error) in
                // Process Response
                guard
                    let placemarks = placemarks,
                    let location = placemarks.first?.location
                else {
                    print("error")
                    return
                }
                let annotation = SGAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: location.coordinate.latitude,
                                                               longitude: location.coordinate.longitude)
                annotation.contactIdReference = id
                self.addAnnotation(annotation)
                
                annotation.location = CLLocation(latitude: location.coordinate.latitude,
                                                 longitude: location.coordinate.longitude)
                annotation.title = contact.givenName + " " + contact.familyName
                self.sgAnnotations.append(annotation)
            }
        }
    }
    
    func setRouteMode(state:Bool) {
        routeMode = state
        centerPointView!.isHidden = routeMode ? false : true
    }
    
    func setAutoRouteMode(state:Bool) {
        autoRouteMode = state
        guard autoRouteMode else {
            if radiusCircle != nil {
                self.removeOverlay(radiusCircle!)
            }
            return
        }
        
        let newRadius = getRadius()
        
        radiusCircle = MKCircle(center: self.centerCoordinate, radius: CLLocationDistance(newRadius))
        self.addOverlay(radiusCircle!)
        
        sgDelegate?.didUpdate(radius: newRadius, center: self.centerCoordinate)
    }
    
    func updateCircle() {
        if autoRouteMode == false {return}
        if radiusCircle != nil {
            self.removeOverlay(radiusCircle!)
        }
        
        let newRadius = getRadius()
        
        radiusCircle = MKCircle(center: self.centerCoordinate, radius: CLLocationDistance(newRadius))
        self.addOverlay(radiusCircle!)
        
        sgDelegate?.didUpdate(radius: newRadius, center: self.centerCoordinate)
    }
    
    private func getRadius() -> Double {
        let latitudeCircumference = 40075160 * cos(self.region.center.latitude * .pi / 180)
        var newRadius = self.region.span.longitudeDelta * latitudeCircumference / 360
        newRadius = newRadius * 0.45
        return newRadius
    }
}
