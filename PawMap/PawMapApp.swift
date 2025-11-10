//
//  PawMapApp.swift
//  PawMap
//
//  Created by Sunny on 9/4/25.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        print("🚀 App launched successfully with Firebase!")
        return true
    }
}

@main
struct PawMapApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    init() {
        // Firebase is already configured in AppDelegate
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AuthViewModel())
                .environmentObject(PlaceViewModel())
                .environmentObject(FavoritesViewModel())
                .environmentObject(TopPicksViewModel())
                .environmentObject(LocationService())
        }
    }
}
