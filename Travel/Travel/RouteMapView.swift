//
//  RouteMapView.swift
//  Travel
//
//  Created by Natalia on 11.09.24.
//

import SwiftUI
import MapKit


struct RouteMapView: UIViewRepresentable {
    var route: MKRoute
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.setRegion(MKCoordinateRegion(route.polyline.boundingMapRect), animated: true)
        mapView.addOverlay(route.polyline)
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // Tutaj możesz dodać dodatkowe aktualizacje mapy
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: RouteMapView
        
        init(_ parent: RouteMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .blue
                renderer.lineWidth = 5
                return renderer
            }
            return MKOverlayRenderer()
        }
    }
}
