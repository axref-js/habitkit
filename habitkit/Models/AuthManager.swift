//
//  AuthManager.swift
//  habitkit
//
//  Manages user authentication state (login/signup).
//

import SwiftUI
import Combine

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isAuthenticated: Bool {
        didSet {
            UserDefaults.standard.set(isAuthenticated, forKey: "isAuthenticated")
        }
    }
    
    private init() {
        self.isAuthenticated = UserDefaults.standard.bool(forKey: "isAuthenticated")
    }
    
    func login(email: String) {
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.isAuthenticated = true
        }
    }
    
    func signup(name: String, email: String) {
        // Save name to AppStorage
        UserDefaults.standard.set(name, forKey: "userName")
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.isAuthenticated = true
        }
    }
    
    func logout() {
        self.isAuthenticated = false
    }
}
