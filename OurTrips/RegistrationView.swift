//
//  RegistrationView.swift
//  OurTrips
//
//  Created by Avinash Dimmeta on 12/9/25.
//

import SwiftUI

struct RegistrationView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        Text("Create Account")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    .padding(.top, 40)
                    
                    // Registration Form
                    VStack(spacing: 16) {
                        TextField("Name", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.name)
                        
                        TextField("Email", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.emailAddress)
#if os(iOS)
                            .keyboardType(.emailAddress)
#endif
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.password)
                        
                        SecureField("Confirm Password", text: $confirmPassword)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.password)
                        
                        Button(action: handleRegister) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Sign Up")
                                    .fontWeight(.semibold)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                        .disabled(isLoading || name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty)
                        
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Already have an account? Sign In")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal, 32)
                }
                .padding()
            }
            .alert("Error", isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func handleRegister() {
        guard password == confirmPassword else {
            showAlert(message: "Passwords do not match")
            return
        }
        
        guard authManager.validateEmail(email) else {
            showAlert(message: "Please enter a valid email address")
            return
        }
        
        guard authManager.validatePassword(password) else {
            showAlert(message: "Password must be at least 6 characters")
            return
        }
        
        isLoading = true
        
        // Simulate network request
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if authManager.register(email: email, password: password, name: name) {
                presentationMode.wrappedValue.dismiss()
            } else {
                showAlert(message: "Registration failed. Please try again.")
            }
            isLoading = false
        }
    }
    
    private func showAlert(message: String) {
        alertMessage = message
        showAlert = true
    }
}

#Preview {
    RegistrationView()
        .environmentObject(AuthManager())
}
