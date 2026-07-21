import SwiftUI
import LocalAuthentication

struct AuthenticationView: View {
    @ObservedObject private var securityManager = SecurityManager.shared
    @State private var password: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isPasswordVisible = false
    @State private var lockoutTimer: Timer? = nil
    @State private var lockoutTimeRemaining: Int = 0
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
            
            // Lockout warning
            if securityManager.isLockedOut {
                VStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                    
                    Text("Account Locked")
                        .font(.title3.bold())
                        .foregroundColor(.red)
                    
                    Text("Too many failed attempts. Try again in \(formatTime(lockoutTimeRemaining)).")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal, 32)
            } else {
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
                            
                            // Remaining attempts indicator
                            if securityManager.remainingAttempts < KeychainManager.maxFailedAttempts {
                                Text("Attempts remaining: \(securityManager.remainingAttempts)")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
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
            }
            
            Spacer()
            
            // Security information
            VStack(spacing: 8) {
                Text("🔒 Your data is secure")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("After \(KeychainManager.maxFailedAttempts) failed attempts, the app will be temporarily locked")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 32)
        }
        .background(Color(.systemBackground))
        .alert("Authentication", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            securityManager.updateLockoutState()
            startLockoutTimerIfNeeded()
            
            // Auto biometric auth
            if !securityManager.isLockedOut &&
               (securityType == .biometric || securityType == .both) &&
               securityManager.isBiometricAvailable {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    authenticateWithBiometrics()
                }
            }
        }
        .onDisappear {
            lockoutTimer?.invalidate()
            lockoutTimer = nil
        }
    }
    
    private func authenticateWithBiometrics() {
        securityManager.authenticateWithBiometrics { success in
            if success {
                onSuccess()
            } else {
                if securityManager.isLockedOut {
                    startLockoutTimerIfNeeded()
                } else if securityType == .biometric {
                    alertMessage = "Biometric authentication failed. Please try again."
                    showAlert = true
                }
            }
        }
    }
    
    private func authenticateWithPassword() {
        securityManager.authenticateWithPassword(password) { success in
            if success {
                password = ""
                onSuccess()
            } else {
                password = ""
                
                if securityManager.isLockedOut {
                    startLockoutTimerIfNeeded()
                } else {
                    alertMessage = "Incorrect password. Attempts remaining: \(securityManager.remainingAttempts)"
                    showAlert = true
                }
            }
        }
    }
    
    private func startLockoutTimerIfNeeded() {
        guard securityManager.isLockedOut else { return }
        
        lockoutTimeRemaining = Int(KeychainManager.remainingLockoutTime())
        lockoutTimer?.invalidate()
        lockoutTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            DispatchQueue.main.async {
                lockoutTimeRemaining -= 1
                if lockoutTimeRemaining <= 0 {
                    timer.invalidate()
                    lockoutTimer = nil
                    securityManager.updateLockoutState()
                }
            }
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}