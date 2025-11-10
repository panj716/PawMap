import Foundation
import CoreLocation
import MapKit
import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingLogin = false
    @State private var showingEditProfile = false
    
    var body: some View {
        NavigationView {
            Group {
                if authViewModel.isAuthenticated {
                    loggedInView
                } else {
                    loggedOutView
                }
            }
            .navigationTitle("Me")
        }
        .sheet(isPresented: $showingLogin) {
            AuthenticationView()
                .environmentObject(authViewModel)
        }
        .sheet(isPresented: $showingEditProfile) {
            NavigationView {
            EditProfileView()
                    .environmentObject(authViewModel)
            }
        }
    }
    
    private var loggedInView: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header with edit and sign out buttons
                HStack {
                    Text("My Profile")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: {
                        showingEditProfile = true
                    }) {
                        Image(systemName: "ellipsis")
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                    
                    Button(action: {
                        authViewModel.signOut()
                    }) {
                        Text("Sign Out")
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer(minLength: 30)
                
                // Dog Profile Section
                VStack(spacing: 20) {
                    // User Profile Picture
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Group {
                                    if false, // let profileImage = userManager.currentUser?.profileImageURL, // TODO: Load image from URL
                                       let uiImage = UIImage(data: Data()) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 80, height: 80)
                                            .clipShape(Circle())
                                    } else {
                                        Image(systemName: "person.circle.fill")
                                            .font(.system(size: 40))
                                            .foregroundColor(.gray)
                                    }
                                }
                            )
                        
                        // Edit user photo button
                        PhotosPicker(selection: Binding(
                            get: { nil },
                            set: { item in
                                Task {
                                    if let data = try? await item?.loadTransferable(type: Data.self) {
                                        userManager.updateProfilePhoto(data)
                                    }
                                }
                            }
                        ), matching: .images) {
                    Circle()
                        .fill(Color.blue)
                                .frame(width: 24, height: 24)
                        .overlay(
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 12))
                                .foregroundColor(.white)
                        )
                        }
                        .offset(x: 30, y: 30)
                    }
                    
                    // Dog Profile Picture
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 120, height: 120)
                            .overlay(
                                Group {
                                    if false, // let dogPhoto = userManager.currentUser?.dogPhotoURL, // TODO: Load image from URL
                                       let uiImage = UIImage(data: Data()) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 120, height: 120)
                                            .clipShape(Circle())
                                    } else {
                                        Image(systemName: "pawprint.fill")
                                            .font(.system(size: 40))
                                            .foregroundColor(.gray)
                                    }
                                }
                            )
                        
                        // Edit dog photo button
                        PhotosPicker(selection: Binding(
                            get: { nil },
                            set: { item in
                                Task {
                                    if let data = try? await item?.loadTransferable(type: Data.self) {
                                        userManager.updateDogPhoto(data)
                                    }
                                }
                            }
                        ), matching: .images) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Image(systemName: "pawprint.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                )
                        }
                        .offset(x: 40, y: 40)
                    }
                    
                    // User Name
                    Text(authViewModel.currentUser?.name ?? "User")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    // Email
                    Text(authViewModel.currentUser?.email ?? "")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    // Dog Name
                    Text((authViewModel.currentUser?.dogName?.isEmpty == false) ? (authViewModel.currentUser?.dogName ?? "Your Dog's Name") : "Your Dog's Name")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor((authViewModel.currentUser?.dogName?.isEmpty == false) ? .black : .gray)
                    
                    // Breed
                    Text(((authViewModel.currentUser?.dogBreed?.isEmpty) == false) ? (authViewModel.currentUser?.dogBreed ?? "Breed") : "Breed")
                        .font(.title3)
                        .foregroundColor((authViewModel.currentUser?.dogBreed?.isEmpty == false) ? .black : .gray)
                    
                    // Basic Stats
                    if let user = authViewModel.currentUser, 
                       (user.dogGender?.isEmpty ?? true) == false && user.dogBirthday != nil && (user.dogWeight ?? 0) > 0 {
                        HStack {
                            Image(systemName: "pawprint.fill")
                                .foregroundColor(.brown)
                                .font(.caption)
                            
                            Text("\(user.dogGender ?? "Unknown"), \(user.dogAgeDescription) • \(Int(user.dogWeight ?? 0)) lbs")
                                .font(.subheadline)
                                .foregroundColor(.black)
                        }
                    } else {
                        HStack {
                            Image(systemName: "pawprint.fill")
                                .foregroundColor(.gray)
                                .font(.caption)
                            
                            Text("Add your dog's details")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Traits
                    if let user = authViewModel.currentUser, !user.dogTraits.isEmpty {
                        HStack(spacing: 20) {
                            ForEach(Array(user.dogTraits.enumerated()), id: \.offset) { index, trait in
                                VStack(spacing: 8) {
                                    Circle()
                                        .fill(Color.brown.opacity(0.1))
                                        .frame(width: 50, height: 50)
                                        .overlay(
                                            Image(systemName: traitIcons[safe: index] ?? "heart.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(traitColors[safe: index] ?? .brown)
                                        )
                                    
                                    Text(trait)
                                        .font(.caption)
                                        .foregroundColor(.black)
                                }
                            }
                        }
                        .padding(.vertical, 20)
                    } else {
                        Text("Add your dog's personality traits")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.vertical, 20)
                    }
                    
                    // Pet Notes Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Pet Notes")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            if let user = authViewModel.currentUser, !(user.dogNotes?.isEmpty ?? true) {
                                Text(user.dogNotes ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.black)
                                    .multilineTextAlignment(.leading)
                            } else {
                                Text("Add notes about your dog's personality, preferences, or special needs")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .italic()
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 50)
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                Button(action: {
                    showingEditProfile = true
                }) {
                    HStack {
                                Image(systemName: "pencil")
                                Text("Edit Profile")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                }
                
                Button(action: {
                    userManager.logout()
                }) {
                    HStack {
                                Image(systemName: "arrow.right.square")
                                Text("Logout")
                            }
                            .font(.headline)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.horizontal, 20)
            }
        }
        .background(Color.white)
        .navigationBarHidden(true)
    }
    
    private var traitIcons: [String] {
        ["bolt.fill", "heart.fill", "wave.3.right"]
    }
    
    private var traitColors: [Color] {
        [.green, .brown, .brown]
    }
    
    private var loggedOutView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "person.circle")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            VStack(spacing: 16) {
                Text("Welcome to PawMap")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Sign in to save your dog's profile and favorite places")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            VStack(spacing: 12) {
                Button(action: {
                    showingLogin = true
                }) {
                    HStack {
                        Image(systemName: "person.fill")
                        Text("Sign In / Sign Up")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
}

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userManager: UserManager
    
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isSignupMode = false
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            Form {
                if isSignupMode {
                    Section("Personal Information") {
                        TextField("Full Name", text: $name)
                            .textContentType(.name)
                    }
                }
                
                Section("Login Information") {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textContentType(.emailAddress)
                    
                    SecureField("Password", text: $password)
                        .textContentType(isSignupMode ? .newPassword : .password)
                }
                
                if let errorMessage = userManager.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(isSignupMode ? "Sign Up" : "Login")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        userManager.clearError()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if userManager.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Button(isSignupMode ? "Sign Up" : "Login") {
                            if isSignupMode {
                                userManager.signup(email: email, password: password, name: name)
                            } else {
                        userManager.login(email: email, password: password)
                            }
                            
                            // Dismiss after successful login/signup
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                if userManager.isLoggedIn {
                        dismiss()
                                }
                            }
                        }
                        .disabled(isSignupMode ? (email.isEmpty || password.isEmpty || name.isEmpty) : (email.isEmpty || password.isEmpty))
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !userManager.isLoading {
                        Button(isSignupMode ? "Login" : "Sign Up") {
                            isSignupMode.toggle()
                            userManager.clearError()
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
        }
        .onChange(of: userManager.isLoggedIn) { _, isLoggedIn in
            if isLoggedIn {
                dismiss()
            }
        }
    }
}

struct DogProfileSection: View {
    @EnvironmentObject var userManager: UserManager
    @State private var showingPhotoPicker = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showingUserPhotoPicker = false
    @State private var selectedUserPhoto: PhotosPickerItem?
    
    var body: some View {
        VStack(spacing: 16) {
            // 狗狗照片
            VStack(spacing: 12) {
                if false, // let dogPhotoData = userManager.currentUser?.dogPhotoURL, // TODO: Load image from URL
                   let uiImage = UIImage(data: Data()) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.pink, lineWidth: 3)
                        )
                        .shadow(color: .pink.opacity(0.3), radius: 8, x: 0, y: 4)
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.pink, Color.pink.opacity(0.7)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .overlay(
                            Image(systemName: "pawprint.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        )
                        .shadow(color: .pink.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Text("添加狗狗照片")
                        .font(.subheadline)
                        .foregroundColor(.pink)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.pink.opacity(0.1))
                        .cornerRadius(20)
                }
            }
            
            // 狗狗信息
            VStack(spacing: 8) {
                Text(userManager.currentUser?.dogName ?? "我的狗狗")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(userManager.currentUser?.dogBreed ?? "狗狗品种")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .onChange(of: selectedPhoto) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                    userManager.updateDogPhoto(data)
                }
            }
        }
    }
}

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var name = ""
    @State private var dogBreed = ""
    @State private var dogName = ""
    @State private var dogBirthday = Date()
    @State private var dogWeight = ""
    @State private var dogGender = "Female"
    @State private var selectedTraits: Set<String> = []
    @State private var dogNotes = ""
    
    private let availableTraits = ["Energetic", "Friendly", "Loves to swim", "Calm", "Playful", "Loyal", "Active", "Gentle"]
    private let genderOptions = ["Male", "Female"]
    
    var body: some View {
            Form {
                Section("Personal Information") {
                    TextField("Name", text: $name)
                }
                
                Section("Dog Information") {
                    TextField("Dog Name", text: $dogName)
                    TextField("Breed", text: $dogBreed)
                    
                    DatePicker("Birthday", selection: $dogBirthday, displayedComponents: .date)
                        .datePickerStyle(.compact)
                    
                    HStack {
                        TextField("Weight", text: $dogWeight)
                            .keyboardType(.decimalPad)
                        Text("lbs")
                            .foregroundColor(.secondary)
                    }
                    
                    Picker("Gender", selection: $dogGender) {
                        ForEach(genderOptions, id: \.self) { gender in
                            Text(gender).tag(gender)
                        }
                    }
                }
                
                Section("Traits") {
                    ForEach(availableTraits, id: \.self) { trait in
                        HStack {
                            Text(trait)
                            Spacer()
                            if selectedTraits.contains(trait) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedTraits.contains(trait) {
                                selectedTraits.remove(trait)
                            } else {
                                selectedTraits.insert(trait)
                            }
                        }
                    }
                }
                
                Section("Pet Notes") {
                    TextField("Add notes about your dog...", text: $dogNotes, axis: .vertical)
                        .lineLimit(3...6)
                }
        }
        .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveProfile()
                        dismiss()
                }
                .disabled(name.isEmpty || dogName.isEmpty)
            }
        }
        .onAppear {
            loadCurrentData()
        }
    }
    
    private func loadCurrentData() {
        print("📋 Loading current data for edit profile...")
        guard let user = authViewModel.currentUser else { 
            print("❌ No current user found in loadCurrentData")
            return 
        }
        print("👤 Loading data for user: \(user.name)")
        name = user.name
        dogBreed = user.dogBreed ?? ""
        dogName = user.dogName ?? ""
        dogBirthday = user.dogBirthday ?? Date()
        dogWeight = (user.dogWeight ?? 0) > 0 ? String(user.dogWeight ?? 0) : ""
        dogGender = (user.dogGender?.isEmpty == false) ? (user.dogGender ?? "Female") : "Female"
        selectedTraits = Set(user.dogTraits)
        dogNotes = user.dogNotes ?? ""
        print("✅ Data loaded successfully")
    }
    
    private func saveProfile() {
        print("🔄 Starting to save profile...")
        print("📋 Form data - Name: \(name), Dog: \(dogName), Breed: \(dogBreed)")
        
        let notes = dogNotes.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        let weight = Double(dogWeight) ?? 0.0
        let traits = Array(selectedTraits)
        
        print("📊 Processed data - Weight: \(weight), Traits: \(traits), Notes: \(notes)")
        
        guard let user = authViewModel.currentUser else {
            print("❌ No current user found in saveProfile")
            return
        }
        
        let updatedUser = PawMapUser(
            id: user.id,
            email: user.email,
            name: name,
            profileImageUrl: user.profileImageUrl,
            dogName: dogName.isEmpty ? nil : dogName,
            dogBreed: dogBreed.isEmpty ? nil : dogBreed,
            dogBirthday: dogBirthday,
            dogWeight: weight,
            dogGender: dogGender,
            dogTraits: traits,
            dogNotes: notes.joined(separator: "\n"),
            favoritePlaceIDs: user.favoritePlaceIDs,
            createdAt: user.createdAt,
            lastActiveAt: Date()
        )
        
        authViewModel.updateProfile(updatedUser)
        
        print("💾 Profile save completed")
    }
}

#Preview {
    ProfileView()
        .environmentObject(UserManager())
}

// Extension for safe array access
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
