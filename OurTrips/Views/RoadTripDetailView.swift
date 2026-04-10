//
//  RoadTripDetailView.swift
//  OurTrips
//
//  Created by Avinash Dimmeta on 4/9/26.
//

import SwiftUI
import SwiftData

struct RoadTripDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authManager: AuthManager
    @Bindable var trip: RoadTrip
    @State private var showShareSheet = false
    @State private var showStartConfirmation = false
    @State private var showLiveTracking = false
    @State private var showEndConfirmation = false
    @State private var showCancelConfirmation = false
    @State private var syncTimer: Timer?
    @State private var lastKnownStatus: TripStatus
    
    init(trip: RoadTrip) {
        self.trip = trip
        _lastKnownStatus = State(initialValue: trip.status)
    }
    
    var isOwner: Bool {
        trip.ownerId == authManager.currentUser?.email
    }
    
    var body: some View {
        List {
            Section("Trip Information") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.green)
                        VStack(alignment: .leading) {
                            Text("From")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(trip.fromLocation.name)
                                .font(.headline)
                        }
                    }
                    
                    Divider()
                    
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.red)
                        VStack(alignment: .leading) {
                            Text("To")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(trip.toLocation.name)
                                .font(.headline)
                        }
                    }
                }
                .padding(.vertical, 8)
                
                HStack {
                    Text("Status")
                        .foregroundColor(.secondary)
                    Spacer()
                    StatusBadge(status: trip.status)
                }
                
                HStack {
                    Text("Created by")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(trip.ownerName)
                }
                
                HStack {
                    Text("Share Code")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(trip.shareCode)
                        .fontWeight(.semibold)
                        .font(.system(.body, design: .monospaced))
                }
            }
            
            Section("Participants (\(trip.participants.count))") {
                ForEach(trip.participants) { participant in
                    HStack {
                        Image(systemName: participant.isOwner ? "star.circle.fill" : "person.circle.fill")
                            .foregroundColor(participant.isOwner ? .yellow : .blue)
                        
                        VStack(alignment: .leading) {
                            Text(participant.userName)
                                .font(.headline)
                            Text(participant.isOwner ? "Trip Owner" : "Participant")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if trip.status == .active && participant.lastUpdated != nil {
                            Image(systemName: "location.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            if isOwner {
                Section("Trip Actions") {
                    Button(action: { showShareSheet = true }) {
                        Label("Share Trip", systemImage: "square.and.arrow.up")
                    }
                    
                    if trip.status == .planned {
                        Button(action: { showStartConfirmation = true }) {
                            Label("Start Trip", systemImage: "play.circle.fill")
                                .foregroundColor(.green)
                        }
                        
                        Button(action: { showCancelConfirmation = true }) {
                            Label("Cancel Trip", systemImage: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                    
                    if trip.status == .active {
                        Button(action: { showLiveTracking = true }) {
                            Label("Start Navigation", systemImage: "location.fill.viewfinder")
                                .foregroundColor(.blue)
                        }
                        
                        Button(action: { showEndConfirmation = true }) {
                            Label("End Trip", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                        
                        Button(action: { showCancelConfirmation = true }) {
                            Label("Cancel Trip", systemImage: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
            } else {
                if trip.status == .active {
                    Section {
                        Button(action: { showLiveTracking = true }) {
                            Label("Start Navigation", systemImage: "location.fill.viewfinder")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle(trip.name)
        .sheet(isPresented: $showShareSheet) {
            ShareTripView(trip: trip)
        }
        .sheet(isPresented: $showLiveTracking) {
            NavigationStack {
                NavigationMapView(trip: trip)
                    .environmentObject(authManager)
            }
        }
        .confirmationDialog("Start this trip?", isPresented: $showStartConfirmation, titleVisibility: .visible) {
            Button("Start Trip", role: .none) {
                startTrip()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All participants will be able to see each other's location during the trip.")
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
        .onAppear {
            // Start syncing trip status for all users (not just non-owners)
            // This allows owner to see when participants join
            startStatusSync()
        }
        .onDisappear {
            syncTimer?.invalidate()
            syncTimer = nil
        }
        .onChange(of: trip.status) { oldValue, newValue in
            // Auto-navigate to navigation view when trip becomes active
            print("🔔 Trip status changed: \(oldValue.rawValue) → \(newValue.rawValue)")
            if newValue == .active && oldValue != .active {
                print("🚀 Auto-launching navigation...")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showLiveTracking = true
                }
            }
        }
        .onChange(of: trip.participants.count) { oldCount, newCount in
            print("👥 Participant count changed: \(oldCount) → \(newCount)")
        }
    }
    
    private func startStatusSync() {
        // Poll for status updates every 2 seconds
        syncTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            checkForStatusUpdates()
        }
    }
    
    private func checkForStatusUpdates() {
        guard let sharedTripData = TripSharingService.shared.getSharedTrip(shareCode: trip.shareCode) else {
            return
        }
        
        var hasChanges = false
        
        // Check if status has changed
        if let statusRaw = sharedTripData["status"] as? String,
           let newStatus = TripStatus(rawValue: statusRaw),
           newStatus != trip.status {
            print("🔄 Status changed from \(trip.status.rawValue) to \(newStatus.rawValue)")
            
            DispatchQueue.main.async {
                trip.status = newStatus
                
                // Update timestamps if available
                if let startedAtInterval = sharedTripData["startedAt"] as? TimeInterval, startedAtInterval > 0 {
                    trip.startedAt = Date(timeIntervalSince1970: startedAtInterval)
                }
                
                if let completedAtInterval = sharedTripData["completedAt"] as? TimeInterval, completedAtInterval > 0 {
                    trip.completedAt = Date(timeIntervalSince1970: completedAtInterval)
                }
                
                hasChanges = true
            }
        }
        
        // Check for new participants
        if let participantsData = sharedTripData["participants"] as? [[String: Any]] {
            for participantData in participantsData {
                guard let userId = participantData["userId"] as? String,
                      let userName = participantData["userName"] as? String,
                      let isOwner = participantData["isOwner"] as? Bool else {
                    continue
                }
                
                // Add participant if they don't exist in our local list
                if !trip.participants.contains(where: { $0.userId == userId }) {
                    DispatchQueue.main.async {
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
            }
        }
        
        if hasChanges {
            try? modelContext.save()
        }
    }
    
    private func startTrip() {
        trip.status = .active
        trip.startedAt = Date()
        try? modelContext.save()
        
        // Update shared storage
        TripSharingService.shared.shareTrip(trip)
        
        // Auto-navigate to navigation view
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showLiveTracking = true
        }
    }
    
    private func endTrip() {
        trip.status = .completed
        trip.completedAt = Date()
        try? modelContext.save()
        
        // Update shared storage
        TripSharingService.shared.shareTrip(trip)
    }
    
    private func cancelTrip() {
        trip.status = .cancelled
        trip.completedAt = Date()
        try? modelContext.save()
        
        // Update shared storage
        TripSharingService.shared.shareTrip(trip)
    }
}

struct StatusBadge: View {
    let status: TripStatus
    
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
    
    var backgroundColor: Color {
        switch status {
        case .planned: return .blue
        case .active: return .green
        case .completed: return .gray
        case .cancelled: return .red
        }
    }
}

struct ShareTripView: View {
    @Environment(\.presentationMode) var presentationMode
    let trip: RoadTrip
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "car.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                VStack(spacing: 8) {
                    Text("Share Your Trip")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Friends can join using this code or link")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Text("Share Code")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(trip.shareCode)
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                    }
                    
                    Button(action: copyShareCode) {
                        Label("Copy Share Code", systemImage: "doc.on.doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: shareTrip) {
                        Label("Share Link", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func copyShareCode() {
        UIPasteboard.general.string = trip.shareCode
    }
    
    private func shareTrip() {
        let shareText = TripSharingService.shared.generateShareMessage(for: trip)
        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
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
    container.mainContext.insert(trip)
    
    return NavigationStack {
        RoadTripDetailView(trip: trip)
            .environmentObject(AuthManager())
            .modelContainer(container)
    }
}
