//
//  LoginView.swift
//  habitkit
//
//  Login and Registration screens.
//

import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isShowingSignup = false
    @State private var isLoading = false
    
    @ObservedObject private var authManager = AuthManager.shared
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                
                // Logo & Header
                VStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(LinearGradient(colors: [Theme.accent, Color(hex: "8957E5")], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 72, height: 72)
                        Image(systemName: "checkmark")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    
                    Text("Welcome Back")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    
                    Text("Log in to continue building your habits")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.textSecondary)
                }
                
                // Form Fields
                VStack(spacing: 16) {
                    // Email
                    HStack(spacing: 12) {
                        Image(systemName: "envelope.fill")
                            .foregroundStyle(Theme.textTertiary)
                            .frame(width: 24)
                        TextField("Email Address", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .textContentType(.emailAddress)
                            .font(.system(size: 16))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surface))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.border, lineWidth: 1))
                    
                    // Password
                    HStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(Theme.textTertiary)
                            .frame(width: 24)
                        SecureField("Password", text: $password)
                            .textContentType(.password)
                            .font(.system(size: 16))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surface))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.border, lineWidth: 1))
                }
                .padding(.horizontal, 24)
                
                // Login Button
                Button {
                    handleLogin()
                } label: {
                    ZStack {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Log In")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(email.isEmpty || password.isEmpty ? Theme.textTertiary : Theme.accent)
                    )
                }
                .disabled(email.isEmpty || password.isEmpty || isLoading)
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.top, 8)
                
                Spacer()
                
                // Sign Up Link
                HStack(spacing: 4) {
                    Text("Don't have an account?")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textSecondary)
                    Button {
                        isShowingSignup = true
                        HapticManager.light()
                    } label: {
                        Text("Sign Up")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.accent)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 32)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationDestination(isPresented: $isShowingSignup) {
                SignupView()
            }
        }
    }
    
    private func handleLogin() {
        isLoading = true
        HapticManager.medium()
        
        // Simulate auth
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isLoading = false
            authManager.login(email: email)
            HapticManager.success()
        }
    }
}

// MARK: - Signup View

struct SignupView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    
    @ObservedObject private var authManager = AuthManager.shared
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Header
            VStack(spacing: 12) {
                Text("Create Account")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                
                Text("Join HabitKit and transform your life")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.textSecondary)
            }
            
            // Form Fields
            VStack(spacing: 16) {
                // Name
                HStack(spacing: 12) {
                    Image(systemName: "person.fill")
                        .foregroundStyle(Theme.textTertiary)
                        .frame(width: 24)
                    TextField("Full Name", text: $name)
                        .textContentType(.name)
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.textPrimary)
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surface))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.border, lineWidth: 1))
                
                // Email
                HStack(spacing: 12) {
                    Image(systemName: "envelope.fill")
                        .foregroundStyle(Theme.textTertiary)
                        .frame(width: 24)
                    TextField("Email Address", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textContentType(.emailAddress)
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.textPrimary)
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surface))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.border, lineWidth: 1))
                
                // Password
                HStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(Theme.textTertiary)
                        .frame(width: 24)
                    SecureField("Password", text: $password)
                        .textContentType(.newPassword)
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.textPrimary)
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surface))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.border, lineWidth: 1))
            }
            .padding(.horizontal, 24)
            
            // Sign Up Button
            Button {
                handleSignup()
            } label: {
                ZStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Create Account")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(name.isEmpty || email.isEmpty || password.isEmpty ? Theme.textTertiary : Theme.accent)
                )
            }
            .disabled(name.isEmpty || email.isEmpty || password.isEmpty || isLoading)
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.top, 8)
            
            Spacer()
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Log In")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.accent)
                }
            }
        }
        .navigationBarBackButtonHidden()
    }
    
    private func handleSignup() {
        isLoading = true
        HapticManager.medium()
        
        // Simulate Auth
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isLoading = false
            authManager.signup(name: name, email: email)
            HapticManager.success()
        }
    }
}

// MARK: - Previews

#Preview("Login") {
    LoginView()
}

#Preview("Signup") {
    NavigationStack {
        SignupView()
    }
}
