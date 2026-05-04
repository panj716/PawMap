import SwiftUI

struct LocationPermissionView: View {
    @EnvironmentObject var locationManager: LocationManager
    @State private var showingSkipAlert = false
    @State private var hasSkippedPermission = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "location.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                }
                
                VStack(spacing: 12) {
                    Text("Enable location")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("PawMap uses your location to show dog-friendly places nearby and personalize your experience.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                VStack(spacing: 16) {
                    PermissionFeatureRow(
                        icon: "map.fill",
                        title: "Discover nearby",
                        description: "Find dog-friendly spots around you"
                    )
                    
                    PermissionFeatureRow(
                        icon: "location.circle.fill",
                        title: "Personalized picks",
                        description: "Better recommendations based on where you are"
                    )
                    
                    PermissionFeatureRow(
                        icon: "heart.fill",
                        title: "Community",
                        description: "Share places with other dog parents"
                    )
                }
                .padding(.horizontal, 20)
                
                VStack(spacing: 12) {
                    Button(action: {
                        print("Requesting location permission...")
                        locationManager.requestLocationPermission()
                    }) {
                        Text("Allow location access")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        showingSkipAlert = true
                    }) {
                        Text("Not now")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: {
                        locationManager.debugLocationStatus()
                    }) {
                        Text("Debug info")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Button(action: {
                        locationManager.forceCenterOnUserLocation()
                    }) {
                        Text("Center on my location")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    
                    Button(action: {
                        locationManager.startFollowingUser()
                    }) {
                        Text("Follow my location")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    
                    Button(action: {
                        locationManager.requestFreshLocation()
                    }) {
                        Text("Refresh location")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: {
                        locationManager.resetLocationPermissionState()
                    }) {
                        Text("Reset permission (debug)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal, 20)
            }
            
            Spacer()
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
        .padding(.horizontal, 20)
        .padding(.bottom, 50)
        .alert("Skip location?", isPresented: $showingSkipAlert) {
            Button("OK") {
                hasSkippedPermission = true
                locationManager.hasHandledPermissionPrompt = true
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("You can turn on location later in Settings. Without it, nearby recommendations won’t work as well.")
        }
        .opacity(hasSkippedPermission ? 0 : 1)
        .animation(.easeInOut(duration: 0.3), value: hasSkippedPermission)
    }
}

struct PermissionFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    LocationPermissionView()
        .environmentObject(LocationManager())
}
