//
//  ToolController.swift
//  SpotSale Go
//
//  Created by Ben-Anthony Donnelly on 13/09/2022.
//

import Foundation
import UIKit
import Contacts

protocol ToolControllerDelegate {
    func toolControllerDidPressRoute()
}

class ToolController:UIViewController {
    var delegate:ToolControllerDelegate?
    override func viewDidLoad() {
        super.viewDidLoad()
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(blurEffectView)
        
        let button = UIBarButtonItem(title: "Create Route", style: .plain, target: self, action: #selector(createRoute))
        navigationItem.rightBarButtonItem = button
    }
    
    @objc func createRoute() {
        delegate?.toolControllerDidPressRoute()
    }
    
    func openContact(contact:CNContact) {
        let contactVC = ContactViewController(nibName: nil, bundle: nil)
        contactVC.contact = contact
        self.navigationController?.pushViewController(contactVC, animated: true)
        
        guard let presentationController = self.navigationController?.presentationController as? UISheetPresentationController else { return }
        presentationController.animateChanges {
            presentationController.selectedDetentIdentifier = .medium
        }
    }
}
