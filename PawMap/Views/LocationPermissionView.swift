import SwiftUI

struct LocationPermissionView: View {
    @EnvironmentObject var locationManager: LocationManager
    @State private var showingSkipAlert = false
    @State private var hasSkippedPermission = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 24) {
                // 图标
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "location.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                }
                
                // 标题和描述
                VStack(spacing: 12) {
                    Text("允许位置访问")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("PawMap需要访问您的位置来为您推荐附近的狗狗友好地点，让您和您的狗狗享受更好的体验。")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                // 功能列表
                VStack(spacing: 16) {
                    PermissionFeatureRow(
                        icon: "map.fill",
                        title: "发现附近地点",
                        description: "找到您周围的狗狗友好场所"
                    )
                    
                    PermissionFeatureRow(
                        icon: "location.circle.fill",
                        title: "个性化推荐",
                        description: "根据您的位置推荐最佳路线"
                    )
                    
                    PermissionFeatureRow(
                        icon: "heart.fill",
                        title: "社区分享",
                        description: "与其他狗狗主人分享您的位置"
                    )
                }
                .padding(.horizontal, 20)
                
                // 按钮
                VStack(spacing: 12) {
                    Button(action: {
                        print("Requesting location permission...")
                        locationManager.requestLocationPermission()
                    }) {
                        Text("允许位置访问")
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
                        Text("稍后设置")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: {
                        locationManager.debugLocationStatus()
                    }) {
                        Text("调试信息")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Button(action: {
                        locationManager.forceCenterOnUserLocation()
                    }) {
                        Text("定位到我的位置")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    
                    Button(action: {
                        locationManager.startFollowingUser()
                    }) {
                        Text("开始跟随我的位置")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    
                    Button(action: {
                        locationManager.requestFreshLocation()
                    }) {
                        Text("请求最新位置")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: {
                        locationManager.resetLocationPermissionState()
                    }) {
                        Text("重置权限状态(测试)")
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
        .alert("跳过位置权限", isPresented: $showingSkipAlert) {
            Button("确定") {
                hasSkippedPermission = true
                locationManager.hasHandledPermissionPrompt = true
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("您可以稍后在设置中启用位置权限。没有位置权限，您将无法看到附近的地点推荐。")
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
