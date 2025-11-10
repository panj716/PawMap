import SwiftUI
import AuthenticationServices

struct AuthenticationView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isSignUpMode = false
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text(isSignUpMode ? "Create Account" : "Welcome Back")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(isSignUpMode ? "Join the PawMap community" : "Sign in to your account")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Email/Password Form
                VStack(spacing: 16) {
                    if isSignUpMode {
                        TextField("Full Name", text: $name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.words)
                    }
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal, 30)
                
                // Error Message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal, 30)
                }
                
                // Sign In/Up Button
                Button(action: handleEmailAuth) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: isSignUpMode ? "person.badge.plus" : "person.fill")
                        }
                        
                        Text(isSignUpMode ? "Create Account" : "Sign In")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
                }
                .disabled(isLoading || email.isEmpty || password.isEmpty || (isSignUpMode && name.isEmpty))
                .padding(.horizontal, 30)
                
                // Apple Sign In
                SignInWithAppleButton(
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        handleAppleSignIn(result: result)
                    }
                )
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .cornerRadius(12)
                .padding(.horizontal, 30)
                
                // Toggle Sign Up/Sign In
                Button(action: {
                    isSignUpMode.toggle()
                    errorMessage = nil
                }) {
                    Text(isSignUpMode ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func handleEmailAuth() {
        isLoading = true
        errorMessage = nil
        
        if isSignUpMode {
            authViewModel.signUp(email: email, password: password, name: name)
            // Handle success/failure through published properties
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.isLoading = false
                if self.authViewModel.isAuthenticated {
                    self.dismiss()
                } else if let error = self.authViewModel.errorMessage {
                    self.errorMessage = error
                }
            }
        } else {
            authViewModel.signIn(email: email, password: password)
            // Handle success/failure through published properties
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.isLoading = false
                if self.authViewModel.isAuthenticated {
                    self.dismiss()
                } else if let error = self.authViewModel.errorMessage {
                    self.errorMessage = error
                }
            }
        }
    }
    
    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            authViewModel.signInWithApple()
            // Handle success/failure through published properties
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if self.authViewModel.isAuthenticated {
                    self.dismiss()
                } else if let error = self.authViewModel.errorMessage {
                    self.errorMessage = error
                }
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthViewModel())
}
