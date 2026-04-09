//
//  AuthManager.swift
//  OurTrips
//
//  Created by Avinash Dimmeta on 12/9/25.
//

import Foundation
import Combine

@MainActor
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    private let userDefaults = UserDefaults.standard
    private let authKey = "isAuthenticated"
    private let userEmailKey = "currentUserEmail"
    
    init() {
        checkAuthenticationStatus()
    }
    
    func checkAuthenticationStatus() {
        isAuthenticated = userDefaults.bool(forKey: authKey)
        if isAuthenticated, let email = userDefaults.string(forKey: userEmailKey) {
            // Load user data if needed
            currentUser = User(email: email)
        }
    }
    
    func login(email: String, password: String) -> Bool {
        // In a real app, this would validate against a backend
        // For now, we'll check if user exists in UserDefaults
        let userKey = "user_\(email)"
        guard let userData = userDefaults.data(forKey: userKey),
              let storedUser = try? JSONDecoder().decode(StoredUser.self, from: userData),
              storedUser.password == password else {
            return false
        }
        
        isAuthenticated = true
        currentUser = User(email: email)
        userDefaults.set(true, forKey: authKey)
        userDefaults.set(email, forKey: userEmailKey)
        return true
    }
    
    func register(email: String, password: String, name: String) -> Bool {
        // Check if user already exists
        let userKey = "user_\(email)"
        if userDefaults.data(forKey: userKey) != nil {
            return false // User already exists
        }
        
        // Store new user
        let newUser = StoredUser(email: email, password: password, name: name)
        if let userData = try? JSONEncoder().encode(newUser) {
            userDefaults.set(userData, forKey: userKey)
            
            // Auto-login after registration
            isAuthenticated = true
            currentUser = User(email: email, name: name)
            userDefaults.set(true, forKey: authKey)
            userDefaults.set(email, forKey: userEmailKey)
            return true
        }
        
        return false
    }
    
    func logout() {
        isAuthenticated = false
        currentUser = nil
        userDefaults.set(false, forKey: authKey)
        userDefaults.removeObject(forKey: userEmailKey)
    }
    
    func validateEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    func validatePassword(_ password: String) -> Bool {
        return password.count >= 6
    }
}

struct User {
    let email: String
    var name: String?
    
    init(email: String, name: String? = nil) {
        self.email = email
        self.name = name
    }
}

private struct StoredUser: Codable {
    let email: String
    let password: String
    let name: String
}

