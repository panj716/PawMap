import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var name = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.pink)
                    
                    Text("Join PawMap")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Create your account to start discovering dog-friendly places")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Form
                VStack(spacing: 16) {
                    // Name Field
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Full Name")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Enter your full name", text: $name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.words)
                    }
                    
                    // Email Field
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Email")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Enter your email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Password")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        SecureField("Enter your password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Confirm Password Field
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Confirm Password")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        SecureField("Confirm your password", text: $confirmPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                .padding(.horizontal, 20)
                
                // Sign Up Button
                Button(action: signUp) {
                    HStack {
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "person.badge.plus")
                        }
                        
                        Text("Create Account")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.pink, Color.pink.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(authViewModel.isLoading || !isFormValid)
                .opacity(isFormValid ? 1.0 : 0.6)
                .padding(.horizontal, 20)
                
                // Error Message
                if let errorMessage = authViewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // Sign In Link
                HStack {
                    Text("Already have an account?")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Sign In") {
                        authViewModel.showLogin()
                    }
                    .font(.caption)
                    .foregroundColor(.pink)
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Sign Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Sign Up", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var isFormValid: Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !password.isEmpty &&
               password == confirmPassword &&
               password.count >= 6 &&
               authViewModel.validateEmail(email)
    }
    
    private func signUp() {
        guard isFormValid else {
            alertMessage = "Please fill in all fields correctly"
            showingAlert = true
            return
        }
        
        authViewModel.signUp(email: email, password: password, name: name)
    }
}

#Preview {
    SignUpView()
        .environmentObject(AuthViewModel())
}

