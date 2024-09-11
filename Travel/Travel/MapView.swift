//
//  MapView.swift
//  Travel
//
//  Created by Natalia on 11.09.24.
//
import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    var routes: [MKRoute]
    @Binding var region: MKCoordinateRegion
    @Binding var selectedStartLocation: Location?
    @Binding var selectedEndLocation: Location?
    @Binding var isSelectingStartLocation: Bool
    @Binding var isSelectingEndLocation: Bool
    @Binding var userLocation: CLLocation?

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        
        init(parent: MapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let routeOverlay = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: routeOverlay)
                renderer.strokeColor = .blue
                renderer.lineWidth = 5.0
                return renderer
            }
            return MKOverlayRenderer()
        }
        
        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            parent.userLocation = userLocation.location
        }
        
        @objc func handleMapTap(_ sender: UITapGestureRecognizer) {
            let location = sender.location(in: sender.view)
            if let mapView = sender.view as? MKMapView {
                let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
                
                if parent.isSelectingStartLocation {
                    parent.selectedStartLocation = Location(coordinate: coordinate)
                    parent.isSelectingStartLocation = false
                } else if parent.isSelectingEndLocation {
                    parent.selectedEndLocation = Location(coordinate: coordinate)
                    parent.isSelectingEndLocation = false
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleMapTap(_:)))
        mapView.addGestureRecognizer(tapGestureRecognizer)
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        print("Updating map view")
        uiView.removeOverlays(uiView.overlays)
        uiView.removeAnnotations(uiView.annotations)
        
        print("Setting region to: \(region)")
        uiView.setRegion(region, animated: true)
        
        for route in routes {
            print("Adding route overlay")
            uiView.addOverlay(route.polyline)
        }
        
        if let userLocation = userLocation {
            print("Adding user location annotation at: \(userLocation.coordinate)")
            let userLocationAnnotation = MKPointAnnotation()
            userLocationAnnotation.coordinate = userLocation.coordinate
            userLocationAnnotation.title = "Your Location"
            uiView.addAnnotation(userLocationAnnotation)
        }
        
        if let startLocation = selectedStartLocation {
            print("Adding start location annotation at: \(startLocation.coordinate)")
            let startAnnotation = MKPointAnnotation()
            startAnnotation.coordinate = startLocation.coordinate
            startAnnotation.title = "Start"
            uiView.addAnnotation(startAnnotation)
        }
        
        if let endLocation = selectedEndLocation {
            print("Adding end location annotation at: \(endLocation.coordinate)")
            let endAnnotation = MKPointAnnotation()
            endAnnotation.coordinate = endLocation.coordinate
            endAnnotation.title = "End"
            uiView.addAnnotation(endAnnotation)
        }
    }
}
