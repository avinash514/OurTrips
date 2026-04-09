//
//  OurTripsApp.swift
//  OurTrips
//
//  Created by Avinash Dimmeta on 12/9/25.
//

import SwiftUI
import SwiftData

@main
struct OurTripsApp: App {
    @StateObject private var authManager = AuthManager()
    
    var sharedModelContainer: ModelContainer = {
        do {
            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: false)
            return try ModelContainer(for: Item.self, configurations: modelConfiguration)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                ContentView()
                    .environmentObject(authManager)
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
