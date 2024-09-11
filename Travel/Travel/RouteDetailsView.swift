//
//  RouteDetailsView.swift
//  Travel
//
//  Created by Natalia on 11.09.24.
//
import SwiftUI
import MapKit

struct RouteDetailsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var route: MKRoute?
    @State private var selectedTransportType: TransportType = .automobile
    @State private var isOptionsSheetPresented = false
    @State private var routeOptions: [MKRoute] = []
    @State private var errorMessage: String = ""
    @State private var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050), // Default location
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )

    var startLocation: CLLocationCoordinate2D?
    var endLocation: CLLocationCoordinate2D?

    var body: some View {
        VStack {
            // Transport Type Picker
            Picker("Select Transport Type", selection: $selectedTransportType) {
                Text("Driving").tag(TransportType.automobile)
                Text("Walking").tag(TransportType.walking)
                Text("Transit").tag(TransportType.transit)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            if let route = route {
                routeDetailsView
                showOptionsButton
            } else {
                noRouteAvailableView
            }
        }
        .background(Color.white)
        .cornerRadius(10)
        .padding()
        .sheet(isPresented: $isOptionsSheetPresented) {
            RouteOptionsView(
                routeOptions: $routeOptions,
                startLocation: startLocation ?? CLLocationCoordinate2D(),
                endLocation: endLocation ?? CLLocationCoordinate2D(),
                selectedTransportType: selectedTransportType, // Pass selected transport type
                onSelect: { selectedRoute in
                    self.route = selectedRoute
                    if let route = selectedRoute {
                        self.region = MKCoordinateRegion(route.polyline.boundingMapRect)
                    }
                },
                onTransportTypeChange: {
                    fetchRouteOptions() // Fetch new route options when transport type changes
                }
            )
        }
        .onChange(of: selectedTransportType) { _ in
            fetchRouteOptions() // Fetch routes when transport type changes
        }
    }

    private var routeDetailsView: some View {
        VStack(spacing: 20) {
            Text("Route calculated!")
                .font(.headline)
            routeInfoText
        }
    }

    private var routeInfoText: some View {
        Group {
            if let route = route {
                Text("Distance: \(String(format: "%.2f", route.distance / 1000)) km")
                Text("Travel Time: \(String(format: "%.2f", route.expectedTravelTime / 60)) minutes")
            }
        }
        .padding()
    }

    private var showOptionsButton: some View {
        Button("Show Options") {
            fetchRouteOptions() // Fetch route options when button is tapped
            isOptionsSheetPresented = true
        }
        .buttonStyle(.bordered)
        .padding()
    }

    private var noRouteAvailableView: some View {
        Text("No route available")
            .padding()
    }
    
    private func fetchRouteOptions() {
        guard let start = startLocation,
              let end = endLocation else {
            print("Start or end location is missing")
            return
        }

        let transportType = selectedTransportType.mkTransportType
        let startPlacemark = MKPlacemark(coordinate: start)
        let endPlacemark = MKPlacemark(coordinate: end)
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: startPlacemark)
        request.destination = MKMapItem(placemark: endPlacemark)
        request.transportType = transportType

        let directions = MKDirections(request: request)
        directions.calculate { (response, error) in
            if let routes = response?.routes {
                // Limit to 3 routes
                self.routeOptions = Array(routes.prefix(3))
            } else if let error = error {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}

struct RouteDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        RouteDetailsView(
            startLocation: CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050),
            endLocation: CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)
        )
    }
}
