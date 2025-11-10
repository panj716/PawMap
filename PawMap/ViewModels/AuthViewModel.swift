import Foundation
import Combine
import AuthenticationServices

/// ViewModel for handling authentication state and user management
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: PawMapUser?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingLogin = false
    @Published var showingSignUp = false
    
    private let authService = AuthService.shared
    private let firebaseService = FirebaseService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupAuthStateListener()
    }
    
    // MARK: - Setup
    
    private func setupAuthStateListener() {
        authService.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuthenticated in
                self?.isAuthenticated = isAuthenticated
                if isAuthenticated {
                    self?.loadCurrentUser()
                } else {
                    self?.currentUser = nil
                }
            }
            .store(in: &cancellables)
        
        authService.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)
        
        authService.$errorMessage
            .receive(on: DispatchQueue.main)
            .assign(to: \.errorMessage, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Authentication Actions
    
    func signUp(email: String, password: String, name: String) {
        authService.signUp(email: email, password: password, name: name)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.showingSignUp = false
                    self?.showingLogin = false
                }
            )
            .store(in: &cancellables)
    }
    
    func signIn(email: String, password: String) {
        authService.signIn(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.showingLogin = false
                }
            )
            .store(in: &cancellables)
    }
    
    func signInWithApple() {
        authService.signInWithApple()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.showingLogin = false
                }
            )
            .store(in: &cancellables)
    }
    
    func signInWithGoogle() {
        authService.signInWithGoogle()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.showingLogin = false
                }
            )
            .store(in: &cancellables)
    }
    
    func signOut() {
        authService.signOut()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.currentUser = nil
                }
            )
            .store(in: &cancellables)
    }
    
    func resetPassword(email: String) {
        authService.resetPassword(email: email)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] _ in
                    // Show success message
                    self?.errorMessage = "Password reset email sent"
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Favorites Management
    
    func isFavorite(placeId: String) -> Bool {
        return currentUser?.favoritePlaceIDs.contains(placeId) ?? false
    }
    
    func toggleFavorite(placeId: String) {
        guard let user = currentUser else { return }
        
        let updatedFavoritePlaceIDs: [String]
        if user.favoritePlaceIDs.contains(placeId) {
            updatedFavoritePlaceIDs = user.favoritePlaceIDs.filter { $0 != placeId }
        } else {
            updatedFavoritePlaceIDs = user.favoritePlaceIDs + [placeId]
        }
        
        let updatedUser = PawMapUser(
            id: user.id,
            email: user.email,
            name: user.name,
            profileImageUrl: user.profileImageUrl,
            dogName: user.dogName,
            dogBreed: user.dogBreed,
            dogBirthday: user.dogBirthday,
            dogWeight: user.dogWeight,
            dogGender: user.dogGender,
            dogTraits: user.dogTraits,
            dogNotes: user.dogNotes,
            favoritePlaceIDs: updatedFavoritePlaceIDs,
            createdAt: user.createdAt,
            lastActiveAt: Date()
        )
        
        updateUserProfile(updatedUser)
    }
    
    // MARK: - User Profile Management
    
    private func loadCurrentUser() {
        guard isAuthenticated else { return }
        
        authService.getCurrentUserProfile()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] user in
                    self?.currentUser = user
                }
            )
            .store(in: &cancellables)
    }
    
    func updateUserProfile(_ profile: PawMapUser) {
        authService.updateUserProfile(profile)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.currentUser = profile
                }
            )
            .store(in: &cancellables)
    }
    
    func updateProfile(_ profile: PawMapUser) {
        updateUserProfile(profile)
    }
    
    func updateProfileImage(_ imageUrl: String) {
        guard let user = currentUser else { return }
        
        let updatedUser = user.updatingProfileImage(imageUrl)
        updateUserProfile(updatedUser)
    }
    
    func updateDogProfile(name: String? = nil, breed: String? = nil, birthday: Date? = nil, weight: Double? = nil, gender: String? = nil, traits: [String]? = nil, notes: String? = nil) {
        guard let user = currentUser else { return }
        
        let updatedUser = user.updatingDogProfile(
            name: name,
            breed: breed,
            birthday: birthday,
            weight: weight,
            gender: gender,
            traits: traits,
            notes: notes
        )
        updateUserProfile(updatedUser)
    }
    
    // MARK: - UI State Management
    
    func showLogin() {
        showingLogin = true
        showingSignUp = false
    }
    
    func showSignUp() {
        showingSignUp = true
        showingLogin = false
    }
    
    func hideAuthSheets() {
        showingLogin = false
        showingSignUp = false
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Validation
    
    func validateEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    func validatePassword(_ password: String) -> Bool {
        return password.count >= 6
    }
    
    func validateName(_ name: String) -> Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - User Statistics
    
    func getUserStats() -> AnyPublisher<UserStats, Error> {
        guard let userId = currentUser?.id else {
            return Fail(error: FirebaseError.authenticationRequired)
                .eraseToAnyPublisher()
        }
        
        return firebaseService.readDocument(UserStats.self, from: "userStats", withId: userId)
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    
    // MARK: - User Preferences
    
    func getUserPreferences() -> AnyPublisher<UserPreferences, Error> {
        guard let userId = currentUser?.id else {
            return Fail(error: FirebaseError.authenticationRequired)
                .eraseToAnyPublisher()
        }
        
        return firebaseService.readDocument(UserPreferences.self, from: "userPreferences", withId: userId)
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    
    func updateUserPreferences(_ preferences: UserPreferences) -> AnyPublisher<Void, Error> {
        guard let userId = currentUser?.id else {
            return Fail(error: FirebaseError.authenticationRequired)
                .eraseToAnyPublisher()
        }
        
        return firebaseService.updateDocument(preferences, in: "userPreferences", withId: userId)
    }
}

// MARK: - Supporting Types

enum AuthError: LocalizedError {
    case invalidEmail
    case weakPassword
    case userNotFound
    case wrongPassword
    case emailAlreadyInUse
    case networkError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address"
        case .weakPassword:
            return "Password must be at least 6 characters long"
        case .userNotFound:
            return "No account found with this email"
        case .wrongPassword:
            return "Incorrect password"
        case .emailAlreadyInUse:
            return "An account already exists with this email"
        case .networkError:
            return "Network error. Please check your connection"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
