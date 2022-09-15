//
//  SheetNavigationController.swift
//  SpotSale Go
//
//  Created by Ben-Anthony Donnelly on 13/09/2022.
//

import Foundation
import UIKit

protocol SheetNavigationControllerDelegate {
    func didUpdateSelectionIdentifier(detent:UISheetPresentationController.Detent.Identifier?)
}

class SheetNavigationController:UINavigationController, UISheetPresentationControllerDelegate, UIViewControllerTransitioningDelegate {
    var sheetNavDelegate:SheetNavigationControllerDelegate?
    let minimum: UISheetPresentationController.Detent = ._detent(withIdentifier: "Test1", constant: 200.0)
    let small: UISheetPresentationController.Detent = ._detent(withIdentifier: "Test2", constant: 100.0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationBar.prefersLargeTitles = true
        
        presentationConfig()
    }
    
    func presentationConfig() {
        if let presentationController = self.presentationController as? UISheetPresentationController {
            presentationController.detents = [
                .medium(),
                .large(),
            ]
            
            if #available(iOS 16, *) {
                presentationController.detents.append(
                    .custom(resolver: { context in
                        return 200
                    })
                )
                presentationController.detents.append(
                    .custom(resolver: { context in
                        return 100
                    })
                )
            }else{
                presentationController.detents.insert(minimum, at: 0)
                presentationController.detents.insert(small, at: 0)
            }
            
            presentationController.largestUndimmedDetentIdentifier = .large
            presentationController.prefersScrollingExpandsWhenScrolledToEdge = true
            presentationController.prefersGrabberVisible = true
            presentationController.delegate = self
        }
    }
    
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return false
    }
    
    func sheetPresentationControllerDidChangeSelectedDetentIdentifier(_ sheetPresentationController: UISheetPresentationController) {
        sheetNavDelegate?.didUpdateSelectionIdentifier(detent: sheetPresentationController.selectedDetentIdentifier)
    }
}
