//
//  ContentView.swift
//  Travel
//
//  Created by Natalia on 11.09.24.
//
import SwiftUI
import MapKit
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var startLocation = ""
    @State private var endLocation = ""
    @State private var route: MKRoute?
    @State private var errorMessage = ""
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050), // Berlin, Germany
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var selectedStartLocation: Location?
    @State private var selectedEndLocation: Location?
    @State private var isSelectingStartLocation = false
    @State private var isSelectingEndLocation = false
    @State private var isOptionsSheetPresented = false
    @State private var selectedTransportType: TransportType = .automobile
    @State private var routeOptions: [MKRoute] = []

    var body: some View {
        ZStack {
            mapView
            VStack {
                transportSelectionView
                locationInputFields
                Button(action: findMyLocation) {
                    Text("Znajdź mnie")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()
                
                Spacer()
                if bothLocationsSelected {
                    optionsButton
                }
            }
            .padding()
        }
        .onAppear {
            locationManager.startUpdatingLocation()
        }
        .onChange(of: locationManager.location) { newLocation in
            if let location = newLocation {
                region.center = location.coordinate
            }
        }
        .onChange(of: selectedStartLocation) { newLocation in
            if let location = newLocation {
                reverseGeocode(location: location.coordinate) { address in
                    startLocation = address ?? ""
                    isSelectingStartLocation = false
                    calculateRouteIfReady()
                }
            }
        }
        .onChange(of: selectedEndLocation) { newLocation in
            if let location = newLocation {
                reverseGeocode(location: location.coordinate) { address in
                    endLocation = address ?? ""
                    isSelectingEndLocation = false
                    calculateRouteIfReady()
                }
            }
        }
    }

    // MARK: - Views

    private var mapView: some View {
        MapView(
            routes: route != nil ? [route!] : [],
            region: $region,
            selectedStartLocation: $selectedStartLocation,
            selectedEndLocation: $selectedEndLocation,
            isSelectingStartLocation: $isSelectingStartLocation,
            isSelectingEndLocation: $isSelectingEndLocation,
            userLocation: $locationManager.location
        )
        .edgesIgnoringSafeArea(.all)
    }

    private var transportSelectionView: some View {
        HStack {
            transportButton(title: "Driving", imageName: "car.fill", transportType: .automobile)
            transportButton(title: "Walking", imageName: "figure.walk", transportType: .walking)
        }
    }

    private func transportButton(title: String, imageName: String, transportType: TransportType) -> some View {
        Button(action: {
            selectedTransportType = transportType
            calculateRouteIfReady()
        }) {
            Label(title, systemImage: imageName)
                .padding()
                .background(selectedTransportType == transportType ? Color.blue : Color.clear)
                .cornerRadius(8)
                .foregroundColor(selectedTransportType == transportType ? .white : .black)
        }
    }

    private var locationInputFields: some View {
        VStack(spacing: 12) {
            TextField("Start Location", text: $startLocation, onEditingChanged: updateStartLocationEditing)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(12)
                .background(Color.white.opacity(0.8))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
                .foregroundColor(startLocation.isEmpty ? .gray : .black)

            TextField("End Location", text: $endLocation, onEditingChanged: updateEndLocationEditing)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(12)
                .background(Color.white.opacity(0.8))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
                .foregroundColor(endLocation.isEmpty ? .gray : .black)
        }
        .padding(.horizontal)
    }

    private func updateStartLocationEditing(isEditing: Bool) {
        isSelectingStartLocation = isEditing
    }

    private func updateEndLocationEditing(isEditing: Bool) {
        isSelectingEndLocation = isEditing
    }

    private var optionsButton: some View {
        Button(action: {
            isOptionsSheetPresented = true
            fetchRouteOptions()
        }) {
            Text("Options")
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .sheet(isPresented: $isOptionsSheetPresented) {
            RouteOptionsView(
                routeOptions: $routeOptions,
                startLocation: selectedStartLocation?.coordinate ?? CLLocationCoordinate2D(),
                endLocation: selectedEndLocation?.coordinate ?? CLLocationCoordinate2D(),
                selectedTransportType: selectedTransportType,
                onSelect: { selectedRoute in
                    self.route = selectedRoute
                    if let route = selectedRoute {
                        self.region = MKCoordinateRegion(route.polyline.boundingMapRect)
                    }
                },
                onTransportTypeChange: {
                    fetchRouteOptions()
                }
            )
        }
    }

    // MARK: - Functions

    private func findMyLocation() {
        if let currentLocation = locationManager.location {
            selectedStartLocation = Location(coordinate: currentLocation.coordinate)
            reverseGeocode(location: currentLocation.coordinate) { address in
                startLocation = address ?? ""
                calculateRouteIfReady()
            }
        }
    }

    private func reverseGeocode(location: CLLocationCoordinate2D, completion: @escaping (String?) -> Void) {
        let geocoder = CLGeocoder()
        let clLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        geocoder.reverseGeocodeLocation(clLocation) { placemarks, error in
            if let placemark = placemarks?.first {
                completion(placemark.thoroughfare)
            } else {
                completion(nil)
            }
        }
    }

    private func calculateRouteIfReady() {
        if let start = selectedStartLocation?.coordinate, let end = selectedEndLocation?.coordinate {
            fetchRoute(start: start, end: end, transportType: selectedTransportType.mkTransportType)
        }
    }

    private func fetchRoute(start: CLLocationCoordinate2D, end: CLLocationCoordinate2D, transportType: MKDirectionsTransportType) {
        let startPlacemark = MKPlacemark(coordinate: start)
        let endPlacemark = MKPlacemark(coordinate: end)
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: startPlacemark)
        request.destination = MKMapItem(placemark: endPlacemark)
        request.transportType = transportType

        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            if let routes = response?.routes {
                self.route = routes.first
                self.region = MKCoordinateRegion(self.route?.polyline.boundingMapRect ?? MKMapRect())
                self.routeOptions = routes
            } else if let error = error {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func fetchRouteOptions() {
        guard let start = selectedStartLocation?.coordinate,
              let end = selectedEndLocation?.coordinate else {
            print("Start or end location is missing")
            return
        }

        let transportTypes: [MKDirectionsTransportType] = [.automobile, .walking, .transit]
        var routes: [MKRoute] = []

        let dispatchGroup = DispatchGroup()

        for transportType in transportTypes {
            dispatchGroup.enter()
            let startPlacemark = MKPlacemark(coordinate: start)
            let endPlacemark = MKPlacemark(coordinate: end)
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: startPlacemark)
            request.destination = MKMapItem(placemark: endPlacemark)
            request.transportType = transportType

            let directions = MKDirections(request: request)
            directions.calculate { (response, error) in
                if let route = response?.routes.first {
                    routes.append(route)
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            self.routeOptions = Array(routes.prefix(3))
        }
    }

    private var bothLocationsSelected: Bool {
        selectedStartLocation != nil && selectedEndLocation != nil
    }
}
