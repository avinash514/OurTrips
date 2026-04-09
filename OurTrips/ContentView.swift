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
    @Query private var items: [Item]
#if os(iOS)
    @State private var selectedTab = 0
#endif

    var body: some View {
#if os(iOS)
        ZStack {
            TabView(selection: $selectedTab) {
                MapView()
                    .tabItem {
                        Label("Map", systemImage: "map")
                    }
                    .tag(0)
                
                TripsListView(items: items, onAdd: addItem, onDelete: deleteItems)
                    .tabItem {
                        Label("Trips", systemImage: "list.bullet")
                    }
                    .tag(1)
            }
            
            // Floating profile button overlay
            if authManager.isAuthenticated {
                VStack {
                    HStack {
                        Spacer()
                        ProfileFloatingButton()
                            .environmentObject(authManager)
                            .padding(.top, 8)
                            .padding(.trailing, 16)
                    }
                    Spacer()
                }
            }
        }
#else
        NavigationSplitView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        TripDetailView(item: item)
                    } label: {
                        Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            .navigationTitle("Trips")
            .toolbar { ToolbarItem { Button(action: addItem) { Label("Add Trip", systemImage: "plus") } } }
        } detail: {
            MapView()
                .navigationTitle("Map")
        }
#endif
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#if os(iOS)
struct TripsListView: View {
    let items: [Item]
    let onAdd: () -> Void
    let onDelete: (IndexSet) -> Void
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        List {
            ForEach(items) { item in
                NavigationLink {
                    TripDetailView(item: item)
                } label: {
                    Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                }
            }
            .onDelete(perform: onDelete)
        }
        .navigationTitle("Trips")
    }
}
#endif


