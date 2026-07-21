import Foundation
import Security
import CryptoKit

/// Secure credential storage using iOS Keychain
/// Replaces insecure UserDefaults password storage
struct KeychainManager {
    
    // MARK: - Keychain Keys
    private static let passwordHashKey = "com.spendwise.security.passwordHash"
    private static let passwordSaltKey = "com.spendwise.security.passwordSalt"
    private static let failedAttemptsKey = "com.spendwise.security.failedAttempts"
    private static let lockoutEndKey = "com.spendwise.security.lockoutEnd"
    private static let lastActiveKey = "com.spendwise.security.lastActive"
    
    // MARK: - Configuration
    static let maxFailedAttempts = 5
    static let lockoutDuration: TimeInterval = 300 // 5 minutes
    static let sessionTimeout: TimeInterval = 300 // 5 minutes of inactivity
    
    // MARK: - Password Management
    
    /// Save a password securely with salt + SHA-256 hashing
    static func savePassword(_ password: String) -> Bool {
        // Generate a random salt
        let salt = generateSalt()
        
        // Hash password with salt
        let hashedPassword = hashPassword(password, salt: salt)
        
        // Save hash and salt to Keychain
        let hashSaved = save(key: passwordHashKey, data: hashedPassword)
        let saltSaved = save(key: passwordSaltKey, data: salt)
        
        return hashSaved && saltSaved
    }
    
    /// Verify a password against the stored hash
    static func verifyPassword(_ password: String) -> Bool {
        guard let storedHash = load(key: passwordHashKey),
              let storedSalt = load(key: passwordSaltKey) else {
            return false
        }
        
        let inputHash = hashPassword(password, salt: storedSalt)
        return inputHash == storedHash
    }
    
    /// Check if a password is stored
    static func hasPassword() -> Bool {
        return load(key: passwordHashKey) != nil
    }
    
    /// Delete stored password
    static func deletePassword() {
        delete(key: passwordHashKey)
        delete(key: passwordSaltKey)
    }
    
    // MARK: - Failed Attempts & Lockout
    
    /// Get current failed attempt count
    static func getFailedAttempts() -> Int {
        guard let data = load(key: failedAttemptsKey) else { return 0 }
        return Int(data) ?? 0
    }
    
    /// Increment failed attempt count
    static func incrementFailedAttempts() {
        let current = getFailedAttempts() + 1
        _ = save(key: failedAttemptsKey, data: String(current))
        
        // Apply lockout if max attempts reached
        if current >= maxFailedAttempts {
            let lockoutEnd = Date().addingTimeInterval(lockoutDuration)
            _ = save(key: lockoutEndKey, data: String(lockoutEnd.timeIntervalSince1970))
        }
    }
    
    /// Reset failed attempt count (on successful auth)
    static func resetFailedAttempts() {
        delete(key: failedAttemptsKey)
        delete(key: lockoutEndKey)
    }
    
    /// Check if account is currently locked out
    static func isLockedOut() -> Bool {
        guard let data = load(key: lockoutEndKey),
              let timestamp = Double(data) else {
            return false
        }
        
        let lockoutEnd = Date(timeIntervalSince1970: timestamp)
        if Date() < lockoutEnd {
            return true
        } else {
            // Lockout expired, reset
            resetFailedAttempts()
            return false
        }
    }
    
    /// Get remaining lockout time in seconds
    static func remainingLockoutTime() -> TimeInterval {
        guard let data = load(key: lockoutEndKey),
              let timestamp = Double(data) else {
            return 0
        }
        
        let lockoutEnd = Date(timeIntervalSince1970: timestamp)
        return max(0, lockoutEnd.timeIntervalSinceNow)
    }
    
    // MARK: - Session Timeout
    
    /// Update the last active timestamp
    static func updateLastActiveTime() {
        _ = save(key: lastActiveKey, data: String(Date().timeIntervalSince1970))
    }
    
    /// Check if session has timed out
    static func hasSessionTimedOut() -> Bool {
        guard let data = load(key: lastActiveKey),
              let timestamp = Double(data) else {
            return true // No record = treat as timed out
        }
        
        let lastActive = Date(timeIntervalSince1970: timestamp)
        return Date().timeIntervalSince(lastActive) > sessionTimeout
    }
    
    // MARK: - Private Helpers
    
    /// Generate a random 32-byte salt
    private static func generateSalt() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
    }
    
    /// Hash password with salt using SHA-256
    private static func hashPassword(_ password: String, salt: String) -> String {
        let combined = salt + password + salt
        let inputData = Data(combined.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - Keychain CRUD Operations
    
    @discardableResult
    private static func save(key: String, data: String) -> Bool {
        guard let data = data.data(using: .utf8) else { return false }
        
        // Delete existing item first
        delete(key: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    private static func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return string
    }
    
    @discardableResult
    private static func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
