//
//  CreateTripView.swift
//  OurTrips
//
//  Created by Avinash Dimmeta on 4/9/26.
//

import SwiftUI
import MapKit
import SwiftData
import CoreLocation

struct CreateTripView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var locationManager = LocationManager()
    
    @State private var tripName = ""
    @State private var fromLocationName = ""
    @State private var toLocationName = ""
    @State private var fromSearchResults: [MKMapItem] = []
    @State private var toSearchResults: [MKMapItem] = []
    @State private var selectedFromLocation: MKMapItem?
    @State private var selectedToLocation: MKMapItem?
    @State private var showFromSearch = false
    @State private var showToSearch = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoadingCurrentLocation = false
    @State private var showSuccessAlert = false
    @State private var createdTrip: RoadTrip?
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Trip Details") {
                    TextField("Trip Name", text: $tripName)
                        .textContentType(.none)
                }
                
                Section("From Location") {
                    Button(action: useCurrentLocation) {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.blue)
                            Text("Use Current Location")
                                .foregroundColor(.blue)
                            Spacer()
                            if isLoadingCurrentLocation {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            }
                        }
                    }
                    .disabled(isLoadingCurrentLocation)
                    
                    HStack {
                        TextField("Or search for a location", text: $fromLocationName)
                            .textContentType(.location)
                            .onChange(of: fromLocationName) { _, newValue in
                                searchLocation(query: newValue, isFrom: true)
                            }
                        
                        if selectedFromLocation != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    
                    if showFromSearch && !fromSearchResults.isEmpty {
                        ForEach(fromSearchResults, id: \.self) { item in
                            Button(action: {
                                selectLocation(item, isFrom: true)
                            }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name ?? "Unknown")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    if let address = item.placemark.title {
                                        Text(address)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                
                Section("To Location") {
                    HStack {
                        TextField("Search destination", text: $toLocationName)
                            .textContentType(.location)
                            .onChange(of: toLocationName) { _, newValue in
                                searchLocation(query: newValue, isFrom: false)
                            }
                        
                        if selectedToLocation != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    
                    if showToSearch && !toSearchResults.isEmpty {
                        ForEach(toSearchResults, id: \.self) { item in
                            Button(action: {
                                selectLocation(item, isFrom: false)
                            }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name ?? "Unknown")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    if let address = item.placemark.title {
                                        Text(address)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Create Road Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createTrip()
                    }
                    .disabled(!isFormValid)
                }
            }
            .alert("Error", isPresented: $showAlert) {
                Button("OK") {}
            } message: {
                Text(alertMessage)
            }
            .alert("Trip Created!", isPresented: $showSuccessAlert) {
                Button("Copy Share Code") {
                    if let trip = createdTrip {
                        UIPasteboard.general.string = trip.shareCode
                    }
                    presentationMode.wrappedValue.dismiss()
                }
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                if let trip = createdTrip {
                    Text("Your trip '\(trip.name)' has been created!\n\nShare Code: \(trip.shareCode)\n\nShare this code with friends to let them join your trip.")
                }
            }
            .onAppear {
                locationManager.requestLocationPermission()
                locationManager.startLocationUpdates()
            }
            .onDisappear {
                locationManager.stopLocationUpdates()
            }
        }
    }
    
    private func useCurrentLocation() {
        guard let location = locationManager.location else {
            showAlert(message: "Location not available. Please check your location settings.")
            return
        }
        
        isLoadingCurrentLocation = true
        
        // Reverse geocode to get address
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            isLoadingCurrentLocation = false
            
            if let error = error {
                showAlert(message: "Could not get address: \(error.localizedDescription)")
                return
            }
            
            guard let placemark = placemarks?.first else {
                showAlert(message: "Could not determine address")
                return
            }
            
            // Create MKMapItem from current location
            let mkPlacemark = MKPlacemark(placemark: placemark)
            let mapItem = MKMapItem(placemark: mkPlacemark)
            
            // Set the location name
            var locationName = "Current Location"
            if let name = placemark.name {
                locationName = name
            } else if let locality = placemark.locality {
                locationName = locality
            }
            
            mapItem.name = locationName
            
            // Select this location
            selectedFromLocation = mapItem
            fromLocationName = locationName
            showFromSearch = false
            fromSearchResults = []
        }
    }
    
    private var isFormValid: Bool {
        !tripName.isEmpty && selectedFromLocation != nil && selectedToLocation != nil
    }
    
    private func searchLocation(query: String, isFrom: Bool) {
        guard !query.isEmpty else {
            if isFrom {
                fromSearchResults = []
                showFromSearch = false
            } else {
                toSearchResults = []
                showToSearch = false
            }
            return
        }
        
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = query
        
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            guard let response = response else { return }
            
            if isFrom {
                fromSearchResults = response.mapItems
                showFromSearch = true
            } else {
                toSearchResults = response.mapItems
                showToSearch = true
            }
        }
    }
    
    private func selectLocation(_ item: MKMapItem, isFrom: Bool) {
        if isFrom {
            selectedFromLocation = item
            fromLocationName = item.name ?? ""
            showFromSearch = false
            fromSearchResults = []
        } else {
            selectedToLocation = item
            toLocationName = item.name ?? ""
            showToSearch = false
            toSearchResults = []
        }
    }
    
    private func createTrip() {
        guard let fromItem = selectedFromLocation,
              let toItem = selectedToLocation,
              let currentUser = authManager.currentUser else {
            showAlert(message: "Please complete all fields")
            return
        }
        
        let fromLocation = TripLocation(
            name: fromItem.name ?? "Unknown",
            address: fromItem.placemark.title ?? "",
            latitude: fromItem.placemark.coordinate.latitude,
            longitude: fromItem.placemark.coordinate.longitude
        )
        
        let toLocation = TripLocation(
            name: toItem.name ?? "Unknown",
            address: toItem.placemark.title ?? "",
            latitude: toItem.placemark.coordinate.latitude,
            longitude: toItem.placemark.coordinate.longitude
        )
        
        let trip = RoadTrip(
            name: tripName,
            fromLocation: fromLocation,
            toLocation: toLocation,
            ownerId: currentUser.email,
            ownerName: currentUser.name ?? currentUser.email
        )
        
        modelContext.insert(trip)
        
        do {
            try modelContext.save()
            
            // Share trip for cross-device joining
            TripSharingService.shared.shareTrip(trip)
            
            // Show success message with share code
            createdTrip = trip
            showSuccessAlert = true
        } catch {
            showAlert(message: "Failed to create trip: \(error.localizedDescription)")
        }
    }
    
    private func showAlert(message: String) {
        alertMessage = message
        showAlert = true
    }
}

#Preview {
    CreateTripView()
        .environmentObject(AuthManager())
}
