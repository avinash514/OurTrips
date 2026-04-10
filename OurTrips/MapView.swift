//
//  MapView.swift
//  OurTrips
//
//  Created by Avinash Dimmeta on 12/9/25.
//

import SwiftUI
import MapKit
import SwiftData

struct MapView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authManager: AuthManager
    @Query(sort: \RoadTrip.createdAt, order: .reverse) private var allTrips: [RoadTrip]
    
    @StateObject private var locationManager = LocationManager()
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var selectedDestination: MKMapItem?
    @State private var routes: [MKRoute] = []
    @State private var selectedRoute: MKRoute?
    @State private var isCalculatingRoute = false
    @State private var showCreateTrip = false
    @State private var showProfileMenu = false
    @State private var showJoinTrip = false
    @State private var sheetPosition: SheetPosition = .collapsed
    
    var recentTrips: [RoadTrip] {
        allTrips.filter { trip in
            trip.participants.contains(where: { $0.userId == authManager.currentUser?.email })
        }.prefix(5).map { $0 }
    }
    
    enum SheetPosition {
        case collapsed  // Search bar only
        case partial    // Recent trips visible
        case expanded   // Full search results
        
        var offset: CGFloat {
            switch self {
            case .collapsed: return UIScreen.main.bounds.height - 140
            case .partial: return UIScreen.main.bounds.height - 400
            case .expanded: return 100
            }
        }
    }
    
    enum DragState {
        case inactive
        case dragging(translation: CGSize)
        
        var translation: CGSize {
            switch self {
            case .inactive: return .zero
            case .dragging(let t): return t
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Full screen map
            Map(position: $cameraPosition) {
                UserAnnotation()
                
                if let destination = selectedDestination {
                    Annotation(destination.name ?? "Destination", coordinate: destination.placemark.coordinate) {
                        VStack {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title)
                                .foregroundColor(.red)
                            Text(destination.name ?? "Destination")
                                .font(.caption)
                                .padding(4)
                                .background(.white.opacity(0.9))
                                .cornerRadius(4)
                        }
                    }
                }
                
                if let route = selectedRoute {
                    MapPolyline(route.polyline)
                        .stroke(.blue, lineWidth: 6)
                }
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .mapStyle(.standard(elevation: .realistic))
            .ignoresSafeArea()
            .onAppear {
                locationManager.requestLocationPermission()
                locationManager.startLocationUpdates()
            }
            .onChange(of: locationManager.location) { _, newLocation in
                if let location = newLocation, selectedDestination == nil {
                    withAnimation {
                        cameraPosition = .region(MKCoordinateRegion(
                            center: location.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                        ))
                    }
                }
            }
            .onDisappear {
                locationManager.stopLocationUpdates()
            }
            
            // Sliding bottom sheet
            BottomSheetView(
                position: $sheetPosition,
                searchText: $searchText,
                selectedRoute: $selectedRoute,
                searchResults: searchResults,
                recentTrips: recentTrips,
                routes: routes,
                selectedDestination: selectedDestination,
                onSearch: searchLocation,
                onSelectResult: selectDestination,
                onClearSearch: clearSearch,
                onSelectRoute: { route in
                    withAnimation {
                        selectedRoute = route
                    }
                },
                onCreateTrip: {
                    showCreateTrip = true
                },
                onClearRoute: clearRoute,
                onShowProfile: {
                    showProfileMenu = true
                },
                onShowTrips: {
                    // Navigate to trips list
                },
                onJoinTrip: {
                    showJoinTrip = true
                }
            )
            .environmentObject(authManager)
        }
        .sheet(isPresented: $showCreateTrip) {
            if let destination = selectedDestination, let route = selectedRoute {
                QuickCreateTripView(
                    destination: destination,
                    route: route
                )
                .environmentObject(authManager)
            }
        }
        .sheet(isPresented: $showProfileMenu) {
            ProfileView()
                .environmentObject(authManager)
        }
        .sheet(isPresented: $showJoinTrip) {
            JoinTripView()
                .environmentObject(authManager)
        }
    }
    
    private func searchLocation(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            sheetPosition = .collapsed
            return
        }
        
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = query
        
        if let location = locationManager.location {
            searchRequest.region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
            )
        }
        
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            guard let response = response else { return }
            searchResults = response.mapItems
            withAnimation {
                sheetPosition = .expanded
            }
        }
    }
    
    private func selectDestination(_ item: MKMapItem) {
        selectedDestination = item
        searchText = item.name ?? ""
        searchResults = []
        calculateRoutes(to: item)
    }
    
    private func calculateRoutes(to destination: MKMapItem) {
        guard let location = locationManager.location else { return }
        
        isCalculatingRoute = true
        routes = []
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: location.coordinate))
        request.destination = destination
        request.transportType = .automobile
        request.requestsAlternateRoutes = true
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            isCalculatingRoute = false
            
            guard let response = response else { return }
            withAnimation {
                self.routes = response.routes
                if let firstRoute = response.routes.first {
                    self.selectedRoute = firstRoute
                    
                    let rect = firstRoute.polyline.boundingMapRect
                    let region = MKCoordinateRegion(rect)
                    let paddedRegion = MKCoordinateRegion(
                        center: region.center,
                        span: MKCoordinateSpan(
                            latitudeDelta: region.span.latitudeDelta * 1.4,
                            longitudeDelta: region.span.longitudeDelta * 1.4
                        )
                    )
                    cameraPosition = .region(paddedRegion)
                    sheetPosition = .partial
                }
            }
        }
    }
    
    private func clearSearch() {
        searchText = ""
        searchResults = []
        sheetPosition = .collapsed
    }
    
    private func clearRoute() {
        withAnimation {
            selectedDestination = nil
            routes = []
            selectedRoute = nil
            searchText = ""
            sheetPosition = .collapsed
            
            if let location = locationManager.location {
                cameraPosition = .region(MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                ))
            }
        }
    }
}

// MARK: - Bottom Sheet View
struct BottomSheetView: View {
    @EnvironmentObject var authManager: AuthManager
    @Binding var position: MapView.SheetPosition
    @Binding var searchText: String
    @Binding var selectedRoute: MKRoute?
    @GestureState private var dragState = MapView.DragState.inactive
    
    let searchResults: [MKMapItem]
    let recentTrips: [RoadTrip]
    let routes: [MKRoute]
    let selectedDestination: MKMapItem?
    let onSearch: (String) -> Void
    let onSelectResult: (MKMapItem) -> Void
    let onClearSearch: () -> Void
    let onSelectRoute: (MKRoute) -> Void
    let onCreateTrip: () -> Void
    let onClearRoute: () -> Void
    let onShowProfile: () -> Void
    let onShowTrips: () -> Void
    let onJoinTrip: () -> Void
    
    var offset: CGFloat {
        position.offset + dragState.translation.height
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 36, height: 5)
                .padding(.top, 10)
            
            // Search bar with profile icon
            HStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search for a place", text: $searchText)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                        .onChange(of: searchText) { _, newValue in
                            onSearch(newValue)
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: onClearSearch) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Button(action: {
                            // Dictation
                        }) {
                            Image(systemName: "mic.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Profile button
                Button(action: onShowProfile) {
                    if let userName = authManager.currentUser?.name {
                        Text(String(userName.prefix(1)))
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(.blue))
                    } else {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .frame(width: 44, height: 44)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            
            // Content based on position and state
            ScrollView {
                VStack(spacing: 16) {
                    if !routes.isEmpty {
                        // Route options
                        RouteOptionsContent(
                            destination: selectedDestination,
                            routes: routes,
                            selectedRoute: $selectedRoute,
                            onSelectRoute: onSelectRoute,
                            onCreateTrip: onCreateTrip,
                            onClear: onClearRoute
                        )
                    } else if !searchResults.isEmpty {
                        // Search results
                        SearchResultsContent(
                            searchResults: searchResults,
                            onSelect: onSelectResult
                        )
                    } else if searchText.isEmpty {
                        // Recent trips
                        RecentTripsContent(
                            trips: recentTrips,
                            onShowAllTrips: onShowTrips,
                            onJoinTrip: onJoinTrip
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .frame(maxHeight: UIScreen.main.bounds.height - offset - 100)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(.regularMaterial)
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .shadow(color: .black.opacity(0.1), radius: 10)
        .offset(y: max(offset, 100))
        .gesture(
            DragGesture()
                .updating($dragState) { value, state, _ in
                    state = .dragging(translation: value.translation)
                }
                .onEnded { value in
                    onDragEnded(value)
                }
        )
    }
    
    private func onDragEnded(_ value: DragGesture.Value) {
        let verticalDirection = value.translation.height
        let velocity = value.predictedEndTranslation.height - value.translation.height
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if verticalDirection > 50 || velocity > 100 {
                // Swipe down
                if position == .expanded {
                    position = .partial
                } else if position == .partial {
                    position = .collapsed
                }
            } else if verticalDirection < -50 || velocity < -100 {
                // Swipe up
                if position == .collapsed {
                    position = .partial
                } else if position == .partial {
                    position = .expanded
                }
            }
        }
    }
}

// MARK: - Recent Trips Content
struct RecentTripsContent: View {
    let trips: [RoadTrip]
    let onShowAllTrips: () -> Void
    let onJoinTrip: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recents")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button(action: onShowAllTrips) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            
            if trips.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "car.circle")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No recent trips")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button(action: onJoinTrip) {
                        Label("Join a Trip", systemImage: "person.badge.plus")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(.blue)
                            .cornerRadius(20)
                    }
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 12) {
                    ForEach(trips) { trip in
                        RecentTripCard(trip: trip)
                    }
                    
                    // Join Trip button
                    Button(action: onJoinTrip) {
                        HStack {
                            Image(systemName: "person.badge.plus")
                                .font(.title3)
                                .foregroundColor(.blue)
                            Text("Join a Trip")
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
            }
        }
    }
}

struct RecentTripCard: View {
    let trip: RoadTrip
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "car.fill")
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(Circle().fill(.blue))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(trip.name)
                    .font(.headline)
                
                HStack(spacing: 4) {
                    Text(trip.fromLocation.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(trip.toLocation.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            StatusBadge(status: trip.status)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4)
    }
}

// MARK: - Search Results Content
struct SearchResultsContent: View {
    let searchResults: [MKMapItem]
    let onSelect: (MKMapItem) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Search Results")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                ForEach(searchResults, id: \.self) { item in
                    Button(action: {
                        onSelect(item)
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.red)
                                .font(.title3)
                            
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
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 4)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Route Options Content
struct RouteOptionsContent: View {
    let destination: MKMapItem?
    let routes: [MKRoute]
    @Binding var selectedRoute: MKRoute?
    let onSelectRoute: (MKRoute) -> Void
    let onCreateTrip: () -> Void
    let onClear: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(destination?.name ?? "Destination")
                        .font(.title2).fontWeight(.bold)
                    if let address = destination?.placemark.title {
                        Text(address)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: onClear) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            
            Text("Routes")
                .font(.headline)
            
            VStack(spacing: 12) {
                ForEach(Array(routes.enumerated()), id: \.offset) { index, route in
                    RouteOptionCard(
                        routeIndex: index,
                        route: route,
                        isSelected: route == selectedRoute,
                        onSelect: {
                            onSelectRoute(route)
                        }
                    )
                }
            }
            
            Button(action: onCreateTrip) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Trip")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
    }
}
    

// MARK: - Route Option Card
struct RouteOptionCard: View {
    let routeIndex: Int
    let route: MKRoute
    let isSelected: Bool
    let onSelect: () -> Void
    
    var duration: String {
        let minutes = Int(route.expectedTravelTime / 60)
        let hours = minutes / 60
        let mins = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(mins)m"
        } else {
            return "\(mins) min"
        }
    }
    
    var distance: String {
        String(format: "%.1f km", route.distance / 1000.0)
    }
    
    var routeName: String {
        route.name.isEmpty ? "Route \(routeIndex + 1)" : route.name
    }
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(.secondary)
                        }
                        Text(routeName)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    
                    HStack(spacing: 8) {
                        Label(duration, systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Label(distance, systemImage: "arrow.triangle.swap")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.05), radius: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Quick Create Trip View
struct QuickCreateTripView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var locationManager = LocationManager()
    
    let destination: MKMapItem
    let route: MKRoute
    
    @State private var tripName = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Trip Details") {
                    TextField("Trip Name", text: $tripName)
                }
                
                Section("Route") {
                    HStack {
                        Text("From")
                            .foregroundColor(.secondary)
                        Spacer()
                        if locationManager.location != nil {
                            Text("Current Location")
                        } else {
                            Text("Loading...")
                        }
                    }
                    
                    HStack {
                        Text("To")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(destination.name ?? "Destination")
                    }
                    
                    HStack {
                        Text("Distance")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.1f km", route.distance / 1000.0))
                    }
                    
                    HStack {
                        Text("Duration")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(route.expectedTravelTime / 60)) min")
                    }
                }
            }
            .navigationTitle("Create Trip")
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
                    .disabled(tripName.isEmpty || locationManager.location == nil)
                }
            }
            .alert("Error", isPresented: $showAlert) {
                Button("OK") {}
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                locationManager.requestLocationPermission()
                locationManager.startLocationUpdates()
                
                // Set default trip name
                if let destName = destination.name {
                    tripName = "Trip to \(destName)"
                }
            }
        }
    }
    
    private func createTrip() {
        guard let currentUser = authManager.currentUser,
              let location = locationManager.location else {
            showAlert(message: "Unable to get current location")
            return
        }
        
        let fromLocation = TripLocation(
            name: "Current Location",
            address: "",
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        
        let toLocation = TripLocation(
            name: destination.name ?? "Destination",
            address: destination.placemark.title ?? "",
            latitude: destination.placemark.coordinate.latitude,
            longitude: destination.placemark.coordinate.longitude
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
            TripSharingService.shared.shareTrip(trip)
            presentationMode.wrappedValue.dismiss()
        } catch {
            showAlert(message: "Failed to create trip: \(error.localizedDescription)")
        }
    }
    
    private func showAlert(message: String) {
        alertMessage = message
        showAlert = true
    }
}

// Helper extension for custom corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

