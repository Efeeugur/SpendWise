import SwiftUI
import AuthenticationServices

struct LoginOrRegisterView: View {
    @Binding var user: User?
    @Binding var isPresented: Bool
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var isLoginMode: Bool = true
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Enhanced background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }
            
            // Main modal content with improved scrolling
            ScrollView {
                VStack(spacing: 0) {
                    // Modal container
                    VStack(spacing: 20) {
                        // Close button (top right)
                        HStack {
                            Spacer()
                            Button(action: { isPresented = false }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.secondary)
                                    .background(Color(.systemBackground))
                                    .clipShape(Circle())
                            }
                            .padding(.top, 20)
                            .padding(.trailing, 20)
                        }
                        
                        // Enhanced branding section aligned with SpendWise Green UI Theme
                        VStack(spacing: 16) {
                            // App Logo
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.green, Color.teal],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                    .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
                                
                                Image(systemName: "dollarsign.circle.fill")
                                    .font(.system(size: 44, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(spacing: 6) {
                                Text("SpendWise".localized)
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.green, Color.teal],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                
                                Text(isLoginMode ? "Welcome Back".localized : "Create Account".localized)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                Text(isLoginMode ? "Sign in to your account".localized : "Join SpendWise today".localized)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 10)
                        
                        // Form content
                        VStack(spacing: 24) {
                            // Input fields
                            VStack(spacing: 16) {
                                // Email field with icon
                                HStack {
                                    Image(systemName: "envelope.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.green)
                                        .frame(width: 24)
                                    
                                    TextField("Email".localized, text: $email)
                                        .keyboardType(.emailAddress)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled(true)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(email.isEmpty ? Color.primary.opacity(0.15) : Color.green, lineWidth: 1.2)
                                )
                                
                                // Password field with icon
                                HStack {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.green)
                                        .frame(width: 24)
                                    
                                    SecureField("Password".localized, text: $password)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(password.isEmpty ? Color.primary.opacity(0.15) : Color.green, lineWidth: 1.2)
                                )
                                
                                // Confirm password (only in register mode)
                                if !isLoginMode {
                                    HStack {
                                        Image(systemName: "lock.shield.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(.green)
                                            .frame(width: 24)
                                        
                                        SecureField("Confirm Password".localized, text: $confirmPassword)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(Color(UIColor.secondarySystemGroupedBackground))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(confirmPassword.isEmpty ? Color.primary.opacity(0.15) : Color.green, lineWidth: 1.2)
                                    )
                                    .transition(.opacity.combined(with: .slide))
                                }
                                
                                // Error message banner
                                if let error = errorMessage {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.red)
                                        Text(error)
                                            .font(.footnote)
                                            .foregroundColor(.red)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        
                            // Auth CTA section
                            VStack(spacing: 16) {
                                // Mode switch
                                HStack(spacing: 6) {
                                    Text(isLoginMode ? "Don't have an account?".localized : "Already have an account?".localized)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Button(action: { 
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            isLoginMode.toggle()
                                            errorMessage = nil
                                            confirmPassword = ""
                                        }
                                    }) {
                                        Text(isLoginMode ? "Create one".localized : "Sign In".localized)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.green)
                                    }
                                }
                                
                                // Primary CTA button
                                Button(action: loginOrRegister) {
                                    HStack(spacing: 12) {
                                        if isLoading {
                                            ProgressView()
                                                .scaleEffect(0.9)
                                                .tint(.white)
                                        }
                                        
                                        Text(isLoginMode ? "Sign In".localized : "Create Account".localized)
                                            .font(.system(size: 17, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                }
                                .background(
                                    LinearGradient(
                                        colors: [Color.green, Color.teal],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                                .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                                .disabled(isFormInvalid || isLoading)
                                .opacity(isFormInvalid || isLoading ? 0.6 : 1.0)
                                .scaleEffect((isFormInvalid || isLoading) ? 0.98 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: isFormInvalid || isLoading)
                            }
                        
                            // OR divider
                            HStack {
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(Color(.systemGray3))
                                Text("OR".localized)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 16)
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(Color(.systemGray3))
                            }
                        
                            // Social OAuth login section (Apple, Google, Facebook)
                            VStack(spacing: 10) {
                                // Apple Sign In
                                SignInWithAppleButton(.signIn) { request in
                                    request.requestedScopes = [.fullName, .email]
                                } onCompletion: { result in
                                    handleAppleSignIn(result: result)
                                }
                                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                                .frame(height: 48)
                                .cornerRadius(12)
                                
                                // Google Sign In
                                Button(action: { handleOAuthSignIn(provider: "google") }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "g.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.red)
                                        Text("Continue with Google".localized)
                                            .font(.system(size: 15, weight: .semibold))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                }
                                .buttonStyle(EnhancedOutlineButtonStyle())
                                
                                // Facebook Sign In
                                Button(action: { handleOAuthSignIn(provider: "facebook") }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "f.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(Color(red: 24/255, green: 119/255, blue: 242/255))
                                        Text("Continue with Facebook".localized)
                                            .font(.system(size: 15, weight: .semibold))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                }
                                .buttonStyle(EnhancedOutlineButtonStyle())
                                
                                // Continue as Guest
                                Button(action: { isPresented = false }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "person.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.orange)
                                        Text("Continue as Guest".localized)
                                            .font(.system(size: 15, weight: .semibold))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                }
                                .buttonStyle(EnhancedOutlineButtonStyle())
                            }
                        }
                        .padding(.horizontal, 28)
                        .padding(.bottom, 32)
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.1), radius: 25, x: 0, y: 15)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 40)
            }
            .frame(maxWidth: 420)
        }
    }
    
    // MARK: - Computed Properties
    private var isFormInvalid: Bool {
        email.isEmpty || password.isEmpty || (!isLoginMode && confirmPassword.isEmpty)
    }
    
    // MARK: - Methods
    private func loginOrRegister() {
        errorMessage = nil
        if !isLoginMode && password != confirmPassword { errorMessage = "Passwords do not match.".localized; return }
        isLoading = true
        Task {
            do {
                let loggedEmail: String
                if isLoginMode {
                    loggedEmail = try await SupabaseService.shared.signIn(email: email, password: password)
                } else {
                    loggedEmail = try await SupabaseService.shared.signUp(email: email, password: password, name: email.components(separatedBy: "@").first ?? "User")
                }
                await MainActor.run {
                    let userName = loggedEmail.components(separatedBy: "@").first?.capitalized ?? "User"
                    let newUser = User(email: loggedEmail, name: userName, isGuest: false)
                    self.user = newUser
                    UserDefaultsManager.saveUser(newUser)
                    UserDefaultsManager.saveRegistrationDateIfNeeded()
                    
                    NotificationCenter.default.post(name: .userDidLogin, object: nil)
                    
                    self.isPresented = false
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = isLoginMode ? "Login failed. Please check your credentials.".localized : "Registration failed. Please try again.".localized
                    self.isLoading = false
                }
            }
        }
    }
    
    private func handleOAuthSignIn(provider: String) {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let (loggedEmail, userName) = try await SupabaseService.shared.signInWithOAuth(provider: provider)
                await MainActor.run {
                    let newUser = User(email: loggedEmail, name: userName, isGuest: false)
                    self.user = newUser
                    UserDefaultsManager.saveUser(newUser)
                    UserDefaultsManager.saveRegistrationDateIfNeeded()
                    
                    NotificationCenter.default.post(name: .userDidLogin, object: nil)
                    self.isPresented = false
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "\(provider.capitalized) Sign-In: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let appleUserId = credential.user
                let email = credential.email ?? "\(appleUserId.prefix(8))@apple.id"
                let fullName = [credential.fullName?.givenName, credential.fullName?.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")
                let displayName = fullName.isEmpty ? email.components(separatedBy: "@").first?.capitalized ?? "User" : fullName
                
                let newUser = User(email: email, name: displayName, isGuest: false)
                self.user = newUser
                UserDefaultsManager.saveUser(newUser)
                UserDefaultsManager.saveRegistrationDateIfNeeded()
                
                NotificationCenter.default.post(name: .userDidLogin, object: nil)
                self.isPresented = false
            }
        case .failure(let error):
            errorMessage = "Apple Sign-In failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Custom Styles
struct EnhancedOutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.primary)
            .background(Color(.systemBackground))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.15), lineWidth: 1.2))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview
struct LoginOrRegisterView_Previews: PreviewProvider {
    static var previews: some View {
        LoginOrRegisterView(user: .constant(nil), isPresented: .constant(true))
            .preferredColorScheme(.light)
        LoginOrRegisterView(user: .constant(nil), isPresented: .constant(true))
            .preferredColorScheme(.dark)
    }
}
