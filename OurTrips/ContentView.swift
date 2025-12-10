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
    @Query private var items: [Item]
#if os(iOS)
    @State private var selectedTab = 0
#endif

    var body: some View {
#if os(iOS)
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
            .toolbar {
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Trip", systemImage: "plus")
                    }
                }
            }
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

struct TripsListView: View {
    let items: [Item]
    let onAdd: () -> Void
    let onDelete: (IndexSet) -> Void
    
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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
            ToolbarItem {
                Button(action: onAdd) {
                    Label("Add Trip", systemImage: "plus")
                }
            }
        }
    }
}

struct TripDetailView: View {
    let item: Item
    
    var body: some View {
        VStack(spacing: 20) {
            MapView()
                .frame(height: 300)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Trip Details")
                    .font(.headline)
                Text("Date: \(item.timestamp, format: Date.FormatStyle(date: .long, time: .shortened))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            
            Spacer()
        }
        .navigationTitle("Trip")
#if os(macOS)
        .navigationSubtitle(item.timestamp.formatted(date: .long, time: .shortened))
#endif
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Item.self, configurations: config)
    
    return ContentView()
        .modelContainer(container)
}
