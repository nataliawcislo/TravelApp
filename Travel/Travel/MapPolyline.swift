//
//  MapPolyline.swift
//  Travel
//
//  Created by Natalia on 11.09.24.
//

import Foundation
import MapKit

struct MapPolyline: Identifiable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
}
