//
//  TeacherLoginView.swift
//  appi4Manager
//
//  Teacher authentication login form
//

import SwiftUI

struct TeacherLoginView: View {
    @Environment(AuthenticationManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isAuthenticating = false
    @State private var errorMessage: String?
    
    // Company ID - can be made configurable if needed
    private let companyId = "2001128"
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                headerView
                
                // Input Fields
                inputFieldsView
                
                // Error Message
                if let errorMessage = errorMessage {
                    errorView(message: errorMessage)
                }
                
                // Sign In Button
                signInButton
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 40)
        }
        .navigationTitle("Teacher Login")
        .navigationBarTitleDisplayMode(.inline)
        .disabled(isAuthenticating)
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.badge.key.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text("Sign in with your teacher credentials")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Input Fields
    
    private var inputFieldsView: some View {
        VStack(spacing: 16) {
            // Username Field
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(.gray)
                    .frame(width: 24)
                
                TextField("Username", text: $username)
                    .textContentType(.username)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            // Password Field
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundColor(.gray)
                    .frame(width: 24)
                
                SecureField("Password", text: $password)
                    .textContentType(.password)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
    
    // MARK: - Error View
    
    private func errorView(message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.red)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Sign In Button
    
    private var signInButton: some View {
        Button {
            Task {
                await authenticate()
            }
        } label: {
            Group {
                if isAuthenticating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Sign In")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
        }
        .background(canSignIn ? Color.accentColor : Color.gray)
        .foregroundColor(.white)
        .cornerRadius(12)
        .disabled(!canSignIn)
    }
    
    // MARK: - Computed Properties
    
    private var canSignIn: Bool {
        !username.isEmpty && !password.isEmpty && !isAuthenticating
    }
    
    // MARK: - Actions
    
    private func authenticate() async {
        isAuthenticating = true
        errorMessage = nil
        
        do {
            try await authManager.authenticate(
                company: companyId,
                username: username,
                password: password
            )
            
            // Clear password for security
            password = ""
            
            // Dismiss view on success
            await MainActor.run {
                dismiss()
            }
            
        } catch let error as ApiError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Authentication failed: \(error.localizedDescription)"
        }
        
        isAuthenticating = false
    }
}

#Preview {
    NavigationStack {
        TeacherLoginView()
            .environment(AuthenticationManager())
    }
}
