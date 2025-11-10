//
//  ContentView.swift
//  PawMap
//
//  Created by Sunny on 9/4/25.
//

import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        MainMapView()
            .environmentObject(LocationManager())
            .environmentObject(PlacesManager())
            .environmentObject(UserManager())
            .environmentObject(authViewModel)
    }
}

// MARK: - Main App View

struct MainAppView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var placeViewModel: PlaceViewModel
    @EnvironmentObject var locationService: LocationService
    
    var body: some View {
        ZStack {
            // Main map view
            ModernMapView()
                .environmentObject(placeViewModel)
                .environmentObject(locationService)
            
            // Bottom navigation
            VStack {
                Spacer()
                // BottomNavigationBar() - commented out due to missing parameters
                // .environmentObject(authViewModel)
                // .environmentObject(placeViewModel)
            }
        }
        .sheet(isPresented: $authViewModel.showingLogin) {
            LoginView()
                .environmentObject(authViewModel)
        }
        .sheet(isPresented: $authViewModel.showingSignUp) {
            SignUpView()
                .environmentObject(authViewModel)
        }
    }
}

struct MainMapView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var placesManager: PlacesManager
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var showingFilterSheet = false
    @State private var showingAddPlaceSheet = false
    @State private var showingSearchSheet = false
    @State private var selectedFilter: Place.PlaceType?
    @State private var searchText = ""
    @State private var showingLocationPermissionAlert = false
    @State private var selectedTab = 1 // 默认选中中间的+按钮
    
    var body: some View {
        ZStack {
            // 全屏地图
            ModernMapView()
                .environmentObject(locationManager)
                .environmentObject(placesManager)
                .environmentObject(userManager)
                .ignoresSafeArea()
            
            // 顶部控制栏
            VStack {
                HStack {
                    // 搜索按钮
                    Button(action: {
                        showingSearchSheet = true
                    }) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.pink)
                            Text("搜索狗狗友好的地方...")
                                .foregroundColor(.pink.opacity(0.7))
                            Spacer()
                            Image(systemName: "pawprint.fill")
                                .foregroundColor(.pink.opacity(0.5))
                                .font(.caption)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Color.pink.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .shadow(color: .pink.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    
                    // 筛选按钮
                    Button(action: {
                        showingFilterSheet = true
                    }) {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.pink, Color.pink.opacity(0.8)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Circle())
                            .shadow(color: .pink.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                Spacer()
            }
            
            // 底部导航栏
        VStack {
                Spacer()
                
                BottomNavigationBar(
                    showingAddPlaceSheet: $showingAddPlaceSheet,
                    locationManager: locationManager,
                    showingLocationPermissionAlert: $showingLocationPermissionAlert,
                    selectedTab: $selectedTab
                )
                .environmentObject(authViewModel)
            }
            
            // 位置权限提示
            if locationManager.authorizationStatus == .notDetermined && !locationManager.hasHandledPermissionPrompt {
                LocationPermissionView()
                    .environmentObject(locationManager)
                    .environmentObject(placesManager)
                    .environmentObject(userManager)
            }
        }
        .sheet(isPresented: $showingFilterSheet) {
            FilterSheetView(selectedFilter: $selectedFilter)
                .environmentObject(locationManager)
                .environmentObject(placesManager)
                .environmentObject(userManager)
        }
        .sheet(isPresented: $showingAddPlaceSheet) {
            AddPlaceSheetView()
                .environmentObject(PlaceViewModel())
                .environmentObject(authViewModel)
                .environmentObject(locationManager)
                .environmentObject(placesManager)
        }
        .sheet(isPresented: $showingSearchSheet) {
            SearchSheetView(searchText: $searchText)
                .environmentObject(locationManager)
                .environmentObject(placesManager)
                .environmentObject(userManager)
        }
        .alert("需要位置权限", isPresented: $showingLocationPermissionAlert) {
            Button("设置") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("请在设置中允许PawMap访问您的位置，以便为您推荐附近的狗狗友好地点。")
        }
        .onAppear {
            locationManager.requestLocationPermission()
        }
    }
}

struct BottomNavigationBar: View {
    @Binding var showingAddPlaceSheet: Bool
    let locationManager: LocationManager
    @Binding var showingLocationPermissionAlert: Bool
    @Binding var selectedTab: Int
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var placesManager: PlacesManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingFavoritesSheet = false
    @State private var showingProfileSheet = false
    @State private var showingTopPicksSheet = false
    
    var body: some View {
        HStack(spacing: 0) {
            // Explore 按钮
            Button(action: {
                selectedTab = 0
                // 这里可以添加explore功能
            }) {
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(selectedTab == 0 ? Color.pink.opacity(0.2) : Color.clear)
                            .frame(width: 45, height: 45)
                        
                        Image(systemName: selectedTab == 0 ? "pawprint.circle.fill" : "pawprint.circle")
                            .font(.system(size: 24))
                            .foregroundColor(selectedTab == 0 ? .pink : .gray)
                    }
                    
                    Text("Explore")
                        .font(.caption2)
                        .foregroundColor(selectedTab == 0 ? .pink : .gray)
                }
            }
            .frame(maxWidth: .infinity)
            
            // Top Picks 按钮
            Button(action: {
                selectedTab = 1
                showingTopPicksSheet = true
            }) {
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(selectedTab == 1 ? Color.purple.opacity(0.2) : Color.clear)
                            .frame(width: 45, height: 45)
                        
                        Image(systemName: selectedTab == 1 ? "heart.circle.fill" : "heart.circle")
                            .font(.system(size: 24))
                            .foregroundColor(selectedTab == 1 ? .purple : .gray)
                    }
                    
                    Text("Top Picks")
                        .font(.caption2)
                        .foregroundColor(selectedTab == 1 ? .purple : .gray)
                }
            }
            .frame(maxWidth: .infinity)
            
            // 中间的 + 按钮 (主要按钮)
            Button(action: {
                selectedTab = 2
                showingAddPlaceSheet = true
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.pink, Color.pink.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                        .shadow(color: .pink.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .overlay(
                            Image(systemName: "pawprint.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.8))
                                .offset(x: 8, y: -8)
                        )
                }
                .scaleEffect(selectedTab == 2 ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedTab)
            }
            .frame(maxWidth: .infinity)
            
            // Favorites 按钮
            Button(action: {
                selectedTab = 3
                showingFavoritesSheet = true
            }) {
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(selectedTab == 3 ? Color.red.opacity(0.2) : Color.clear)
                            .frame(width: 45, height: 45)
                        
                        Image(systemName: selectedTab == 3 ? "heart.fill" : "heart")
                            .font(.system(size: 24))
                            .foregroundColor(selectedTab == 3 ? .red : .gray)
                    }
                    
                    Text("Favorites")
                        .font(.caption2)
                        .foregroundColor(selectedTab == 3 ? .red : .gray)
                }
            }
            .frame(maxWidth: .infinity)
            
            // Me 按钮
            Button(action: {
                selectedTab = 4
                showingProfileSheet = true
            }) {
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(selectedTab == 4 ? Color.pink.opacity(0.2) : Color.clear)
                            .frame(width: 45, height: 45)
                        
                        Image(systemName: selectedTab == 4 ? "person.circle.fill" : "person.circle")
                            .font(.system(size: 24))
                            .foregroundColor(selectedTab == 4 ? .pink : .gray)
                            .overlay(
                                Image(systemName: "pawprint.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(selectedTab == 4 ? .pink : .gray)
                                    .offset(x: 12, y: -12)
                            )
                    }
                    
                    Text("Me")
                        .font(.caption2)
                        .foregroundColor(selectedTab == 4 ? .pink : .gray)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 34) // 为安全区域留出空间
        .sheet(isPresented: $showingFavoritesSheet) {
            FavoritesView()
                .environmentObject(authViewModel)
                .environmentObject(placesManager)
        }
        .sheet(isPresented: $showingProfileSheet) {
            ProfileView()
                .environmentObject(authViewModel)
        }
        .sheet(isPresented: $showingTopPicksSheet) {
            TopPicksView()
                .environmentObject(locationManager)
        }
        .onAppear {
            // Request location permission when app starts
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                locationManager.requestLocationPermission()
            }
        }
        .alert("Location Access Required", isPresented: $showingLocationPermissionAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("PawMap needs access to your location to show nearby dog-friendly places. Please enable location access in Settings.")
        }
        .onChange(of: locationManager.authorizationStatus) { _, status in
            if status == .denied || status == .restricted {
                showingLocationPermissionAlert = true
            }
        }
    }
}

struct FavoritesListView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var placesManager: PlacesManager
    @Environment(\.dismiss) private var dismiss
    
    var favoritePlaces: [Place] {
        placesManager.places.filter { place in
            userManager.isFavorite(placeId: place.id)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 头部装饰
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.pink, Color.pink.opacity(0.8)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "heart.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                    }
                    
                    Text("我的收藏")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.pink)
                    
                    Text("\(favoritePlaces.count) 个地点")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                .padding(.bottom, 20)
                
                if favoritePlaces.isEmpty {
                    // 空状态
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "heart")
                            .font(.system(size: 60))
                            .foregroundColor(.pink.opacity(0.3))
                        
                        Text("还没有收藏的地点")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Text("在地图上点击地点，然后点击❤️来收藏")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Spacer()
                    }
                } else {
                    // 收藏列表
                    List(favoritePlaces) { place in
                        FavoritePlaceRow(place: place)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("收藏")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}


#Preview {
    ContentView()
}
