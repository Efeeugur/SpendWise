import SwiftUI

// MARK: - Password Setup View
struct PasswordSetupView: View {
    @Binding var password: String
    @Binding var confirmPassword: String
    @Binding var isPasswordVisible: Bool
    let onSave: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var errorMessage: String = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    VStack(spacing: 16) {
                        Text("Set Password").font(.largeTitle).fontWeight(.bold).foregroundColor(.primary)
                        Text("Create a secure password to protect your financial data").font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password").font(.subheadline).fontWeight(.medium).foregroundColor(.secondary)
                            HStack {
                                if isPasswordVisible {
                                    TextField("Enter password", text: $password)
                                        .font(.body)
                                } else {
                                    SecureField("Enter password", text: $password)
                                        .font(.body)
                                }
                                Button(action: { isPasswordVisible.toggle() }) { Image(systemName: isPasswordVisible ? "eye.slash" : "eye").foregroundColor(.secondary).font(.body) }
                            }
                            .padding().background(Color(.systemGray6)).cornerRadius(12)
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password").font(.subheadline).fontWeight(.medium).foregroundColor(.secondary)
                            if isPasswordVisible {
                                TextField("Re-enter password", text: $confirmPassword)
                                    .font(.body)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                            } else {
                                SecureField("Re-enter password", text: $confirmPassword)
                                    .font(.body)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                            }
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Requirements:").font(.caption).fontWeight(.medium).foregroundColor(.secondary)
                            HStack { Image(systemName: password.count >= 4 ? "checkmark.circle.fill" : "circle").foregroundColor(password.count >= 4 ? .green : .secondary).font(.caption); Text("At least 4 characters").font(.caption).foregroundColor(.secondary); Spacer() }
                            HStack { Image(systemName: (!password.isEmpty && !confirmPassword.isEmpty && password == confirmPassword) ? "checkmark.circle.fill" : "circle").foregroundColor((!password.isEmpty && !confirmPassword.isEmpty && password == confirmPassword) ? .green : .secondary).font(.caption); Text("Passwords match").font(.caption).foregroundColor(.secondary); Spacer() }
                        }
                        .padding(.top, 8)
                        if !errorMessage.isEmpty { Text(errorMessage).font(.caption).foregroundColor(.red).padding(.horizontal) }
                    }
                    .padding(.horizontal, 24)
                    Spacer()
                    VStack(spacing: 16) {
                        Button(action: handleSave) { Text("Save Password").font(.headline).fontWeight(.semibold).foregroundColor(.white).frame(maxWidth: .infinity).padding().background(LinearGradient(colors: [.blue, .blue.opacity(0.8)], startPoint: .leading, endPoint: .trailing)).cornerRadius(12) }
                        .disabled(!isFormValid).opacity(isFormValid ? 1.0 : 0.6)
                        Button("Cancel") { dismiss() }.font(.body).foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 24).padding(.bottom, 40)
                }
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
        }
    }
    
    private var isFormValid: Bool { password.count >= 4 && password == confirmPassword }
    
    private func handleSave() {
        errorMessage = ""
        guard password.count >= 4 else { errorMessage = "Password must be at least 4 characters."; return }
        guard password == confirmPassword else { errorMessage = "Passwords do not match."; return }
        onSave()
    }
}

// MARK: - Main Security View
struct SecurityView: View {
    @StateObject private var securityManager = SecurityManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var selectedSecurityType: SecurityType = UserDefaultsManager.loadSecurityType()
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showPasswordSetup = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isPasswordVisible = false
    @State private var hasPassword = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    VStack(spacing: 8) {
                        Text("Security").font(.largeTitle).fontWeight(.bold).foregroundColor(.primary)
                        Text("Protect your financial data with advanced security options").font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Security Type Selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text("SECURITY TYPE").font(.caption).fontWeight(.medium).foregroundColor(.secondary).padding(.horizontal, 20)
                        VStack(spacing: 0) {
                            ForEach(Array(SecurityType.allCases.enumerated()), id: \.element) { index, type in
                                SecurityTypeRow(type: type, isSelected: selectedSecurityType == type, onTap: { handleSecurityTypeChange(type) })
                                    .background(Color(.systemBackground))
                                if index < SecurityType.allCases.count - 1 { Divider().padding(.leading, 20) }
                            }
                        }
                        .background(Color(.systemBackground)).cornerRadius(12).shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                        Text(selectedSecurityType.description).font(.caption).foregroundColor(.secondary).padding(.horizontal, 20)
                    }
                    .padding(.horizontal, 20)
                    
                    // Password settings
                    if selectedSecurityType == .password || selectedSecurityType == .both {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("PASSWORD SETTINGS").font(.caption).fontWeight(.medium).foregroundColor(.secondary).padding(.horizontal, 20)
                            VStack(spacing: 0) {
                                if !hasPassword {
                                    Button(action: { showPasswordSetup = true }) { row(icon: "key.fill", text: "Set Password") }
                                } else {
                                    Button(action: { showPasswordSetup = true }) { row(icon: "key.fill", text: "Change Password") }
                                    Divider().padding(.leading, 20)
                                    Button(action: { removePassword() }) { row(icon: "trash.fill", text: "Remove Password", tint: .red) }
                                }
                            }
                            .background(Color(.systemBackground)).cornerRadius(12).shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Biometric
                    if selectedSecurityType == .biometric || selectedSecurityType == .both {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("BIOMETRIC AUTHENTICATION").font(.caption).fontWeight(.medium).foregroundColor(.secondary).padding(.horizontal, 20)
                            VStack(spacing: 16) {
                                HStack(spacing: 16) {
                                    Image(systemName: securityManager.biometricType == .faceID ? "faceid" : (securityManager.biometricType == .touchID ? "touchid" : "lock.shield")).font(.system(size: 40)).foregroundColor(.blue)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(securityManager.getBiometricTypeName()).font(.headline).foregroundColor(.primary)
                                        HStack {
                                            Image(systemName: securityManager.isBiometricAvailable ? "checkmark.circle.fill" : "xmark.circle.fill").foregroundColor(securityManager.isBiometricAvailable ? .green : .red).font(.caption)
                                            Text(securityManager.isBiometricAvailable ? "Available" : "Not Available").font(.caption).foregroundColor(securityManager.isBiometricAvailable ? .green : .red)
                                        }
                                    }
                                    Spacer()
                                }
                                if !securityManager.isBiometricAvailable { Text("Biometric authentication is not available on this device.").font(.caption).foregroundColor(.secondary) }
                            }
                            .padding(20).background(Color(.systemBackground)).cornerRadius(12).shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Test
                    VStack(alignment: .leading, spacing: 16) {
                        Text("SECURITY TEST").font(.caption).fontWeight(.medium).foregroundColor(.secondary).padding(.horizontal, 20)
                        Button(action: testAuthentication) { row(icon: "shield.checkered", text: "Test Authentication", tint: selectedSecurityType == .none ? .secondary : .blue) }
                            .disabled(selectedSecurityType == .none)
                            .background(Color(.systemBackground)).cornerRadius(12).shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2).opacity(selectedSecurityType == .none ? 0.6 : 1.0)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() }.font(.body).fontWeight(.medium) } }
        }
        .sheet(isPresented: $showPasswordSetup) { PasswordSetupView(password: $password, confirmPassword: $confirmPassword, isPasswordVisible: $isPasswordVisible, onSave: savePassword) }
        .alert("Security", isPresented: $showAlert) { Button("OK") { } } message: { Text(alertMessage) }
        .onAppear { hasPassword = UserDefaultsManager.loadSecurityPassword() != nil }
    }
    
    private func row(icon: String, text: String, tint: Color = .primary) -> some View {
        HStack {
            Image(systemName: icon).foregroundColor(tint == .primary ? .blue : tint).font(.body)
            Text(text).font(.body).foregroundColor(tint)
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(.secondary).font(.caption)
        }
        .padding(20)
    }
    
    private func handleSecurityTypeChange(_ newType: SecurityType) {
        switch newType {
        case .password, .both:
            if !hasPassword { showPasswordSetup = true; return }
            UserDefaultsManager.saveSecurityType(newType); selectedSecurityType = newType
        case .biometric:
            if !securityManager.isBiometricAvailable { alertMessage = "Biometric authentication is not available on this device."; showAlert = true; return }
            UserDefaultsManager.saveSecurityType(newType); selectedSecurityType = newType
        case .none:
            UserDefaultsManager.saveSecurityType(newType); selectedSecurityType = newType
        }
    }
    
    private func savePassword() {
        guard password.count >= 4 else { alertMessage = "Password must be at least 4 characters."; showAlert = true; return }
        guard password == confirmPassword else { alertMessage = "Passwords do not match."; showAlert = true; return }
        UserDefaultsManager.saveSecurityPassword(password)
        UserDefaultsManager.saveSecurityType(selectedSecurityType)
        hasPassword = true
        password = ""; confirmPassword = ""; showPasswordSetup = false
        alertMessage = "Password successfully saved."; showAlert = true
    }
    
    private func removePassword() {
        UserDefaultsManager.clearSecurityPassword(); hasPassword = false
        if selectedSecurityType == .password { selectedSecurityType = .none; UserDefaultsManager.saveSecurityType(.none) }
        else if selectedSecurityType == .both { selectedSecurityType = .biometric; UserDefaultsManager.saveSecurityType(.biometric) }
        alertMessage = "Password removed successfully."; showAlert = true
    }
    
    private func testAuthentication() {
        switch selectedSecurityType {
        case .password: showPasswordSetup = true
        case .biometric:
            securityManager.authenticateWithBiometrics { success in
                alertMessage = success ? "Biometric authentication successful!" : "Biometric authentication failed."; showAlert = true
            }
        case .both:
            securityManager.authenticateWithBiometrics { success in
                if success { alertMessage = "Biometric authentication successful!"; showAlert = true } else { showPasswordSetup = true }
            }
        case .none: break
        }
    }
}

// MARK: - Security Type Row
struct SecurityTypeRow: View {
    let type: SecurityType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.rawValue).font(.body).fontWeight(.medium).foregroundColor(.primary)
                    Text(type.description).font(.caption).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                if isSelected { Image(systemName: "checkmark.circle.fill").foregroundColor(.blue).font(.body) }
            }
            .padding(20)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SecurityView_Previews: PreviewProvider {
    static var previews: some View { SecurityView() }
}
