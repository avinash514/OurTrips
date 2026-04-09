//
//  TripDetailView.swift
//  OurTrips
//
//  Created by Avinash Dimmeta on 12/9/25.
//

import SwiftUI
import MapKit

struct TripDetailView: View {
    @StateObject private var locationManager = LocationManager()
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.presentationMode) var presentationMode
    
    var item: Item
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header with back button
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    Text("Trip Details")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal)
                
                // Trip info
                VStack(alignment: .leading, spacing: 12) {
                    Text(item.timestamp, style: .date)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Location: \(locationManager.region.center.latitude), \(locationManager.region.center.longitude)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Map view
                MapView()
                    .frame(height: 300)
                    .cornerRadius(12)
                    .padding(.horizontal)
                
                // Trip actions
                VStack(spacing: 12) {
                    Button(action: {
                        // Share trip
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Trip")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        // Edit trip
                    }) {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Edit Trip")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        // Delete trip
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Trip")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            }
        }
        .onAppear {
            locationManager.requestLocationPermission()
            locationManager.startLocationUpdates()
        }
        .onDisappear {
            locationManager.stopLocationUpdates()
        }
    }
}

#Preview {
    TripDetailView(item: Item(timestamp: Date()))
        .environmentObject(AuthManager())
}
