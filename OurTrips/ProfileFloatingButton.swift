//
//  ProfileFloatingButton.swift
//  OurTrips
//
//  Created by Avinash Dimmeta on 12/9/25.
//

import SwiftUI

struct ProfileFloatingButton: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        Button(action: {
            // Handle profile button tap
        }) {
            if authManager.currentUser != nil {
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.blue)
            } else {
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.gray)
            }
        }
    }
}

#Preview {
    ProfileFloatingButton()
        .environmentObject(AuthManager())
}
