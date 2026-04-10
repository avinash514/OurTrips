//
//  JoinTripView.swift
//  OurTrips
//
//  Created by Avinash Dimmeta on 4/9/26.
//

import SwiftUI
import SwiftData

struct JoinTripView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authManager: AuthManager
    @Query private var trips: [RoadTrip]
    
    @State private var shareCode = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isJoining = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                VStack(spacing: 8) {
                    Text("Join a Road Trip")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Enter the share code provided by your friend")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 16) {
                    TextField("Share Code", text: $shareCode)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.oneTimeCode)
                        .autocapitalization(.allCharacters)
                        .font(.system(size: 20, weight: .semibold, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: joinTrip) {
                        if isJoining {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Join Trip")
                                .fontWeight(.semibold)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                    .disabled(shareCode.isEmpty || isJoining)
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .alert("Join Trip", isPresented: $showAlert) {
                Button("OK") {
                    if alertMessage.contains("Successfully") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func joinTrip() {
        guard let currentUser = authManager.currentUser else {
            showAlert(message: "You must be logged in to join a trip")
            return
        }
        
        let cleanCode = shareCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        // First, check if trip exists locally
        if let existingTrip = trips.first(where: { $0.shareCode == cleanCode }) {
            // Check if user is already a participant
            if existingTrip.participants.contains(where: { $0.userId == currentUser.email }) {
                showAlert(message: "You are already a participant in this trip!")
                return
            }
            
            // Add to existing local trip
            addParticipantToTrip(existingTrip)
            return
        }
        
        // If not found locally, check shared storage
        guard let sharedTripData = TripSharingService.shared.getSharedTrip(shareCode: cleanCode) else {
            showAlert(message: "Trip not found. Please check the share code and try again.")
            return
        }
        
        // Create local copy of the trip
        isJoining = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            do {
                let fromLocation = TripLocation(
                    name: sharedTripData["fromLocationName"] as? String ?? "",
                    address: sharedTripData["fromLocationAddress"] as? String ?? "",
                    latitude: sharedTripData["fromLocationLat"] as? Double ?? 0.0,
                    longitude: sharedTripData["fromLocationLon"] as? Double ?? 0.0
                )
                
                let toLocation = TripLocation(
                    name: sharedTripData["toLocationName"] as? String ?? "",
                    address: sharedTripData["toLocationAddress"] as? String ?? "",
                    latitude: sharedTripData["toLocationLat"] as? Double ?? 0.0,
                    longitude: sharedTripData["toLocationLon"] as? Double ?? 0.0
                )
                
                let trip = RoadTrip(
                    id: sharedTripData["id"] as? String ?? UUID().uuidString,
                    name: sharedTripData["name"] as? String ?? "Road Trip",
                    fromLocation: fromLocation,
                    toLocation: toLocation,
                    ownerId: sharedTripData["ownerId"] as? String ?? "",
                    ownerName: sharedTripData["ownerName"] as? String ?? "",
                    shareCode: cleanCode
                )
                
                // Set status if available
                if let statusRaw = sharedTripData["status"] as? String,
                   let status = TripStatus(rawValue: statusRaw) {
                    trip.status = status
                }
                
                // Add current user as participant
                let newParticipant = TripParticipant(
                    userId: currentUser.email,
                    userName: currentUser.name ?? currentUser.email,
                    isOwner: false
                )
                trip.participants.append(newParticipant)
                
                modelContext.insert(trip)
                try modelContext.save()
                
                // Share the updated trip so the owner can see the new participant
                TripSharingService.shared.shareTrip(trip)
                
                showAlert(message: "Successfully joined \(trip.name)! 🎉")
            } catch {
                showAlert(message: "Failed to join trip: \(error.localizedDescription)")
            }
            
            isJoining = false
        }
    }
    
    private func addParticipantToTrip(_ trip: RoadTrip) {
        guard let currentUser = authManager.currentUser else { return }
        
        isJoining = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let newParticipant = TripParticipant(
                userId: currentUser.email,
                userName: currentUser.name ?? currentUser.email,
                isOwner: false
            )
            
            trip.participants.append(newParticipant)
            
            do {
                try modelContext.save()
                
                // Share the updated trip so the owner can see the new participant
                TripSharingService.shared.shareTrip(trip)
                
                showAlert(message: "Successfully joined \(trip.name)! 🎉")
            } catch {
                showAlert(message: "Failed to join trip: \(error.localizedDescription)")
            }
            
            isJoining = false
        }
    }
    
    private func showAlert(message: String) {
        alertMessage = message
        showAlert = true
    }
}

#Preview {
    JoinTripView()
        .environmentObject(AuthManager())
}
