//
//  SGAnnotation.swift
//  SpotSale Go
//
//  Created by Ben-Anthony Donnelly on 04/09/2022.
//

import Foundation
import MapKit

class SGAnnotation: MKPointAnnotation {
    var contactIdReference = String()
    var location:CLLocation?
}
