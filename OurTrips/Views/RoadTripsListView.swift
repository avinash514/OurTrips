//
//  RoadTripsListView.swift
//  OurTrips
//
//  Created by Avinash Dimmeta on 4/9/26.
//

import SwiftUI
import SwiftData

struct RoadTripsListView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authManager: AuthManager
    @Query(sort: \RoadTrip.createdAt, order: .reverse) private var trips: [RoadTrip]
    
    @State private var showCreateTrip = false
    @State private var showJoinTrip = false
    @State private var syncTimer: Timer?
    @State private var isSyncing = false
    
    var myTrips: [RoadTrip] {
        trips.filter { trip in
            // Only show non-cancelled trips, or cancelled trips from today
            if trip.status == .cancelled {
                // Hide old cancelled trips
                if let completedAt = trip.completedAt, Date().timeIntervalSince(completedAt) > 3600 {
                    return false
                }
            }
            return trip.participants.contains(where: { $0.userId == authManager.currentUser?.email })
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if myTrips.isEmpty {
                    EmptyTripsView(
                        onCreateTrip: { showCreateTrip = true },
                        onJoinTrip: { showJoinTrip = true }
                    )
                } else {
                    List {
                        ForEach(myTrips) { trip in
                            NavigationLink(destination: RoadTripDetailView(trip: trip).environmentObject(authManager)) {
                                TripRow(trip: trip, currentUserId: authManager.currentUser?.email ?? "")
                            }
                        }
                        .onDelete(perform: deleteTrips)
                    }
                }
            }
            .navigationTitle("My Trips")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        isSyncing = true
                        syncAllTripStatuses()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            isSyncing = false
                        }
                    }) {
                        if isSyncing {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(isSyncing)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showCreateTrip = true }) {
                            Label("Create Trip", systemImage: "plus.circle")
                        }
                        
                        Button(action: { showJoinTrip = true }) {
                            Label("Join Trip", systemImage: "person.badge.plus")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateTrip) {
                CreateTripView()
                    .environmentObject(authManager)
            }
            .sheet(isPresented: $showJoinTrip) {
                JoinTripView()
                    .environmentObject(authManager)
            }
            .onAppear {
                syncAllTripStatuses()
                // Start periodic sync
                syncTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                    syncAllTripStatuses()
                }
            }
            .onDisappear {
                syncTimer?.invalidate()
                syncTimer = nil
            }
        }
    }
    
    private func syncAllTripStatuses() {
        print("🔄 Syncing all trip statuses...")
        var hasChanges = false
        
        for trip in trips {
            guard let sharedTripData = TripSharingService.shared.getSharedTrip(shareCode: trip.shareCode) else {
                continue
            }
            
            // Check if status has changed
            if let statusRaw = sharedTripData["status"] as? String,
               let newStatus = TripStatus(rawValue: statusRaw),
               newStatus != trip.status {
                print("🔄 Trip '\(trip.name)' status updated: \(trip.status.rawValue) → \(newStatus.rawValue)")
                trip.status = newStatus
                
                // Update timestamps
                if let startedAtInterval = sharedTripData["startedAt"] as? TimeInterval, startedAtInterval > 0 {
                    trip.startedAt = Date(timeIntervalSince1970: startedAtInterval)
                }
                
                if let completedAtInterval = sharedTripData["completedAt"] as? TimeInterval, completedAtInterval > 0 {
                    trip.completedAt = Date(timeIntervalSince1970: completedAtInterval)
                }
                
                hasChanges = true
            }
            
            // Sync participants
            if let participantsData = sharedTripData["participants"] as? [[String: Any]] {
                for participantData in participantsData {
                    guard let userId = participantData["userId"] as? String,
                          let userName = participantData["userName"] as? String,
                          let isOwner = participantData["isOwner"] as? Bool else {
                        continue
                    }
                    
                    // Add participant if they don't exist
                    if !trip.participants.contains(where: { $0.userId == userId }) {
                        let newParticipant = TripParticipant(
                            userId: userId,
                            userName: userName,
                            isOwner: isOwner
                        )
                        trip.participants.append(newParticipant)
                        hasChanges = true
                        print("✅ Added participant '\(userName)' to trip '\(trip.name)'")
                    }
                }
            }
        }
        
        if hasChanges {
            try? modelContext.save()
        }
    }
    
    private func deleteTrips(at offsets: IndexSet) {
        for index in offsets {
            let trip = myTrips[index]
            // Remove from shared storage
            TripSharingService.shared.removeSharedTrip(shareCode: trip.shareCode)
            // Delete from local database
            modelContext.delete(trip)
        }
        try? modelContext.save()
    }
}

struct TripRow: View {
    let trip: RoadTrip
    let currentUserId: String
    
    var isOwner: Bool {
        trip.ownerId == currentUserId
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(trip.name)
                    .font(.headline)
                
                Spacer()
                
                if isOwner {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
                
                StatusBadge(status: trip.status)
            }
            
            HStack(spacing: 4) {
                Image(systemName: "mappin.circle")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(trip.fromLocation.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Image(systemName: "mappin.circle")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(trip.toLocation.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            HStack {
                Image(systemName: "person.2.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(trip.participants.count) participant\(trip.participants.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(trip.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct EmptyTripsView: View {
    let onCreateTrip: () -> Void
    let onJoinTrip: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "car.circle")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Trips Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Create a new road trip or join an existing one")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                Button(action: onCreateTrip) {
                    Label("Create New Trip", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                Button(action: onJoinTrip) {
                    Label("Join Existing Trip", systemImage: "person.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 40)
        }
        .padding()
    }
}

#Preview {
    RoadTripsListView()
        .environmentObject(AuthManager())
}
