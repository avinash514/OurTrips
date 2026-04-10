//
//  NavigationMapView.swift
//  OurTrips
//
//  Created by Avinash Dimmeta on 4/9/26.
//

import SwiftUI
import MapKit
import SwiftData

struct NavigationMapView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var locationManager = LocationManager()
    @Bindable var trip: RoadTrip
    
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var route: MKRoute?
    @State private var isCalculatingRoute = true
    @State private var showRouteSteps = false
    @State private var locationUpdateTimer: Timer?
    @State private var participantColors: [String: Color] = [:]
    @State private var isNavigationMode = true
    
    var estimatedArrivalTime: String {
        guard let route = route else { return "--:--" }
        let arrival = Date().addingTimeInterval(route.expectedTravelTime)
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: arrival)
    }
    
    var remainingDistance: String {
        guard let route = route else { return "-- km" }
        let km = route.distance / 1000.0
        return String(format: "%.1f km", km)
    }
    
    var remainingTime: String {
        guard let route = route else { return "-- min" }
        let minutes = Int(route.expectedTravelTime / 60)
        let hours = minutes / 60
        let mins = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(mins)m"
        } else {
            return "\(mins) min"
        }
    }
    
    var body: some View {
        ZStack {
            Map(position: $cameraPosition) {
                // Starting point
                Annotation("Start", coordinate: trip.fromLocation.coordinate) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
                
                // Destination
                Annotation("Destination", coordinate: trip.toLocation.coordinate) {
                    VStack {
                        Image(systemName: "mappin.circle.fill")
                            .font(.title)
                            .foregroundColor(.red)
                        Text(trip.toLocation.name)
                            .font(.caption)
                            .padding(4)
                            .background(.white.opacity(0.9))
                            .cornerRadius(4)
                    }
                }
                
                // Route overlay
                if let route = route {
                    MapPolyline(route.polyline)
                        .stroke(.blue, lineWidth: 6)
                }
                
                // User location
                UserAnnotation()
                
                // Other participants with unique colors
                ForEach(trip.participants.filter { $0.userId != authManager.currentUser?.email && $0.currentLocation != nil }) { participant in
                    if let location = participant.currentLocation {
                        Annotation(participant.userName, coordinate: location.coordinate) {
                            ParticipantAnnotationView(
                                participant: participant,
                                color: getColorForParticipant(participant.userId)
                            )
                        }
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            
            // Navigation UI Overlay
            VStack(spacing: 0) {
                // Top info bar
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(estimatedArrivalTime)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("ETA")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                        .frame(height: 30)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(remainingDistance)
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("Distance")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                        .frame(height: 30)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(remainingTime)
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("Time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: { showRouteSteps.toggle() }) {
                        Image(systemName: "list.bullet")
                            .font(.title3)
                            .foregroundColor(.blue)
                            .padding(8)
                            .background(Color.white.opacity(0.9))
                            .clipShape(Circle())
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .shadow(radius: 4)
                
                Spacer()
                
                // Bottom control bar
                HStack(spacing: 20) {
                    // Participants count
                    HStack(spacing: 8) {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.blue)
                        Text("\(trip.participants.count)")
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    
                    Spacer()
                    
                    // Re-center button
                    Button(action: centerOnRoute) {
                        Image(systemName: "location.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                }
                .padding()
            }
            
            // Loading overlay
            if isCalculatingRoute {
                VStack(spacing: 16) {
                    ProgressView("Calculating route...")
                        .padding()
                    
                    Button("Skip") {
                        isCalculatingRoute = false
                    }
                    .buttonStyle(.bordered)
                }
                .padding(24)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
            }
        }
        .navigationTitle(trip.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showRouteSteps) {
            if let route = route {
                RouteStepsView(trip: trip, route: route)
                    .environmentObject(authManager)
            }
        }
        .onAppear {
            locationManager.requestLocationPermission()
            locationManager.startLocationUpdates()
            
            // Give location manager a moment to initialize
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                calculateRoute()
            }
            
            startLocationTracking()
            initializeParticipantColors()
            
            // Safety timeout: Stop loading after 10 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                if isCalculatingRoute {
                    print("⚠️ Route calculation timeout")
                    isCalculatingRoute = false
                }
            }
        }
        .onChange(of: locationManager.location) { _, newLocation in
            // Follow user in navigation mode like Apple Maps
            if isNavigationMode, let location = newLocation {
                let heading = locationManager.heading ?? 0
                withAnimation(.easeInOut(duration: 0.3)) {
                    cameraPosition = .camera(
                        MapCamera(
                            centerCoordinate: location.coordinate,
                            distance: 1000,
                            heading: heading,
                            pitch: 60
                        )
                    )
                }
            }
        }
        .onDisappear {
            stopLocationTracking()
            locationManager.stopLocationUpdates()
        }
        .onChange(of: trip.status) { _, newStatus in
            if newStatus != .active {
                // Trip has been ended or cancelled, dismiss the navigation view
                dismiss()
            }
        }
    }
    
    private func calculateRoute() {
        isCalculatingRoute = true
        
        // Wait for location if not available yet
        guard let currentLocation = locationManager.location else {
            print("⏳ Waiting for location to calculate route...")
            // Retry after 1 second
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if self.locationManager.location != nil {
                    self.calculateRoute()
                } else {
                    print("⚠️ Still no location, calculating route from trip start point")
                    self.calculateRouteFromTripStart()
                }
            }
            return
        }
        
        // Calculate route from current location to destination
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: currentLocation.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: trip.toLocation.coordinate))
        request.transportType = .automobile
        request.requestsAlternateRoutes = false
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            DispatchQueue.main.async {
                self.isCalculatingRoute = false
                
                if let error = error {
                    print("❌ Route calculation error: \(error.localizedDescription)")
                    // Fallback to showing trip route
                    self.calculateRouteFromTripStart()
                    return
                }
                
                guard let route = response?.routes.first else {
                    print("❌ No route found")
                    self.calculateRouteFromTripStart()
                    return
                }
                
                print("✅ Route calculated: \(route.distance/1000) km")
                self.route = route
                
                // Start in navigation mode
                self.isNavigationMode = true
            }
        }
    }
    
    private func calculateRouteFromTripStart() {
        // Fallback: Calculate route from trip origin to destination
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: trip.fromLocation.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: trip.toLocation.coordinate))
        request.transportType = .automobile
        request.requestsAlternateRoutes = false
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            DispatchQueue.main.async {
                self.isCalculatingRoute = false
                
                if let error = error {
                    print("❌ Fallback route error: \(error.localizedDescription)")
                    return
                }
                
                guard let route = response?.routes.first else {
                    print("❌ No fallback route found")
                    return
                }
                
                print("✅ Fallback route calculated")
                self.route = route
            }
        }
    }
    
    private func centerOnRoute() {
        isNavigationMode = false
        
        if let route = route {
            let rect = route.polyline.boundingMapRect
            let region = MKCoordinateRegion(rect)
            
            // Add padding
            let paddedRegion = MKCoordinateRegion(
                center: region.center,
                span: MKCoordinateSpan(
                    latitudeDelta: region.span.latitudeDelta * 1.3,
                    longitudeDelta: region.span.longitudeDelta * 1.3
                )
            )
            
            withAnimation {
                cameraPosition = .region(paddedRegion)
            }
            
            // Return to navigation mode after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                isNavigationMode = true
            }
        } else if let location = locationManager.location {
            let heading = locationManager.heading ?? 0
            withAnimation {
                cameraPosition = .camera(
                    MapCamera(
                        centerCoordinate: location.coordinate,
                        distance: 1000,
                        heading: heading,
                        pitch: 60
                    )
                )
            }
            isNavigationMode = true
        }
    }
    
    private func startLocationTracking() {
        // Update participant location every 3 seconds for better real-time tracking
        locationUpdateTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            updateParticipantLocation()
        }
        updateParticipantLocation()
    }
    
    private func stopLocationTracking() {
        locationUpdateTimer?.invalidate()
        locationUpdateTimer = nil
    }
    
    private func updateParticipantLocation() {
        guard let currentUser = authManager.currentUser,
              let location = locationManager.location,
              let index = trip.participants.firstIndex(where: { $0.userId == currentUser.email }) else {
            return
        }
        
        // Update local participant location
        trip.participants[index].updateLocation(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        
        try? modelContext.save()
        
        // Share updated trip with participant locations to other devices
        TripSharingService.shared.shareTrip(trip)
        
        // Also sync participant locations from other devices
        syncParticipantLocations()
    }
    
    private func syncParticipantLocations() {
        guard let sharedTripData = TripSharingService.shared.getSharedTrip(shareCode: trip.shareCode),
              let participantsData = sharedTripData["participants"] as? [[String: Any]] else {
            return
        }
        
        var hasChanges = false
        
        // First, check if there are new participants we don't have
        for participantData in participantsData {
            guard let userId = participantData["userId"] as? String,
                  let userName = participantData["userName"] as? String,
                  let isOwner = participantData["isOwner"] as? Bool else {
                continue
            }
            
            // Add participant if they don't exist in our local list
            if !trip.participants.contains(where: { $0.userId == userId }) {
                let newParticipant = TripParticipant(
                    userId: userId,
                    userName: userName,
                    isOwner: isOwner
                )
                trip.participants.append(newParticipant)
                hasChanges = true
                print("✅ Added new participant: \(userName)")
            }
        }
        
        // Update participant locations from shared data
        for participantData in participantsData {
            guard let userId = participantData["userId"] as? String,
                  let index = trip.participants.firstIndex(where: { $0.userId == userId }) else {
                continue
            }
            
            // Update location if available
            if let lat = participantData["latitude"] as? Double,
               let lon = participantData["longitude"] as? Double,
               let lastUpdatedInterval = participantData["lastUpdated"] as? TimeInterval {
                
                // Update if this location is newer than what we have
                let newDate = Date(timeIntervalSince1970: lastUpdatedInterval)
                if trip.participants[index].lastUpdated == nil || newDate > trip.participants[index].lastUpdated! {
                    trip.participants[index].updateLocation(latitude: lat, longitude: lon)
                    hasChanges = true
                }
            }
        }
        
        if hasChanges {
            try? modelContext.save()
        }
    }
    
    private func initializeParticipantColors() {
        let colors: [Color] = [.red, .blue, .green, .orange, .purple, .pink, .cyan, .mint]
        var colorIndex = 0
        
        for participant in trip.participants {
            if participantColors[participant.userId] == nil {
                participantColors[participant.userId] = colors[colorIndex % colors.count]
                colorIndex += 1
            }
        }
    }
    
    private func getColorForParticipant(_ userId: String) -> Color {
        return participantColors[userId] ?? .purple
    }
}

struct ParticipantAnnotationView: View {
    let participant: TripParticipant
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 40, height: 40)
                    .shadow(color: color.opacity(0.5), radius: 4, x: 0, y: 2)
                
                Image(systemName: participant.isOwner ? "car.fill" : "car.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 18))
                    .rotationEffect(.degrees(0)) // Can add heading rotation later
            }
            
            Text(participant.userName.split(separator: " ").first ?? "")
                .font(.caption2)
                .fontWeight(.bold)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(color)
                .foregroundColor(.white)
                .cornerRadius(4)
                .shadow(radius: 1)
        }
    }
}

struct RouteStepsView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authManager: AuthManager
    @Bindable var trip: RoadTrip
    let route: MKRoute
    
    @State private var showCancelConfirmation = false
    @State private var showEndConfirmation = false
    
    var isOwner: Bool {
        trip.ownerId == authManager.currentUser?.email
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section("Trip Summary") {
                    HStack {
                        Text("Total Distance")
                        Spacer()
                        Text(String(format: "%.1f km", route.distance / 1000.0))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Expected Time")
                        Spacer()
                        Text(formatDuration(route.expectedTravelTime))
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Directions (\(route.steps.count) steps)") {
                    ForEach(Array(route.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Circle().fill(Color.blue))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(step.instructions)
                                    .font(.body)
                                
                                if step.distance > 0 {
                                    Text(formatDistance(step.distance))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                if isOwner {
                    Section("Trip Actions") {
                        Button(action: { showEndConfirmation = true }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("End Trip")
                                    .foregroundColor(.green)
                            }
                        }
                        
                        Button(action: { showCancelConfirmation = true }) {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                Text("Cancel Trip")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Route Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .confirmationDialog("End this trip?", isPresented: $showEndConfirmation, titleVisibility: .visible) {
                Button("End Trip") {
                    endTrip()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will mark the trip as completed.")
            }
            .confirmationDialog("Cancel this trip?", isPresented: $showCancelConfirmation, titleVisibility: .visible) {
                Button("Cancel Trip", role: .destructive) {
                    cancelTrip()
                }
                Button("Keep Trip", role: .cancel) {}
            } message: {
                Text("This will cancel the trip for all participants. This action cannot be undone.")
            }
        }
    }
    
    private func endTrip() {
        trip.status = .completed
        trip.completedAt = Date()
        try? modelContext.save()
        presentationMode.wrappedValue.dismiss()
    }
    
    private func cancelTrip() {
        trip.status = .cancelled
        trip.completedAt = Date()
        try? modelContext.save()
        presentationMode.wrappedValue.dismiss()
    }
    
    private func formatDistance(_ distance: Double) -> String {
        if distance < 1000 {
            return String(format: "%.0f m", distance)
        } else {
            return String(format: "%.1f km", distance / 1000.0)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        let hours = minutes / 60
        let mins = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(mins)m"
        } else {
            return "\(mins) minutes"
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
    
    return NavigationStack {
        NavigationMapView(trip: trip)
            .environmentObject(AuthManager())
            .modelContainer(container)
    }
}
