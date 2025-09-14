import Foundation
import CoreLocation
import MapKit
import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var userManager: UserManager
    @State private var showingLogin = false
    @State private var showingEditProfile = false
    
    var body: some View {
        NavigationView {
            Group {
                if userManager.isLoggedIn {
                    loggedInView
                } else {
                    loggedOutView
                }
            }
            .navigationTitle("个人")
        }
        .sheet(isPresented: $showingLogin) {
            LoginView()
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView()
        }
    }
    
    private var loggedInView: some View {
        List {
            // 用户信息
            Section {
                HStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text(userManager.currentUser?.name.prefix(1).uppercased() ?? "U")
                                .font(.title)
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(userManager.currentUser?.name ?? "用户")
                            .font(.headline)
                        Text(userManager.currentUser?.email ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("狗狗: \(userManager.currentUser?.dogBreed ?? "未设置")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 8)
            }
            
            // 狗狗信息
            Section {
                DogProfileSection()
            }
            
            // 统计信息
            Section("统计") {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                    Text("我想带\(userManager.currentUser?.dogName ?? "我的狗狗")去的地方")
                    Spacer()
                    Text("\(userManager.userFavorites.count)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("我的评价")
                    Spacer()
                    Text("0")
                        .foregroundColor(.secondary)
                }
            }
            
            // 设置
            Section("设置") {
                Button(action: {
                    showingEditProfile = true
                }) {
                    HStack {
                        Image(systemName: "person.circle")
                        Text("编辑资料")
                    }
                }
                
                Button(action: {
                    userManager.logout()
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("退出登录")
                    }
                    .foregroundColor(.red)
                }
            }
        }
    }
    
    private var loggedOutView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "person.circle")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            VStack(spacing: 16) {
                Text("欢迎使用 PawMap")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("登录以享受完整功能")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 12) {
                Button(action: {
                    showingLogin = true
                }) {
                    HStack {
                        Image(systemName: "envelope")
                        Text("邮箱登录")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                
                Button(action: {
                    userManager.loginWithGoogle()
                }) {
                    HStack {
                        Image(systemName: "globe")
                        Text("Google 登录")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(10)
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
    
    var body: some View {
        NavigationView {
            Form {
                Section("登录信息") {
                    TextField("邮箱", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("密码", text: $password)
                }
            }
            .navigationTitle("登录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("登录") {
                        userManager.login(email: email, password: password)
                        dismiss()
                    }
                    .disabled(email.isEmpty || password.isEmpty)
                }
            }
        }
    }
}

struct DogProfileSection: View {
    @EnvironmentObject var userManager: UserManager
    @State private var showingPhotoPicker = false
    @State private var selectedPhoto: PhotosPickerItem?
    
    var body: some View {
        VStack(spacing: 16) {
            // 狗狗照片
            VStack(spacing: 12) {
                if let dogPhotoData = userManager.currentUser?.dogPhoto,
                   let uiImage = UIImage(data: dogPhotoData) {
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
    @EnvironmentObject var userManager: UserManager
    
    @State private var name = ""
    @State private var dogBreed = ""
    @State private var dogName = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("个人信息") {
                    TextField("姓名", text: $name)
                }
                
                Section("狗狗信息") {
                    TextField("狗狗姓名", text: $dogName)
                    TextField("狗狗品种", text: $dogBreed)
                }
            }
            .navigationTitle("编辑资料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        userManager.updateProfile(name: name, dogBreed: dogBreed, dogName: dogName)
                        dismiss()
                    }
                    .disabled(name.isEmpty || dogName.isEmpty)
                }
            }
        }
        .onAppear {
            name = userManager.currentUser?.name ?? ""
            dogBreed = userManager.currentUser?.dogBreed ?? ""
            dogName = userManager.currentUser?.dogName ?? ""
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(UserManager())
}
