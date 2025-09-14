import Foundation
import CoreLocation
import MapKit
import SwiftUI

struct MeetupsView: View {
    @EnvironmentObject var userManager: UserManager
    @State private var showingCreateMeetup = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                Image(systemName: "person.3.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
                
                VStack(spacing: 16) {
                    Text("狗狗聚会")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("即将推出！")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("与附近的狗狗主人组织聚会，让您的狗狗结交新朋友")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Button(action: {
                    showingCreateMeetup = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("创建聚会")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(10)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("聚会")
        }
        .sheet(isPresented: $showingCreateMeetup) {
            CreateMeetupView()
        }
    }
}

struct CreateMeetupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userManager: UserManager
    
    @State private var title = ""
    @State private var location = ""
    @State private var selectedDate = Date()
    @State private var time = ""
    @State private var dogBreed = ""
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("聚会信息") {
                    TextField("聚会标题", text: $title)
                    TextField("地点", text: $location)
                    DatePicker("日期", selection: $selectedDate, displayedComponents: .date)
                    TextField("时间 (例如: 下午2点)", text: $time)
                }
                
                Section("狗狗信息") {
                    TextField("狗狗品种", text: $dogBreed)
                }
                
                Section("备注") {
                    TextField("其他信息...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("创建聚会")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("创建") {
                        createMeetup()
                    }
                    .disabled(title.isEmpty || location.isEmpty)
                }
            }
        }
    }
    
    private func createMeetup() {
        // 这里会创建聚会并保存
        // 目前只是演示功能
        dismiss()
    }
}

#Preview {
    MeetupsView()
        .environmentObject(UserManager())
}
