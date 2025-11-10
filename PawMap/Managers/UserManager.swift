import Foundation
import CoreLocation
import MapKit
import Combine
import PhotosUI

class UserManager: ObservableObject {
    @Published var isLoggedIn = false
    @Published var currentUser: UserProfile?
    @Published var userFavorites: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let userDefaults = UserDefaults.standard
    private let favoritesKey = "userFavorites"
    private let userKey = "currentUser"
    private let loginKey = "isLoggedIn"
    private let usersKey = "registeredUsers" // Store all registered users
    
    init() {
        loadUserData()
    }
    
    func login(email: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        // Validate email format
        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address"
            isLoading = false
            return
        }
        
        // Validate password
        guard !password.isEmpty else {
            errorMessage = "Password cannot be empty"
            isLoading = false
            return
        }
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Check if user exists and password matches
            if let user = self.findUserByEmail(email), self.verifyPassword(password, for: user) {
                self.currentUser = user
                self.isLoggedIn = true
                self.saveUserData()
                self.isLoading = false
            } else {
                self.errorMessage = "Invalid email or password"
                self.isLoading = false
            }
        }
    }
    
    func signup(email: String, password: String, name: String) {
        isLoading = true
        errorMessage = nil
        
        // Validate inputs
        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address"
            isLoading = false
            return
        }
        
        guard !password.isEmpty && password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters long"
            isLoading = false
            return
        }
        
        guard !name.isEmpty else {
            errorMessage = "Name cannot be empty"
            isLoading = false
            return
        }
        
        // Check if user already exists
        if findUserByEmail(email) != nil {
            errorMessage = "An account with this email already exists"
            isLoading = false
            return
        }
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Create new user
            let newUser = UserProfile(
                id: UUID().uuidString,
                email: email,
                name: name,
                dogName: "",
                dogPhotoURL: nil,
                dogBirthday: nil,
                dogBreed: "",
                dogWeight: 0.0,
                dogGender: "",
                dogTraits: [],
                dogNotes: "",
                profileImageURL: nil,
                favoritePlaceIDs: [],
                createdAt: Date(),
                updatedAt: Date()
            )
            
            // Save user with hashed password
            self.saveUser(newUser, with: password)
            
            // Log in the new user
            self.currentUser = newUser
            self.isLoggedIn = true
            self.saveUserData()
            self.isLoading = false
        }
    }
    
    func loginWithGoogle() {
        // 模拟Google登录
        let user = UserProfile(
            id: UUID().uuidString,
            email: "user@gmail.com",
            name: "Google用户",
            dogName: "",
            dogPhotoURL: nil,
            dogBirthday: nil,
            dogBreed: "",
            dogWeight: 0.0,
            dogGender: "",
            dogTraits: [],
            dogNotes: "",
            profileImageURL: nil,
            favoritePlaceIDs: [],
            createdAt: Date(),
            updatedAt: Date()
        )
        
        currentUser = user
        isLoggedIn = true
        saveUserData()
    }
    
    func logout() {
        currentUser = nil
        isLoggedIn = false
        userFavorites.removeAll()
        saveUserData()
    }
    
    func updateProfile(name: String, dogBreed: String, dogName: String, dogBirthday: Date? = nil, dogWeight: Double = 0.0, dogGender: String = "", dogTraits: [String] = [], dogNotes: [String] = []) {
        guard let user = currentUser else { 
            print("❌ No current user found")
            return 
        }
        
        print("💾 Updating profile for user: \(user.name)")
        print("📝 New data - Name: \(name), Dog: \(dogName), Breed: \(dogBreed)")
        
        let updatedUser = UserProfile(
            id: user.id,
            email: user.email,
            name: name,
            dogName: dogName,
            dogPhotoURL: user.dogPhotoURL,
            dogBirthday: dogBirthday,
            dogBreed: dogBreed,
            dogWeight: dogWeight,
            dogGender: dogGender,
            dogTraits: dogTraits,
            dogNotes: dogNotes.joined(separator: ", "),
            profileImageURL: user.profileImageURL,
            favoritePlaceIDs: user.favoritePlaceIDs,
            createdAt: user.createdAt,
            updatedAt: Date()
        )
        
        currentUser = updatedUser
        
        // Update the user in the registered users list as well
        updateUserInRegisteredList(updatedUser)
        
        print("🔄 About to save user data...")
        saveUserData()
        print("✅ Profile updated successfully")
    }
    
    func updateDogPhoto(_ photoData: Data?) {
        guard let user = currentUser else { return }
        
        // Convert photo data to URL string (simplified for now)
        let photoURL = photoData != nil ? "dog_photo_\(user.id)" : user.dogPhotoURL
        
        let updatedUser = UserProfile(
            id: user.id,
            email: user.email,
            name: user.name,
            dogName: user.dogName,
            dogPhotoURL: photoURL,
            dogBirthday: user.dogBirthday,
            dogBreed: user.dogBreed,
            dogWeight: user.dogWeight,
            dogGender: user.dogGender,
            dogTraits: user.dogTraits,
            dogNotes: user.dogNotes,
            profileImageURL: user.profileImageURL,
            favoritePlaceIDs: user.favoritePlaceIDs,
            createdAt: user.createdAt,
            updatedAt: Date()
        )
        
        currentUser = updatedUser
        saveUserData()
    }
    
    func updateProfilePhoto(_ photoData: Data?) {
        guard let user = currentUser else { return }
        
        // Convert photo data to URL string (simplified for now)
        let photoURL = photoData != nil ? "profile_photo_\(user.id)" : user.profileImageURL
        
        let updatedUser = UserProfile(
            id: user.id,
            email: user.email,
            name: user.name,
            dogName: user.dogName,
            dogPhotoURL: user.dogPhotoURL,
            dogBirthday: user.dogBirthday,
            dogBreed: user.dogBreed,
            dogWeight: user.dogWeight,
            dogGender: user.dogGender,
            dogTraits: user.dogTraits,
            dogNotes: user.dogNotes,
            profileImageURL: photoURL,
            favoritePlaceIDs: user.favoritePlaceIDs,
            createdAt: user.createdAt,
            updatedAt: Date()
        )
        
        currentUser = updatedUser
        saveUserData()
    }
    
    func toggleFavorite(placeId: String) {
        if userFavorites.contains(placeId) {
            userFavorites.remove(placeId)
        } else {
            userFavorites.insert(placeId)
        }
        
        // 同步更新 currentUser 的 favoritePlaceIDs
        if var user = currentUser {
            var updatedFavoriteIDs = user.favoritePlaceIDs
            if updatedFavoriteIDs.contains(placeId) {
                updatedFavoriteIDs.removeAll { $0 == placeId }
            } else {
                updatedFavoriteIDs.append(placeId)
            }
            
            let updatedUser = UserProfile(
                id: user.id,
                email: user.email,
                name: user.name,
                dogName: user.dogName,
                dogPhotoURL: user.dogPhotoURL,
                dogBirthday: user.dogBirthday,
                dogBreed: user.dogBreed,
                dogWeight: user.dogWeight,
                dogGender: user.dogGender,
                dogTraits: user.dogTraits,
                dogNotes: user.dogNotes,
                profileImageURL: user.profileImageURL,
                favoritePlaceIDs: updatedFavoriteIDs,
                createdAt: user.createdAt,
                updatedAt: Date()
            )
            currentUser = updatedUser
        }
        
        saveUserData()
    }
    
    func isFavorite(placeId: String) -> Bool {
        // 检查 userFavorites Set
        if userFavorites.contains(placeId) {
            return true
        }
        
        // 同时检查 currentUser 的 favoritePlaceIDs（确保同步）
        if let user = currentUser, user.favoritePlaceIDs.contains(placeId) {
            // 如果 currentUser 有但 userFavorites 没有，同步它们
            if !userFavorites.contains(placeId) {
                userFavorites.insert(placeId)
            }
            return true
        }
        
        return false
    }
    
    private func saveUserData() {
        print("💾 Saving user data...")
        print("🔍 isLoggedIn: \(isLoggedIn)")
        userDefaults.set(isLoggedIn, forKey: loginKey)
        
        if let user = currentUser {
            print("👤 Saving user: \(user.name)")
            print("📊 User details - Name: '\(user.name)', Dog: '\(user.dogName)', Breed: '\(user.dogBreed)'")
            
            do {
                let userData = try JSONEncoder().encode(user)
                userDefaults.set(userData, forKey: userKey)
                print("✅ User data encoded and saved successfully")
                
                // Verify the save by reading it back
                if let savedData = userDefaults.data(forKey: userKey),
                   let savedUser = try? JSONDecoder().decode(UserProfile.self, from: savedData) {
                    print("✅ Verification successful - saved user: \(savedUser.name)")
                } else {
                    print("❌ Verification failed - could not read back saved data")
                }
            } catch {
                print("❌ Failed to encode user data: \(error)")
            }
        } else {
            print("❌ No current user to save")
        }
        
        let favoritesArray = Array(userFavorites)
        userDefaults.set(favoritesArray, forKey: favoritesKey)
        print("💾 User data save completed")
    }
    
    private func loadUserData() {
        isLoggedIn = userDefaults.bool(forKey: loginKey)
        print("🔄 Loading user data...")
        print("🔍 isLoggedIn from storage: \(isLoggedIn)")
        
        if let userData = userDefaults.data(forKey: userKey) {
            print("📦 Found user data in storage")
            do {
                let user = try JSONDecoder().decode(UserProfile.self, from: userData)
                currentUser = user
                print("✅ Successfully loaded user: \(user.name)")
                print("📊 Loaded user details - Name: '\(user.name)', Dog: '\(user.dogName)', Breed: '\(user.dogBreed)'")
                
                // 从 currentUser 的 favoritePlaceIDs 加载收藏
                userFavorites = Set(user.favoritePlaceIDs)
                print("✅ Loaded \(user.favoritePlaceIDs.count) favorites from user profile")
            } catch {
                print("❌ Failed to decode user data: \(error)")
            }
        } else {
            print("❌ No user data found in storage")
        }
        
        // 如果 userFavorites 为空，尝试从旧的 favoritesKey 加载（向后兼容）
        if userFavorites.isEmpty {
            if let favoritesArray = userDefaults.array(forKey: favoritesKey) as? [String] {
                userFavorites = Set(favoritesArray)
                print("✅ Loaded \(favoritesArray.count) favorites from legacy storage")
                
                // 同步到 currentUser
                if var user = currentUser {
                    let updatedUser = UserProfile(
                        id: user.id,
                        email: user.email,
                        name: user.name,
                        dogName: user.dogName,
                        dogPhotoURL: user.dogPhotoURL,
                        dogBirthday: user.dogBirthday,
                        dogBreed: user.dogBreed,
                        dogWeight: user.dogWeight,
                        dogGender: user.dogGender,
                        dogTraits: user.dogTraits,
                        dogNotes: user.dogNotes,
                        profileImageURL: user.profileImageURL,
                        favoritePlaceIDs: Array(userFavorites),
                        createdAt: user.createdAt,
                        updatedAt: Date()
                    )
                    currentUser = updatedUser
                    saveUserData()
                }
            } else {
                print("❌ No favorites found in storage")
            }
        }
    }
    
    // MARK: - Authentication Helper Methods
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func findUserByEmail(_ email: String) -> UserProfile? {
        let users = getAllRegisteredUsers()
        return users.first { $0.email.lowercased() == email.lowercased() }
    }
    
    private func getAllRegisteredUsers() -> [UserProfile] {
        guard let usersData = userDefaults.data(forKey: usersKey),
              let users = try? JSONDecoder().decode([UserProfile].self, from: usersData) else {
            return []
        }
        return users
    }
    
    private func saveUser(_ user: UserProfile, with password: String) {
        var users = getAllRegisteredUsers()
        
        // Remove existing user if updating
        users.removeAll { $0.email.lowercased() == user.email.lowercased() }
        
        // Add new user
        users.append(user)
        
        // Save users
        if let usersData = try? JSONEncoder().encode(users) {
            userDefaults.set(usersData, forKey: usersKey)
        }
        
        // Save password hash (in a real app, this would be much more secure)
        let passwordKey = "password_\(user.email.lowercased())"
        userDefaults.set(hashPassword(password), forKey: passwordKey)
    }
    
    private func updateUserInRegisteredList(_ updatedUser: UserProfile) {
        var users = getAllRegisteredUsers()
        
        // Find and update the user
        if let index = users.firstIndex(where: { $0.id == updatedUser.id }) {
            users[index] = updatedUser
            
            // Save updated users list
            if let usersData = try? JSONEncoder().encode(users) {
                userDefaults.set(usersData, forKey: usersKey)
                print("✅ Updated user in registered users list")
            } else {
                print("❌ Failed to update user in registered users list")
            }
        }
    }
    
    private func verifyPassword(_ password: String, for user: UserProfile) -> Bool {
        let passwordKey = "password_\(user.email.lowercased())"
        guard let storedHash = userDefaults.string(forKey: passwordKey) else {
            return false
        }
        return hashPassword(password) == storedHash
    }
    
    private func hashPassword(_ password: String) -> String {
        // Simple hash for demo - in production, use proper hashing like bcrypt
        let data = password.data(using: .utf8) ?? Data()
        return data.base64EncodedString()
    }
    
    func clearError() {
        errorMessage = nil
    }
}
