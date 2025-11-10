import SwiftUI

struct SearchSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var placesManager: PlacesManager
    @Binding var searchText: String
    
    @State private var searchResults: [Place] = []
    @State private var isSearching = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜索栏
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("搜索地点、地址或标签...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onChange(of: searchText) { _, newValue in
                            performSearch(query: newValue)
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            searchResults = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                // 搜索结果
                if isSearching {
                    VStack {
                        Spacer()
                        ProgressView("搜索中...")
                        Spacer()
                    }
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("未找到结果")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("尝试使用不同的关键词搜索")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                } else if searchResults.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "map.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("搜索狗狗友好的地方")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("输入地点名称、地址或标签来搜索")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        // 热门搜索
                        VStack(alignment: .leading, spacing: 12) {
                            Text("热门搜索")
                                .font(.headline)
                                .padding(.top, 20)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                ForEach(["咖啡店", "狗公园", "海滩", "步道"], id: \.self) { tag in
                                    Button(action: {
                                        searchText = tag
                                        performSearch(query: tag)
                                    }) {
                                        Text(tag)
                                            .font(.caption)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.blue.opacity(0.1))
                                            .foregroundColor(.blue)
                                            .cornerRadius(16)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer()
                    }
                } else {
                    List(searchResults) { place in
                        SearchResultRow(place: place)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("搜索")
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
    
    private func performSearch(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        // 模拟搜索延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            searchResults = placesManager.places.filter { place in
                place.name.localizedCaseInsensitiveContains(query) ||
                place.address.localizedCaseInsensitiveContains(query) ||
                place.tags.contains { $0.localizedCaseInsensitiveContains(query) } ||
                place.type.displayName.localizedCaseInsensitiveContains(query)
            }
            isSearching = false
        }
    }
}

struct SearchResultRow: View {
    let place: Place
    @EnvironmentObject var userManager: UserManager
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            HStack(spacing: 12) {
                // 类型图标
                ZStack {
                    Circle()
                        .fill(Color(place.type.color))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: place.type.iconName)
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .medium))
                }
                
                // 地点信息
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(place.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if userManager.isFavorite(placeId: place.id) {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 14))
                        }
                    }
                    
                    Text(place.address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    HStack {
                        HStack(spacing: 2) {
                            ForEach(0..<5) { index in
                                Image(systemName: index < Int(place.rating) ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                                    .font(.system(size: 12))
                            }
                        }
                        
                        Text(String(format: "%.1f", place.rating))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(place.type.displayName)
                            .font(.caption)
                            .foregroundColor(Color(place.type.color))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(place.type.color).opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            PlaceDetailView(place: place)
        }
    }
}

#Preview {
    SearchSheetView(searchText: .constant(""))
        .environmentObject(PlacesManager())
        .environmentObject(UserManager())
}
