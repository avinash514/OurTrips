//
//  LiveTrackingView.swift
//  OurTrips
//
//  Created by Avinash Dimmeta on 4/9/26.
//

import SwiftUI
import MapKit
import SwiftData

struct LiveTrackingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var locationManager = LocationManager()
    @Bindable var trip: RoadTrip
    
    @State private var cameraPosition: MapCameraPosition
    @State private var locationUpdateTimer: Timer?
    
    init(trip: RoadTrip) {
        self.trip = trip
        let initialRegion = MKCoordinateRegion(
            center: trip.fromLocation.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )
        _cameraPosition = State(initialValue: .region(initialRegion))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $cameraPosition) {
                    // Starting point marker
                    Annotation("Start", coordinate: trip.fromLocation.coordinate) {
                        VStack {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title)
                                .foregroundColor(.green)
                            Text("Start")
                                .font(.caption)
                                .padding(4)
                                .background(.white.opacity(0.8))
                                .cornerRadius(4)
                        }
                    }
                    
                    // Destination marker
                    Annotation("Destination", coordinate: trip.toLocation.coordinate) {
                        VStack {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title)
                                .foregroundColor(.red)
                            Text("Destination")
                                .font(.caption)
                                .padding(4)
                                .background(.white.opacity(0.8))
                                .cornerRadius(4)
                        }
                    }
                    
                    // Participant markers
                    ForEach(trip.participants.filter { $0.currentLocation != nil }) { participant in
                        if let location = participant.currentLocation {
                            Annotation(participant.userName, coordinate: location.coordinate) {
                                ParticipantMarker(participant: participant, isCurrentUser: participant.userId == authManager.currentUser?.email)
                            }
                        }
                    }
                }
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapScaleView()
                }
                
                // Participants list overlay
                VStack {
                    HStack {
                        Spacer()
                        ParticipantsListOverlay(participants: trip.participants)
                            .padding()
                    }
                    Spacer()
                }
            }
            .navigationTitle("Live Tracking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: centerOnParticipants) {
                        Image(systemName: "location.circle")
                    }
                }
            }
            .onAppear {
                startLocationUpdates()
            }
            .onDisappear {
                stopLocationUpdates()
            }
        }
    }
    
    private func startLocationUpdates() {
        locationManager.requestLocationPermission()
        locationManager.startLocationUpdates()
        
        // Update participant location every 5 seconds
        locationUpdateTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            updateParticipantLocation()
        }
        
        // Initial update
        updateParticipantLocation()
    }
    
    private func stopLocationUpdates() {
        locationManager.stopLocationUpdates()
        locationUpdateTimer?.invalidate()
        locationUpdateTimer = nil
    }
    
    private func updateParticipantLocation() {
        guard let currentUser = authManager.currentUser,
              let location = locationManager.location,
              let index = trip.participants.firstIndex(where: { $0.userId == currentUser.email }) else {
            return
        }
        
        trip.participants[index].updateLocation(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        
        try? modelContext.save()
    }
    
    private func centerOnParticipants() {
        let coordinates = trip.participants.compactMap { $0.currentLocation?.coordinate }
        guard !coordinates.isEmpty else { return }
        
        let minLat = coordinates.map { $0.latitude }.min() ?? 0
        let maxLat = coordinates.map { $0.latitude }.max() ?? 0
        let minLon = coordinates.map { $0.longitude }.min() ?? 0
        let maxLon = coordinates.map { $0.longitude }.max() ?? 0
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.5, 0.01),
            longitudeDelta: max((maxLon - minLon) * 1.5, 0.01)
        )
        
        cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
    }
}

struct ParticipantMarker: View {
    let participant: TripParticipant
    let isCurrentUser: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(isCurrentUser ? Color.blue : Color.purple)
                    .frame(width: 40, height: 40)
                
                if participant.isOwner {
                    Image(systemName: "star.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                } else {
                    Image(systemName: "car.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                }
            }
            .shadow(radius: 4)
            
            Text(participant.userName)
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(isCurrentUser ? Color.blue : Color.purple)
                .foregroundColor(.white)
                .cornerRadius(4)
                .shadow(radius: 2)
        }
    }
}

struct ParticipantsListOverlay: View {
    let participants: [TripParticipant]
    @State private var isExpanded = false
    
    var activeParticipants: [TripParticipant] {
        participants.filter { $0.currentLocation != nil }
    }
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Image(systemName: "person.2.fill")
                    Text("\(activeParticipants.count)/\(participants.count)")
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .shadow(radius: 4)
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(participants) { participant in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(participant.currentLocation != nil ? Color.green : Color.gray)
                                .frame(width: 8, height: 8)
                            
                            Text(participant.userName)
                                .font(.caption)
                                .lineLimit(1)
                            
                            if participant.isOwner {
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                    .foregroundColor(.yellow)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                    }
                }
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .shadow(radius: 4)
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: RoadTrip.self, configurations: config)
    
    let trip = RoadTrip(
        name: "Weekend Getaway",
        fromLocation: TripLocation(name: "San Francisco", address: "CA", latitude: 37.7749, longitude: -122.4194),
        toLocation: TripLocation(name: "Los Angeles", address: "CA", latitude: 34.0522, longitude: -118.2437),
        ownerId: "test@example.com",
        ownerName: "John Doe"
    )
    trip.status = .active
    container.mainContext.insert(trip)
    
    return LiveTrackingView(trip: trip)
        .environmentObject(AuthManager())
        .modelContainer(container)
}
