//
//  RouteOptionsView.swift
//  Travel
//
//  Created by Natalia on 11.09.24.
//
import SwiftUI
import MapKit

extension MKRoute: Identifiable {
    public var id: UUID {
        return UUID() // Generate a unique identifier for each route
    }
}

struct RouteOptionsView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var routeOptions: [MKRoute]
    var startLocation: CLLocationCoordinate2D
    var endLocation: CLLocationCoordinate2D
    var selectedTransportType: TransportType
    var onSelect: (MKRoute?) -> Void
    var onTransportTypeChange: () -> Void

    var filteredRoutes: [MKRoute] {
        // Filter routes based on the selected transport type
        routeOptions.filter { $0.transportType == selectedTransportType.mkTransportType }
    }

    var body: some View {
        NavigationView {
            VStack {
                List(filteredRoutes.prefix(3)) { route in
                    RouteOptionRow(route: route) {
                        onSelect(route)
                        dismiss()
                    }
                }
                .listStyle(PlainListStyle())
                .navigationTitle("Select a Route")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
        }
        .onAppear {
            onTransportTypeChange()
        }
    }
}

struct RouteOptionRow: View {
    var route: MKRoute
    var onTap: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Distance: \(String(format: "%.2f", route.distance / 1000)) km")
                Text("Travel Time: \(String(format: "%.2f", route.expectedTravelTime / 60)) minutes")
            }
            Spacer()
            Button("Select") {
                onTap()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

enum TransportType: Int, Hashable {
    case automobile = 0
    case walking
    case transit

    init(_ transportType: MKDirectionsTransportType) {
        switch transportType {
        case .automobile:
            self = .automobile
        case .walking:
            self = .walking
        case .transit:
            self = .transit
        default:
            self = .automobile
        }
    }

    var mkTransportType: MKDirectionsTransportType {
        switch self {
        case .automobile:
            return .automobile
        case .walking:
            return .walking
        case .transit:
            return .transit
        }
    }
}
