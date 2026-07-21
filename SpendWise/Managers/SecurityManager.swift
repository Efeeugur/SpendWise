import Foundation
import LocalAuthentication
import SwiftUI

enum SecurityType: String, CaseIterable, Codable {
    case none = "No Protection"
    case password = "Password"
    case biometric = "Face ID / Touch ID"
    case both = "Password + Face ID / Touch ID"
    
    var description: String {
        switch self {
        case .none: return "No app protection"
        case .password: return "Protected with password only"
        case .biometric: return "Protected with Face ID / Touch ID only"
        case .both: return "Protected with password and Face ID / Touch ID"
        }
    }
}

class SecurityManager: ObservableObject {
    static let shared = SecurityManager()
    
    @Published var isAuthenticated = false
    @Published var biometricType: LABiometryType = .none
    @Published var isBiometricAvailable = false
    @Published var isLockedOut = false
    @Published var remainingAttempts: Int = KeychainManager.maxFailedAttempts
    
    private init() {
        checkBiometricAvailability()
        updateLockoutState()
    }
    
    func checkBiometricAvailability() {
        // Create a fresh LAContext per check — Apple recommends not reusing contexts
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            isBiometricAvailable = true
            biometricType = context.biometryType
        } else {
            isBiometricAvailable = false
            biometricType = .none
        }
    }
    
    func authenticateWithBiometrics(completion: @escaping (Bool) -> Void) {
        guard isBiometricAvailable else {
            completion(false)
            return
        }
        
        guard !KeychainManager.isLockedOut() else {
            isLockedOut = true
            completion(false)
            return
        }
        
        // Fresh LAContext per authentication request
        let context = LAContext()
        let reason = "Authentication is required to access your financial data"
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.isAuthenticated = true
                    KeychainManager.resetFailedAttempts()
                    KeychainManager.updateLastActiveTime()
                    self.updateLockoutState()
                    completion(true)
                } else {
                    self.isAuthenticated = false
                    KeychainManager.incrementFailedAttempts()
                    self.updateLockoutState()
                    completion(false)
                }
            }
        }
    }
    
    func authenticateWithPassword(_ password: String, completion: @escaping (Bool) -> Void) {
        // Check lockout first
        guard !KeychainManager.isLockedOut() else {
            isLockedOut = true
            completion(false)
            return
        }
        
        if KeychainManager.verifyPassword(password) {
            isAuthenticated = true
            KeychainManager.resetFailedAttempts()
            KeychainManager.updateLastActiveTime()
            updateLockoutState()
            completion(true)
        } else {
            isAuthenticated = false
            KeychainManager.incrementFailedAttempts()
            updateLockoutState()
            completion(false)
        }
    }
    
    func logout() {
        isAuthenticated = false
    }
    
    /// Check if the session has expired due to inactivity
    func checkSessionTimeout() {
        if isAuthenticated && KeychainManager.hasSessionTimedOut() {
            isAuthenticated = false
        }
    }
    
    /// Call this when user interacts with the app
    func refreshSession() {
        if isAuthenticated {
            KeychainManager.updateLastActiveTime()
        }
    }
    
    func updateLockoutState() {
        isLockedOut = KeychainManager.isLockedOut()
        remainingAttempts = max(0, KeychainManager.maxFailedAttempts - KeychainManager.getFailedAttempts())
    }
    
    func getBiometricTypeName() -> String {
        switch biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .none:
            return "No Biometric Authentication"
        case .opticID:
            return "Optic ID"
        @unknown default:
            return "Unknown"
        }
    }
}
