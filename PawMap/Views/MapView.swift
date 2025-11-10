import Foundation
import CoreLocation
import MapKit
import SwiftUI
struct MapView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var placesManager: PlacesManager
    @EnvironmentObject var userManager: UserManager
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $locationManager.region,
                interactionModes: .all,
                showsUserLocation: true,
                userTrackingMode: .none,
                annotationItems: placesManager.places) { place in
                MapAnnotation(coordinate: place.coordinate) {
                    PlaceAnnotationView(place: place)
                        .onTapGesture {
                            placesManager.selectedPlace = place
                        }
                }
            }
            .ignoresSafeArea()
            
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: {
                        locationManager.centerOnUserLocation()
                    }) {
                        Image(systemName: "location.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding(.trailing)
                }
                .padding(.top)
                
                Spacer()
            }
            
            if locationManager.isLoading {
                VStack {
                    ProgressView("正在获取位置...")
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                    Spacer()
                }
                .padding()
            }
        }
        .onAppear {
            locationManager.requestLocationPermission()
        }
        .sheet(item: $placesManager.selectedPlace) { place in
            PlaceDetailView(place: place)
        }
    }
}

struct PlaceAnnotationView: View {
    let place: Place
    @EnvironmentObject var userManager: UserManager
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(Color(place.type.color))
                    .frame(width: 30, height: 30)
                
                Image(systemName: place.type.iconName)
                    .foregroundColor(.white)
                    .font(.system(size: 14, weight: .medium))
            }
            
            // 收藏标记
            if userManager.isFavorite(placeId: place.id) {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 12))
                    .offset(y: -5)
            }
            
            // 自动加载标记 (removed - not in current Place model)
        }
    }
}

#Preview {
    MapView()
        .environmentObject(LocationManager())
        .environmentObject(PlacesManager())
        .environmentObject(UserManager())
}
