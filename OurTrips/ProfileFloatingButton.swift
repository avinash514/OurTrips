//
//  ProfileFloatingButton.swift
//  OurTrips
//
//  Created by Avinash Dimmeta on 12/9/25.
//

import SwiftUI

struct ProfileFloatingButton: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showProfileSheet = false
    
    var body: some View {
        Button(action: {
            showProfileSheet = true
        }) {
            if authManager.currentUser != nil {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.blue)
                    .background(Color.white.opacity(0.9), in: Circle())
                    .shadow(radius: 3)
            } else {
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.gray)
                    .background(Color.white.opacity(0.9), in: Circle())
                    .shadow(radius: 3)
            }
        }
        .sheet(isPresented: $showProfileSheet) {
            ProfileSheet()
                .environmentObject(authManager)
        }
    }
}

struct ProfileSheet: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.presentationMode) var presentationMode
    @State private var showLogoutConfirmation = false
    
    var body: some View {
        NavigationStack {
            List {
                Section("Account Information") {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(authManager.currentUser?.name ?? "User")
                                .font(.headline)
                            Text(authManager.currentUser?.email ?? "")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 8)
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    Button(action: {
                        showLogoutConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.square")
                                .foregroundColor(.red)
                            Text("Logout")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .confirmationDialog("Are you sure you want to logout?", isPresented: $showLogoutConfirmation, titleVisibility: .visible) {
                Button("Logout", role: .destructive) {
                    authManager.logout()
                    presentationMode.wrappedValue.dismiss()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}

#Preview {
    ProfileFloatingButton()
        .environmentObject(AuthManager())
}
