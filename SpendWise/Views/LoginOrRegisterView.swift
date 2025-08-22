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
                        
                        // Enhanced branding section with logo
                        VStack(spacing: 16) {
                            // App Logo
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.blue, Color.purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                    .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                                
                                Image(systemName: "creditcard.and.123")
                                    .font(.system(size: 36, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(spacing: 6) {
                                Text("SpendWise")
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.blue, Color.purple],
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
                        
                        // Form content with better spacing
                        VStack(spacing: 28) {
                            // Enhanced input fields
                            VStack(spacing: 16) {
                                // Email field with icon
                                HStack {
                                    Image(systemName: "envelope")
                                        .font(.system(size: 18))
                                        .foregroundColor(.blue)
                                        .frame(width: 24)
                                    
                                    TextField("Email".localized, text: $email)
                                        .keyboardType(.emailAddress)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled(true)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(email.isEmpty ? Color(.systemGray4) : Color.blue, lineWidth: 1)
                                )
                                
                                // Password field with icon
                                HStack {
                                    Image(systemName: "lock")
                                        .font(.system(size: 18))
                                        .foregroundColor(.blue)
                                        .frame(width: 24)
                                    
                                    SecureField("Password".localized, text: $password)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(password.isEmpty ? Color(.systemGray4) : Color.blue, lineWidth: 1)
                                )
                                
                                // Confirm password (only in register mode) with icon
                                if !isLoginMode {
                                    HStack {
                                        Image(systemName: "lock.shield")
                                            .font(.system(size: 18))
                                            .foregroundColor(.blue)
                                            .frame(width: 24)
                                        
                                        SecureField("Confirm Password".localized, text: $confirmPassword)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(confirmPassword.isEmpty ? Color(.systemGray4) : Color.blue, lineWidth: 1)
                                    )
                                    .transition(.opacity.combined(with: .slide))
                                }
                                
                                // Enhanced error message
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
                        
                            // Enhanced auth section
                            VStack(spacing: 20) {
                                // Mode switch with better styling
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
                                            .foregroundColor(.blue)
                                    }
                                }
                                
                                // Enhanced primary CTA button
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
                                    .frame(height: 52)
                                }
                                .background(
                                    LinearGradient(
                                        colors: [Color.blue, Color.blue.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                                .disabled(isFormInvalid || isLoading)
                                .opacity(isFormInvalid || isLoading ? 0.6 : 1.0)
                                .scaleEffect((isFormInvalid || isLoading) ? 0.98 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: isFormInvalid || isLoading)
                            }
                        
                            // Enhanced OR divider
                            HStack {
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(Color(.systemGray3))
                                Text("OR".localized)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 20)
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(Color(.systemGray3))
                            }
                        
                            // Enhanced social login section
                            VStack(spacing: 12) {
                                // Apple Sign In with enhanced styling
                                SignInWithAppleButton(.signIn) { request in
                                    // Configure request if needed
                                } onCompletion: { result in
                                    // Handle completion placeholder
                                    handleSocialLogin("Apple")
                                }
                                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                                .frame(height: 50)
                                .cornerRadius(12)
                                
                                // Enhanced Google Sign In
                                Button(action: { handleSocialLogin("Google") }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "globe")
                                            .font(.system(size: 18))
                                            .foregroundColor(.red)
                                        Text("Continue with Google".localized)
                                            .font(.system(size: 16, weight: .medium))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                }
                                .buttonStyle(EnhancedOutlineButtonStyle())
                                
                                // Enhanced Continue as Guest
                                Button(action: { isPresented = false }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "person")
                                            .font(.system(size: 18))
                                            .foregroundColor(.orange)
                                        Text("Continue as Guest".localized)
                                            .font(.system(size: 16, weight: .medium))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
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
        // Validate password match in register mode
        if !isLoginMode && password != confirmPassword { errorMessage = "Passwords do not match."; return }
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
                    
                    // Post notification that user logged in
                    NotificationCenter.default.post(name: .userDidLogin, object: nil)
                    
                    self.isPresented = false
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = isLoginMode ? "Login failed. Please check your credentials." : "Registration failed. Please try again."
                    self.isLoading = false
                }
            }
        }
    }
    
    private func handleSocialLogin(_ provider: String) { errorMessage = "\(provider) Sign-In not yet configured" }
}

// MARK: - Custom Styles
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.systemGray4), lineWidth: 1))
    }
}

struct OutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.primary)
            .background(Color(.systemBackground))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.systemGray4), lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct EnhancedOutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.primary)
            .background(Color(.systemBackground))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.systemGray3), lineWidth: 1.5))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
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
