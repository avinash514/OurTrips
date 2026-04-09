//
//  MapView.swift
//  OurTrips
//
//  Created by Avinash Dimmeta on 12/9/25.
//

import SwiftUI
import MapKit

struct MapView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var cameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    ))
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Map(position: $cameraPosition)
#if os(iOS)
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapScaleView()
                }
#endif
                .onAppear {
                    locationManager.requestLocationPermission()
                    locationManager.startLocationUpdates()
                    updateCameraPosition()
                }
                .onReceive(locationManager.$region) { newRegion in
                    cameraPosition = .region(newRegion)
                }
                .onDisappear {
                    locationManager.stopLocationUpdates()
                }
            
#if os(iOS)
            // Map controls (iOS-only)
            VStack(spacing: 12) {
                // Location button
                Button(action: {
                    if let location = locationManager.location {
                        let newRegion = MKCoordinateRegion(
                            center: location.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )
                        locationManager.region = newRegion
                        cameraPosition = .region(newRegion)
                    } else {
                        locationManager.requestLocationPermission()
                    }
                }) {
                    Image(systemName: "location.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue, in: Circle())
                        .shadow(radius: 5)
                }
            }
            .padding()
#endif
        }
        .overlay(alignment: .bottom) {
            // Location status
            if locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted {
                VStack(spacing: 8) {
                    Text("Location Access Denied")
                        .font(.headline)
                    Text("Please enable location access in Settings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                .padding()
            }
        }
    }
    
    private func updateCameraPosition() {
        cameraPosition = .region(locationManager.region)
    }
}

#Preview {
    MapView()
}

