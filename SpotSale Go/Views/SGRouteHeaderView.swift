//
//  SGRouteHeaderView.swift
//  SpotSale Go
//
//  Created by Ben-Anthony Donnelly on 14/09/2022.
//

import Foundation
import UIKit

class SGRouteHeaderView: UIView {
    var latitudeLabel:UITextView?
    var longitudeLabel:UITextView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(stackView)
        
        self.layer.borderColor = UIColor.red.cgColor
        
        latitudeLabel = UITextView()
        latitudeLabel!.text = "wadwa"
        latitudeLabel!.heightAnchor.constraint(equalToConstant: self.frame.height).isActive = true
        latitudeLabel!.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(latitudeLabel!)
        
        longitudeLabel = UITextView()
        longitudeLabel!.heightAnchor.constraint(equalToConstant: self.frame.height).isActive = true
        longitudeLabel!.translatesAutoresizingMaskIntoConstraints = false
        longitudeLabel!.text = "12wadwa"
        stackView.addArrangedSubview(longitudeLabel!)
        
        stackView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        stackView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        stackView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        stackView.heightAnchor.constraint(equalToConstant: 50).isActive = true
                
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
