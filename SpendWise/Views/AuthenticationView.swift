import SwiftUI
import LocalAuthentication

struct AuthenticationView: View {
    @StateObject private var securityManager = SecurityManager.shared
    @State private var password: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isPasswordVisible = false
    @State private var authenticationAttempts = 0
    let onSuccess: () -> Void
    
    private let securityType = UserDefaultsManager.loadSecurityType()
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Logo and title
            VStack(spacing: 16) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("SpendWise")
                    .font(.largeTitle.bold())
                
                Text("Authentication is required to access your financial data")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            // Authentication options
            VStack(spacing: 20) {
                if securityType == .biometric || securityType == .both {
                    Button {
                        authenticateWithBiometrics()
                    } label: {
                        HStack {
                            Image(systemName: securityManager.biometricType == .faceID ? "faceid" : "touchid")
                                .font(.title2)
                            Text("Sign in with \(securityManager.getBiometricTypeName())")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!securityManager.isBiometricAvailable)
                }
                
                if securityType == .password || securityType == .both {
                    VStack(spacing: 12) {
                        HStack {
                            if isPasswordVisible {
                                TextField("Password", text: $password)
                                    .textFieldStyle(.roundedBorder)
                            } else {
                                SecureField("Password", text: $password)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            Button {
                                isPasswordVisible.toggle()
                            } label: {
                                Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Button {
                            authenticateWithPassword()
                        } label: {
                            Text("Sign in with Password")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .disabled(password.isEmpty)
                    }
                }
                
                if securityType == .none {
                    Button {
                        onSuccess()
                    } label: {
                        Text("No Security - Continue")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Security information
            VStack(spacing: 8) {
                Text("🔒 Your data is secure")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("If authentication fails, the app will be locked")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 32)
        }
        .background(Color(.systemBackground))
        .alert("Authentication", isPresented: $showAlert) {
            Button("Try Again") { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            // Otomatik biyometrik kimlik doğrulama
            if (securityType == .biometric || securityType == .both) && securityManager.isBiometricAvailable {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    authenticateWithBiometrics()
                }
            }
        }
    }
    
    private func authenticateWithBiometrics() {
        securityManager.authenticateWithBiometrics { success in
            if success {
                onSuccess()
            } else {
                if securityType == .biometric {
                    alertMessage = "Biometric authentication failed. Please try again."
                    showAlert = true
                }
                // If both is selected, continue with password
            }
        }
    }
    
    private func authenticateWithPassword() {
        securityManager.authenticateWithPassword(password) { success in
            if success {
                password = ""
                onSuccess()
            } else {
                authenticationAttempts += 1
                password = ""
                
                if authenticationAttempts >= 3 {
                    alertMessage = "Too many failed attempts. The app is locked."
                } else {
                    alertMessage = "Incorrect password. Attempts left: \(3 - authenticationAttempts)"
                }
                showAlert = true
            }
        }
    }
} 