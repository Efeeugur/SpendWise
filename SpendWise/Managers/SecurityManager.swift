import Foundation
import LocalAuthentication
import SwiftUI

enum SecurityType: String, CaseIterable {
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
    
    private let context = LAContext()
    
    private init() {
        checkBiometricAvailability()
    }
    
    func checkBiometricAvailability() {
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
        
        let reason = "Authentication is required to access your financial data"
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.isAuthenticated = true
                    completion(true)
                } else {
                    self.isAuthenticated = false
                    completion(false)
                }
            }
        }
    }
    
    func authenticateWithPassword(_ password: String, completion: @escaping (Bool) -> Void) {
        let savedPassword = UserDefaultsManager.loadSecurityPassword()
        
        if password == savedPassword {
            isAuthenticated = true
            completion(true)
        } else {
            isAuthenticated = false
            completion(false)
        }
    }
    
    func logout() {
        isAuthenticated = false
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
