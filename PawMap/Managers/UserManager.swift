import Foundation
import CoreLocation
import MapKit
import Combine
import PhotosUI

class UserManager: ObservableObject {
    @Published var isLoggedIn = false
    @Published var currentUser: UserProfile?
    @Published var userFavorites: Set<String> = []
    
    private let userDefaults = UserDefaults.standard
    private let favoritesKey = "userFavorites"
    private let userKey = "currentUser"
    private let loginKey = "isLoggedIn"
    
    init() {
        loadUserData()
    }
    
    func login(email: String, password: String) {
        // 模拟登录 - 在实际应用中这里会调用API
        let user = UserProfile(
            id: UUID().uuidString,
            name: "用户",
            email: email,
            dogBreed: "金毛",
            dogName: "我的狗狗",
            profileImage: nil,
            dogPhoto: nil
        )
        
        currentUser = user
        isLoggedIn = true
        saveUserData()
    }
    
    func loginWithGoogle() {
        // 模拟Google登录
        let user = UserProfile(
            id: UUID().uuidString,
            name: "Google用户",
            email: "user@gmail.com",
            dogBreed: "拉布拉多",
            dogName: "我的狗狗",
            profileImage: nil,
            dogPhoto: nil
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
    
    func updateProfile(name: String, dogBreed: String, dogName: String) {
        guard var user = currentUser else { return }
        
        let updatedUser = UserProfile(
            id: user.id,
            name: name,
            email: user.email,
            dogBreed: dogBreed,
            dogName: dogName,
            profileImage: user.profileImage,
            dogPhoto: user.dogPhoto
        )
        
        currentUser = updatedUser
        saveUserData()
    }
    
    func updateDogPhoto(_ photoData: Data?) {
        guard var user = currentUser else { return }
        
        let updatedUser = UserProfile(
            id: user.id,
            name: user.name,
            email: user.email,
            dogBreed: user.dogBreed,
            dogName: user.dogName,
            profileImage: user.profileImage,
            dogPhoto: photoData
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
        saveUserData()
    }
    
    func isFavorite(placeId: String) -> Bool {
        return userFavorites.contains(placeId)
    }
    
    private func saveUserData() {
        userDefaults.set(isLoggedIn, forKey: loginKey)
        
        if let user = currentUser {
            if let userData = try? JSONEncoder().encode(user) {
                userDefaults.set(userData, forKey: userKey)
            }
        }
        
        let favoritesArray = Array(userFavorites)
        userDefaults.set(favoritesArray, forKey: favoritesKey)
    }
    
    private func loadUserData() {
        isLoggedIn = userDefaults.bool(forKey: loginKey)
        
        if let userData = userDefaults.data(forKey: userKey),
           let user = try? JSONDecoder().decode(UserProfile.self, from: userData) {
            currentUser = user
        }
        
        if let favoritesArray = userDefaults.array(forKey: favoritesKey) as? [String] {
            userFavorites = Set(favoritesArray)
        }
    }
}
