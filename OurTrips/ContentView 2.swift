import SwiftUI

struct ContentView_TripsListView: View {
    let items: [Item]
    let onAdd: () -> Void
    let onDelete: (IndexSet) -> Void
    
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        ZStack {
            List {
                ForEach(items, id: \.id) { item in
                    NavigationLink(destination: TripDetailView(item: item)) {
                        Text(item.timestamp, format: .dateTime)
                    }
                }
                .onDelete(perform: onDelete)
            }
            .navigationTitle("Trips")
            
            // Ensure this button is only visible if authenticated
            if authManager.isAuthenticated {
                ProfileFloatingButton()
                    .environmentObject(authManager)
                    .padding(.top, 50) // Adjust padding and position as needed
            }
        }
    }
}
