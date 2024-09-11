//
//  Location.swift
//  Travel
//
//  Created by Natalia on 11.09.24.
//

import Foundation
import MapKit
import CoreLocation


struct Location: Equatable {
    var coordinate: CLLocationCoordinate2D

    // Automatically synthesized by Swift
    static func == (lhs: Location, rhs: Location) -> Bool {
        return lhs.coordinate.latitude == rhs.coordinate.latitude &&
               lhs.coordinate.longitude == rhs.coordinate.longitude
    }
}

