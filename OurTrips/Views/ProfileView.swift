//
//  ProfileView.swift
//  OurTrips
//
//  Created by Avinash Dimmeta on 4/9/26.
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authManager: AuthManager
    @Query(sort: \RoadTrip.createdAt, order: .reverse) private var trips: [RoadTrip]
    @State private var showLogoutConfirmation = false
    @State private var showTrips = false
    
    var myActiveTrips: [RoadTrip] {
        trips.filter { trip in
            trip.participants.contains(where: { $0.userId == authManager.currentUser?.email }) &&
            (trip.status == .planned || trip.status == .active)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(authManager.currentUser?.name ?? "User")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text(authManager.currentUser?.email ?? "")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 12)
                    }
                    .padding(.vertical, 12)
                }
                
                Section("Account") {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        Text("Email")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(authManager.currentUser?.email ?? "")
                            .foregroundColor(.primary)
                    }
                    
                    if let name = authManager.currentUser?.name {
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            Text("Name")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(name)
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                Section("My Trips") {
                    if myActiveTrips.isEmpty {
                        HStack {
                            Image(systemName: "car.circle")
                                .foregroundColor(.secondary)
                                .frame(width: 24)
                            Text("No active trips")
                                .foregroundColor(.secondary)
                        }
                    } else {
                        ForEach(myActiveTrips.prefix(3)) { trip in
                            NavigationLink(destination: RoadTripDetailView(trip: trip).environmentObject(authManager)) {
                                HStack {
                                    Image(systemName: trip.status == .active ? "location.fill" : "car.fill")
                                        .foregroundColor(trip.status == .active ? .green : .blue)
                                        .frame(width: 24)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(trip.name)
                                            .font(.headline)
                                        HStack(spacing: 4) {
                                            Text("Code:")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text(trip.shareCode)
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    Spacer()
                                    StatusBadge(status: trip.status)
                                }
                            }
                            .contextMenu {
                                Button(action: {
                                    UIPasteboard.general.string = trip.shareCode
                                }) {
                                    Label("Copy Share Code", systemImage: "doc.on.doc")
                                }
                            }
                        }
                        
                        if myActiveTrips.count > 3 {
                            Button(action: { showTrips = true }) {
                                HStack {
                                    Image(systemName: "list.bullet")
                                        .foregroundColor(.blue)
                                        .frame(width: 24)
                                    Text("See All Trips")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                
                Section("App Information") {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        Text("Version")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.primary)
                    }
                    
                    HStack {
                        Image(systemName: "hammer.fill")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        Text("Build")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("1")
                            .foregroundColor(.primary)
                    }
                }
                
                Section {
                    Button(action: {
                        showLogoutConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.square")
                                .foregroundColor(.red)
                                .frame(width: 24)
                            Text("Logout")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .confirmationDialog("Are you sure you want to logout?", isPresented: $showLogoutConfirmation, titleVisibility: .visible) {
                Button("Logout", role: .destructive) {
                    authManager.logout()
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showTrips) {
                NavigationStack {
                    RoadTripsListView()
                        .environmentObject(authManager)
                        .navigationTitle("All Trips")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showTrips = false
                                }
                            }
                        }
                }
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager())
}
