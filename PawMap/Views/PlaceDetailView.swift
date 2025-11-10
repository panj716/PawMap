import Foundation
import CoreLocation
import MapKit
import SwiftUI


struct PlaceDetailView: View {
    let place: Place
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var placesManager: PlacesManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddReview = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 地点名称和类型
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(place.name)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Button(action: {
                                userManager.toggleFavorite(placeId: place.id)
                            }) {
                                Image(systemName: userManager.isFavorite(placeId: place.id) ? "heart.fill" : "heart")
                                    .font(.title2)
                                    .foregroundColor(userManager.isFavorite(placeId: place.id) ? .red : .gray)
                            }
                        }
                        
                        HStack {
                            Image(systemName: place.type.iconName)
                                .foregroundColor(Color(place.type.color))
                            Text(place.type.displayName)
                                .font(.headline)
                                .foregroundColor(Color(place.type.color))
                        }
                    }
                    
                    // 评分
                    HStack {
                        HStack(spacing: 2) {
                            ForEach(0..<5) { index in
                                Image(systemName: index < Int(place.rating) ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                            }
                        }
                        Text(String(format: "%.1f", place.rating))
                            .font(.headline)
                        Text("(0 评价)") // TODO: Load reviews from Firebase
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // 地址
                    HStack {
                        Image(systemName: "location")
                            .foregroundColor(.gray)
                        Text(place.address)
                            .font(.body)
                    }
                    
                    // 标签
                    if !place.tags.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("设施")
                                .font(.headline)
                            
                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 80))
                            ], spacing: 8) {
                                ForEach(place.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    
                    // 描述
                    if !place.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("描述")
                                .font(.headline)
                            Text(place.notes)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // 评价
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("评价")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button("添加评价") {
                                showingAddReview = true
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        
                        if true { // place.reviews.isEmpty { // TODO: Load reviews from Firebase
                            Text("暂无评价")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            // ForEach(place.reviews) { review in
                            //     ReviewRow(review: review)
                            // }
                        }
                    }
                    
                    // 操作按钮
                    VStack(spacing: 12) {
                        Button(action: {
                            openInMaps()
                        }) {
                            HStack {
                                Image(systemName: "map")
                                Text("获取路线")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                        if userManager.isLoggedIn {
                            Button(action: {
                                showingAddReview = true
                            }) {
                                HStack {
                                    Image(systemName: "star")
                                    Text("添加评价")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("地点详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddReview) {
            AddReviewView(place: place)
        }
    }
    
    private func openInMaps() {
        let coordinate = place.coordinate
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = place.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}


#Preview {
    PlaceDetailView(place: Place(
        name: "Belle Isle Park",
        type: .park,
        address: "Belle Isle, Detroit, MI",
        latitude: 42.3389,
        longitude: -82.9967,
        rating: 4.5,
        tags: ["户外", "大空间", "水边"],
        notes: "美丽的岛屿公园，有专门的狗狗区域",
        createdBy: "system"
    ))
    .environmentObject(UserManager())
    .environmentObject(PlacesManager())
}
