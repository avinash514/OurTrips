//
//  ContentView.swift
//  OurTrips
//
//  Created by Avinash Dimmeta on 12/9/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authManager: AuthManager
    @Query private var trips: [RoadTrip]
#if os(iOS)
    @State private var selectedTab = 0
#endif
    
    var activeTrip: RoadTrip? {
        trips.first { trip in
            trip.status == .active &&
            trip.participants.contains(where: { $0.userId == authManager.currentUser?.email })
        }
    }

    var body: some View {
#if os(iOS)
        if let activeTrip = activeTrip {
            NavigationStack {
                NavigationMapView(trip: activeTrip)
                    .environmentObject(authManager)
            }
        } else {
            MapView()
                .environmentObject(authManager)
        }
#else
        NavigationSplitView {
            RoadTripsListView()
                .environmentObject(authManager)
                .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            MapView()
                .environmentObject(authManager)
                .navigationTitle("Map")
        }
#endif
    }
}


