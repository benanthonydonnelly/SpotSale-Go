//
//  RouteViewController.swift
//  SpotSale Go
//
//  Created by Ben-Anthony Donnelly on 04/09/2022.
//

import Foundation
import UIKit
import Contacts
import CoreLocation
import MapKit

protocol RouteControllerDelegate {
    func routeVCDidToggleAutoMode(state:Bool)
    func routeVCDidDismiss()
    func routeVCDidStartRoute(first:CLLocationCoordinate2D, second:CLLocationCoordinate2D)
}

class RouteViewController:UIViewController {
    var delegate:RouteControllerDelegate?
    var routeStops:[RouteObject] = []
    var tableView:UITableView?
    let contactManager = ContactManager()
    var currentLocation:CLLocation?
    var areaSlider:UISlider?
    var autoRouteMode = false
    var startRouteButton:UIButton?
    var startCoordinate:CLLocationCoordinate2D
    var autoButton:UIButton?
    
    init(startCoordinate:CLLocationCoordinate2D) {
        self.startCoordinate = startCoordinate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(blurEffectView)
        
        self.navigationItem.title = "Route"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .close,
                                                                 target: self,
                                                                 action: #selector(closeSheet))
        
        if let navigationController = self.navigationController as? SheetNavigationController {
            navigationController.sheetNavDelegate = self
        }

        createTable()
        createControls()
    }
    
    func createTable() {
        tableView = UITableView(frame: CGRect(x: 0, y: 80, width: view.frame.width, height: view.frame.height-80))
        tableView?.delegate = self
        tableView?.dataSource = self
        tableView?.dragDelegate = self
        tableView?.dragInteractionEnabled = true
        tableView?.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 140, right: 0)
        tableView?.backgroundColor = .clear
        view.addSubview(tableView!)
        
        // Add a start point row to the header
//        let header = SGRouteHeaderView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 60))
//        tableView?.tableHeaderView = header
    }
    
    func updateAutoRoute(objects:[RouteObject]) {
        routeStops = bubbleSort(list: objects)
        
        tableView?.reloadData()
    }
    
    func addStop(_ stop:SGAnnotation) {
        for i in routeStops {
            if i.contact.identifier == stop.contactIdReference {
                return
            }
        }
        
        if let contact = contactManager.getContact(identifier: stop.contactIdReference) {
            let distance = currentLocation?.distance(from: stop.location ?? CLLocation())
            let kilometers = (distance ?? 0)/1000
            
            var object = RouteObject(contact: contact, annotation: stop)
            object.distance = kilometers
            routeStops.append(object)
            tableView?.reloadData()
        }
    }
    
    func updateUserLocation(userLocation:MKUserLocation?) {
        currentLocation = userLocation?.location
    }
    
    @objc func closeSheet() {
        self.delegate?.routeVCDidToggleAutoMode(state: false)
        self.dismiss(animated: true)
        delegate?.routeVCDidDismiss()
    }
    
    func openContact(contact:CNContact) {
        let contactVC = ContactViewController(nibName: nil, bundle: nil)
        contactVC.contact = contact
        self.navigationController?.pushViewController(contactVC, animated: true)
        
        guard let presentationController = self.navigationController?.presentationController as? UISheetPresentationController else { return }
        print("present")
        presentationController.animateChanges {
            presentationController.selectedDetentIdentifier = .medium
        }
    }
}

extension RouteViewController {
    func createControls() {
        autoButton = UIButton(frame: CGRect(x: view.frame.size.width - 110, y: 140, width: 90, height: 35))
        autoButton?.layer.cornerRadius = 17.5
        autoButton?.layer.borderWidth = 2
        autoButton?.layer.borderColor = UIColor.gray.cgColor
        autoButton?.backgroundColor = .clear
        autoButton?.setTitleColor(.gray, for: .normal)
        autoButton?.setTitle("auto", for: .normal)
        autoButton?.addTarget(self, action: #selector(toggleAutoMode(sender:)), for: .touchUpInside)
        
        let button = UIBarButtonItem(customView: autoButton!)
        navigationItem.leftBarButtonItem = button
        
        let screenHeight = UIScreen.main.bounds.height
        startRouteButton = UIButton(frame: CGRect(x: 20,
                                                  y: screenHeight/2 - 50,
                                                  width: view.frame.width - 40,
                                                  height: 50))
        startRouteButton?.layer.cornerRadius = 10
        startRouteButton?.backgroundColor = .blue
        startRouteButton?.setTitle("Start Route", for: .normal)
        startRouteButton?.addTarget(self, action: #selector(startRoute), for: .touchUpInside)
        view.addSubview(startRouteButton!)
    }
    
    @objc func toggleAutoMode(sender:UIButton) {
        autoRouteMode = autoRouteMode ? false : true
        self.navigationItem.title = autoRouteMode ? "Auto Route" : "Route"
        
        let color = UIColor(named: "voltGreenColor") ?? .yellow
        
        sender.backgroundColor = autoRouteMode ? color : .clear
        sender.setTitleColor(autoRouteMode ? .black : .gray, for: .normal)
        sender.layer.borderColor = autoRouteMode ? color.cgColor : UIColor.gray.cgColor
        sender.setTitle(autoRouteMode ? "end" : "auto", for: .normal)
        
        sender.tintColor = autoRouteMode ? .gray : color
        self.delegate?.routeVCDidToggleAutoMode(state: autoRouteMode)
    }
    
    @objc func startRoute() {
        guard routeStops.count >= 1 else {return}
        
        self.navigationItem.title = "Route"
        
        autoButton!.backgroundColor = .clear
        autoButton!.setTitleColor(.gray, for: .normal)
        autoButton!.layer.borderColor = UIColor.gray.cgColor
        autoButton!.setTitle("auto", for: .normal)
        autoButton!.tintColor = .gray
        
        autoRouteMode = false
        self.delegate?.routeVCDidToggleAutoMode(state: autoRouteMode)
        self.delegate?.routeVCDidStartRoute(first: startCoordinate, second: routeStops[0].annotation.coordinate)
    }
}

extension RouteViewController:UITableViewDelegate, UITableViewDataSource, UITableViewDragDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        routeStops.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "Cell")

        if (cell == nil) {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
            cell!.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
            cell?.backgroundColor = .clear
        }
        
        let object = routeStops[indexPath.row]

        cell!.textLabel!.text = object.contact.givenName + " " + object.contact.familyName
        if let distance = object.distance {
            cell!.detailTextLabel!.text = String(Int(distance)) + "km"
        }
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let object = routeStops[indexPath.row]
        openContact(contact: object.contact)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let dragItem = UIDragItem(itemProvider: NSItemProvider())
        dragItem.localObject = routeStops[indexPath.row]
        return [ dragItem ]
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        // Update the model
        let mover = routeStops.remove(at: sourceIndexPath.row)
        routeStops.insert(mover, at: destinationIndexPath.row)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            routeStops.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
}

extension RouteViewController: SheetNavigationControllerDelegate {
    func didUpdateSelectionIdentifier(detent: UISheetPresentationController.Detent.Identifier?) {
        guard let detent = detent else {return}
        guard startRouteButton != nil else {return}
        
        let screenHeight = UIScreen.main.bounds.height
        
        UIView.animate(withDuration: 0.3) {
            switch detent {
            case .medium:
                self.startRouteButton!.isHidden = false
                self.startRouteButton!.frame = CGRect(x: self.startRouteButton!.frame.origin.x,
                                                      y: screenHeight/2 - 50,
                                                      width: self.startRouteButton!.frame.width,
                                                      height: self.startRouteButton!.frame.height)
                break
            case .large:
                self.startRouteButton!.isHidden = false
                self.startRouteButton!.frame = CGRect(x: self.startRouteButton!.frame.origin.x,
                                                      y: screenHeight - 140,
                                                      width: self.startRouteButton!.frame.width,
                                                      height: self.startRouteButton!.frame.height)
                break
            default:
                self.startRouteButton!.isHidden = true
                break
            }
        }
    }
}

struct RouteObject {
    let contact:CNContact
    let annotation:SGAnnotation
    var distance:Double?
}

// MARK: Bubble Sort
extension RouteViewController {
    // Compares adjacent pairs and swaps them until sorted
    func bubbleSort(list:[RouteObject]) -> [RouteObject] {
        guard list.count >= 2 else {
            return list
        }
        
        var sortedList = list
        for i in (1..<sortedList.count) {
            for index in (0..<sortedList.count - i) {
                let object = sortedList[index]
                let nextObject = sortedList[index + 1]
                if let oDistance = object.distance, let nDistance = nextObject.distance {
                    if oDistance > nDistance {
                        sortedList.swapAt(index, index+1)
                    }
                }
            }
        }
        
        return sortedList
    }
}
