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
            // Background overlay
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }
            
            // Main modal content
            VStack(spacing: 0) {
                // Modal container
                VStack(spacing: 16) {
                    // Close button (top right)
                    HStack {
                        Spacer()
                        Button(action: { isPresented = false }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 16)
                        .padding(.trailing, 16)
                    }
                    
                    // Branding section
                    VStack(spacing: 4) {
                        Text("SpenWise")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text(isLoginMode ? "Sign In" : "Register")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 16)
                    
                    // Form content
                    VStack(spacing: 24) {
                        // Input fields
                        VStack(spacing: 12) {
                            // Email field
                            TextField("Email", text: $email)
                                .textFieldStyle(CustomTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                            
                            // Password field
                            SecureField("Password", text: $password)
                                .textFieldStyle(CustomTextFieldStyle())
                            
                            // Confirm password (only in register mode)
                            if !isLoginMode {
                                SecureField("Confirm Password", text: $confirmPassword)
                                    .textFieldStyle(CustomTextFieldStyle())
                            }
                            
                            // Error message
                            if let error = errorMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        
                        // Auth section
                        VStack(spacing: 16) {
                            // Mode switch
                            HStack(spacing: 4) {
                                Text(isLoginMode ? "Don't have an account?" : "Already have an account?")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Button(action: { 
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        isLoginMode.toggle()
                                        errorMessage = nil
                                        confirmPassword = ""
                                    }
                                }) {
                                    Text(isLoginMode ? "Create one" : "Sign In")
                                        .font(.caption)
                                        .foregroundColor(.accentColor)
                                }
                            }
                            
                            // Primary CTA button
                            Button(action: loginOrRegister) {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .foregroundColor(.white)
                                    }
                                    Text(isLoginMode ? "Sign In" : "Create Account")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                            }
                            .background(Color.accentColor)
                            .cornerRadius(8)
                            .disabled(isFormInvalid || isLoading)
                            .opacity(isFormInvalid || isLoading ? 0.6 : 1.0)
                        }
                        .padding(16)
                        .background(Color(.systemGray6).opacity(0.3))
                        .cornerRadius(12)
                        
                        // OR divider
                        HStack {
                            Rectangle().frame(height: 1).foregroundColor(Color(.systemGray4))
                            Text("OR").font(.system(size: 14, weight: .medium)).foregroundColor(.secondary).padding(.horizontal, 16)
                            Rectangle().frame(height: 1).foregroundColor(Color(.systemGray4))
                        }
                        
                        // Social login section
                        VStack(spacing: 10) {
                            // Apple Sign In
                            SignInWithAppleButton(.signIn) { request in
                                // Configure request if needed
                            } onCompletion: { result in
                                // Handle completion placeholder
                                handleSocialLogin("Apple")
                            }
                            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                            .frame(height: 44)
                            .cornerRadius(8)
                            
                            // Google Sign In
                            Button(action: { handleSocialLogin("Google") }) {
                                HStack {
                                    Image(systemName: "g.circle.fill").font(.system(size: 16))
                                    Text("Continue with Google").font(.system(size: 16, weight: .medium))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                            }
                            .buttonStyle(OutlineButtonStyle())
                            
                            // Facebook Sign In
                            Button(action: { handleSocialLogin("Facebook") }) {
                                HStack {
                                    Image(systemName: "f.circle.fill").font(.system(size: 16))
                                    Text("Continue with Facebook").font(.system(size: 16, weight: .medium))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                            }
                            .buttonStyle(OutlineButtonStyle())
                            
                            // Continue as Guest
                            Button(action: { isPresented = false }) {
                                Text("Continue as Guest").font(.system(size: 16, weight: .medium)).frame(maxWidth: .infinity).frame(height: 44)
                            }
                            .buttonStyle(OutlineButtonStyle())
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
            }
            .frame(maxWidth: 400)
            .padding(.horizontal, 16)
            .padding(.top, 64)
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
                let loggedEmail = try await SupabaseService.shared.signIn(email: email, password: password)
                await MainActor.run {
                    self.user = User(email: loggedEmail, isGuest: false)
                    self.isPresented = false
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Login failed. Please check your credentials."
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

// MARK: - Preview
struct LoginOrRegisterView_Previews: PreviewProvider {
    static var previews: some View {
        LoginOrRegisterView(user: .constant(nil), isPresented: .constant(true))
            .preferredColorScheme(.light)
        LoginOrRegisterView(user: .constant(nil), isPresented: .constant(true))
            .preferredColorScheme(.dark)
    }
}
