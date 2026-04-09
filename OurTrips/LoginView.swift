//
//  LoginView.swift
//  OurTrips
//
//  Created by Avinash Dimmeta on 12/9/25.
//

import SwiftUI


struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showRegistration = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "map.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                Text("OurTrips")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Sign in to continue")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            
            // Login Form
            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
#if os(iOS)
                    .keyboardType(.emailAddress)
#endif
                
                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.password)
                
                if showError {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Button(action: handleLogin) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Sign In")
                            .fontWeight(.semibold)
                    }
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(isLoading || email.isEmpty || password.isEmpty)
                
                Button(action: { showRegistration = true }) {
                    Text("Don't have an account? Sign Up")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showRegistration) {
            RegistrationView()
                .environmentObject(authManager)
        }
    }
    
    private func handleLogin() {
        guard authManager.validateEmail(email) else {
            showError(message: "Please enter a valid email address")
            return
        }
        
        guard authManager.validatePassword(password) else {
            showError(message: "Password must be at least 6 characters")
            return
        }
        
        isLoading = true
        showError = false
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if authManager.login(email: email, password: password) {
                // Success - authManager will update isAuthenticated
            } else {
                showError(message: "Invalid email or password")
            }
            isLoading = false
        }
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager())
}

