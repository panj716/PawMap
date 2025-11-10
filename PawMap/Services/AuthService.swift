import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine
import AuthenticationServices
import CryptoKit

/// Service for handling user authentication with Firebase Auth
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let firebaseService = FirebaseService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Listen to authentication state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.isAuthenticated = user != nil
                self?.currentUser = user
            }
        }
    }
    
    // MARK: - Email/Password Authentication
    
    /// Sign up with email and password
    func signUp(email: String, password: String, name: String) -> AnyPublisher<Void, Error> {
        isLoading = true
        errorMessage = nil
        
        return Future { [weak self] promise in
            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        promise(.failure(error))
                        return
                    }
                    
                    guard let user = result?.user else {
                        let error = NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create user"])
                        promise(.failure(error))
                        return
                    }
                    
                    // Create user profile in Firestore
                    let userProfile = PawMapUser(
                        id: user.uid,
                        email: email,
                        name: name,
                        profileImageUrl: nil,
                        dogName: nil,
                        dogBreed: nil,
                        dogBirthday: nil,
                        dogWeight: nil,
                        dogGender: nil,
                        dogTraits: [],
                        dogNotes: nil,
                        favoritePlaceIDs: [],
                        createdAt: Date(),
                        lastActiveAt: Date()
                    )
                    
                    let cancellable = self?.firebaseService.createDocument(userProfile, in: "users", withId: user.uid)
                        .sink(
                            receiveCompletion: { completion in
                                if case .failure(let error) = completion {
                                    promise(.failure(error))
                                }
                            },
                            receiveValue: { documentId in
                                print("✅ User profile created in Firestore with ID: \(documentId)")
                                promise(.success(()))
                            }
                        )
                    self?.cancellables.insert(cancellable!)
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Sign in with email and password
    func signIn(email: String, password: String) -> AnyPublisher<Void, Error> {
        isLoading = true
        errorMessage = nil
        
        return Future { [weak self] promise in
            Auth.auth().signIn(withEmail: email, password: password) { result, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        promise(.failure(error))
                        return
                    }
                    
                    // Update last active timestamp
                    if let user = result?.user {
                        self?.updateLastActive(for: user.uid)
                    }
                    
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Apple Sign In
    
    /// Sign in with Apple
    func signInWithApple() -> AnyPublisher<Void, Error> {
        isLoading = true
        errorMessage = nil
        
        return Future { [weak self] promise in
            let nonce = self?.randomNonceString() ?? ""
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = self?.sha256(nonce)
            
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = AppleSignInDelegate { result in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    switch result {
                    case .success(let user):
                        promise(.success(()))
                    case .failure(let error):
                        self?.errorMessage = error.localizedDescription
                        promise(.failure(error))
                    }
                }
            }
            authorizationController.performRequests()
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Google Sign In
    
    /// Sign in with Google
    func signInWithGoogle() -> AnyPublisher<Void, Error> {
        isLoading = true
        errorMessage = nil
        
        return Future { [weak self] promise in
            // Implementation would depend on Google Sign-In SDK
            // This is a placeholder for the actual implementation
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self?.isLoading = false
                // Simulate Google sign in
                promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Sign Out
    
    /// Sign out current user
    func signOut() -> AnyPublisher<Void, Error> {
        return Future { promise in
            do {
                try Auth.auth().signOut()
                DispatchQueue.main.async {
                    self.isAuthenticated = false
                    self.currentUser = nil
                }
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Password Reset
    
    /// Send password reset email
    func resetPassword(email: String) -> AnyPublisher<Void, Error> {
        return Future { promise in
            Auth.auth().sendPasswordReset(withEmail: email) { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - User Profile Management
    
    /// Get current user profile from Firestore
    func getCurrentUserProfile() -> AnyPublisher<PawMapUser?, Error> {
        guard let userId = currentUser?.uid else {
            return Just(nil)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        return firebaseService.readDocument(PawMapUser.self, from: "users", withId: userId)
    }
    
    /// Update user profile
    func updateUserProfile(_ profile: PawMapUser) -> AnyPublisher<Void, Error> {
        guard let userId = currentUser?.uid else {
            return Fail(error: FirebaseError.authenticationRequired)
                .eraseToAnyPublisher()
        }
        
        return firebaseService.updateDocument(profile, in: "users", withId: userId)
    }
    
    /// Update last active timestamp
    private func updateLastActive(for userId: String) {
        let updateData = ["lastActiveAt": Timestamp(date: Date())]
        firebaseService.db.collection("users").document(userId).updateData(updateData)
    }
    
    // MARK: - Helper Methods
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}

// MARK: - Apple Sign In Delegate

class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate {
    private let completion: (Result<Void, Error>) -> Void
    
    init(completion: @escaping (Result<Void, Error>) -> Void) {
        self.completion = completion
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
            
            let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                         rawNonce: nil,
                                                         fullName: appleIDCredential.fullName)
            
            Auth.auth().signIn(with: credential) { (authResult, error) in
                if let error = error {
                    self.completion(.failure(error))
                    return
                }
                
                // Create user profile if it's a new user
                if let user = authResult?.user {
                    let userProfile = PawMapUser(
                        id: user.uid,
                        email: user.email ?? "",
                        name: "\(appleIDCredential.fullName?.givenName ?? "") \(appleIDCredential.fullName?.familyName ?? "")".trimmingCharacters(in: .whitespaces),
                        profileImageUrl: nil,
                        dogName: nil,
                        dogBreed: nil,
                        dogBirthday: nil,
                        dogWeight: nil,
                        dogGender: nil,
                        dogTraits: [],
                        dogNotes: nil,
                        favoritePlaceIDs: [],
                        createdAt: Date(),
                        lastActiveAt: Date()
                    )
                    
                    FirebaseService.shared.createDocument(userProfile, in: "users", withId: user.uid)
                        .sink(
                            receiveCompletion: { _ in },
                            receiveValue: { _ in }
                        )
                        .store(in: &self.cancellables)
                }
                
                self.completion(.success(()))
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completion(.failure(error))
    }
    
    private var currentNonce: String?
    private var cancellables = Set<AnyCancellable>()
}

