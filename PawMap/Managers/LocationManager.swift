import Foundation
import CoreLocation
import MapKit
import Combine
import SwiftUI

class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    
    @Published var location: CLLocation?
    /// Default view: Ann Arbor–Birmingham corridor so curated “district” pins (e.g. Birmingham) stay on-screen.
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 42.39, longitude: -83.50),
        span: MKCoordinateSpan(latitudeDelta: 0.42, longitudeDelta: 0.58)
    )
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLoading = false
    @Published var hasHandledPermissionPrompt = false
    @Published var shouldFollowUser = true
    @Published var isFollowingUser = false
    @Published var mapCameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 42.39, longitude: -83.50),
            span: MKCoordinateSpan(latitudeDelta: 0.42, longitudeDelta: 0.58)
        )
    )
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation // Highest accuracy like web version
        locationManager.distanceFilter = 0 // No distance filter for most accurate tracking
        locationManager.pausesLocationUpdatesAutomatically = false // Don't pause updates
        locationManager.allowsBackgroundLocationUpdates = false // Don't track in background
        
        // Check current authorization status
        authorizationStatus = locationManager.authorizationStatus
        
        
        // Zipcode flow does not require auto location permission prompt.
    }
    
    func requestLocationPermission() {
        hasHandledPermissionPrompt = true
        
        print("Requesting location permission...")
        
        // Check if we already have permission
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            print("Location already authorized, starting updates")
            startLocationUpdates()
            return
        }
        
        // Check if location services are enabled
        guard CLLocationManager.locationServicesEnabled() else {
            print("Location services are disabled")
            return
        }
        
        // Request permission
        print("Requesting when-in-use authorization")
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startLocationUpdates() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            print("Location not authorized, requesting permission")
            requestLocationPermission()
            return
        }
        
        guard CLLocationManager.locationServicesEnabled() else {
            print("Location services disabled")
            return
        }
        
        print("Starting location updates...")
        isLoading = true
        locationManager.startUpdatingLocation()
        locationManager.requestLocation() // Request immediate location update
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        isLoading = false
    }
    
    func setRegion(to coordinate: CLLocationCoordinate2D, animated: Bool = true) {
        let newRegion = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        
        // Update both region and camera position
        region = newRegion
        mapCameraPosition = .region(newRegion)
    }
    
    /// Sets both `region` and `mapCameraPosition` (SwiftUI `Map`) to the same logical area.
    func applyMapRegion(_ newRegion: MKCoordinateRegion) {
        region = newRegion
        mapCameraPosition = .region(newRegion)
    }
    
    func centerOnUserLocation() {
        guard let location = location else { 
            print("No location available to center on")
            return 
        }
        print("Centering on user location: \(location.coordinate)")
        setRegion(to: location.coordinate, animated: true)
        isFollowingUser = true
        shouldFollowUser = true
    }
    
    func checkLocationServicesEnabled() -> Bool {
        return CLLocationManager.locationServicesEnabled()
    }
    
    func getCurrentAuthorizationStatus() -> CLAuthorizationStatus {
        return locationManager.authorizationStatus
    }
    
    func debugLocationStatus() {
        print("=== Location Debug Info ===")
        print("Location Services Enabled: \(CLLocationManager.locationServicesEnabled())")
        print("Authorization Status: \(authorizationStatus.rawValue)")
        if let loc = location {
            print("Current Location: \(loc.coordinate)")
            print("Location Accuracy: \(loc.horizontalAccuracy)m")
            print("Location Age: \(abs(loc.timestamp.timeIntervalSinceNow))s")
            print("Location Speed: \(loc.speed)m/s")
        } else {
            print("Current Location: nil")
        }
        print("Has Handled Permission Prompt: \(hasHandledPermissionPrompt)")
        print("Is Loading: \(isLoading)")
        print("Current Region Center: \(region.center)")
        print("Current Region Span: \(region.span)")
        print("Desired Accuracy: \(locationManager.desiredAccuracy)")
        print("Distance Filter: \(locationManager.distanceFilter)")
        print("==========================")
    }
    
    func requestFreshLocation() {
        print("Requesting fresh location update...")
        locationManager.requestLocation()
    }
    
    func forceCenterOnUserLocation() {
        guard let location = location else {
            print("No location available to center on")
            return
        }
        
        print("Forcing center on user location: \(location.coordinate)")
        setRegion(to: location.coordinate, animated: true)
        isFollowingUser = true
    }
    
    func startFollowingUser() {
        shouldFollowUser = true
        isFollowingUser = true
        if let location = location {
            setRegion(to: location.coordinate, animated: true)
        }
        print("Started following user location")
    }
    
    func stopFollowingUser() {
        shouldFollowUser = false
        isFollowingUser = false
        print("Stopped following user location")
    }
    
    func toggleLocationFollowing() {
        if isFollowingUser {
            stopFollowingUser()
        } else {
            startFollowingUser()
        }
    }
    
    func resetLocationPermissionState() {
        hasHandledPermissionPrompt = false
        authorizationStatus = .notDetermined
        print("Location permission state reset for testing")
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        
        // More lenient accuracy filtering for better responsiveness like web version
        guard newLocation.horizontalAccuracy <= 500 else {
            print("Ignoring inaccurate location: accuracy = \(newLocation.horizontalAccuracy)m")
            return
        }
        
        // Accept locations up to 2 minutes old for better coverage
        guard newLocation.timestamp.timeIntervalSinceNow > -120 else {
            print("Ignoring old location: age = \(abs(newLocation.timestamp.timeIntervalSinceNow))s")
            return
        }
        
        DispatchQueue.main.async {
            // Always update location for real-time tracking like web version
            let shouldUpdate = self.location == nil || 
                              newLocation.horizontalAccuracy < (self.location?.horizontalAccuracy ?? 999) ||
                              newLocation.distance(from: self.location ?? newLocation) > 5 // Update if moved more than 5m
            
            if shouldUpdate {
                print("Updating location: \(newLocation.coordinate) (accuracy: \(newLocation.horizontalAccuracy)m)")
                self.location = newLocation
                
                // Always center on user location when following is enabled
                if self.shouldFollowUser {
                    self.setRegion(to: newLocation.coordinate, animated: true)
                    self.isFollowingUser = true
                }
            }
            
            self.isLoading = false
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.isLoading = false
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
            print("Location authorization status changed to: \(status.rawValue)")
            
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                print("Location authorized")
            case .denied, .restricted:
                print("Location access denied or restricted")
                self.isLoading = false
            case .notDetermined:
                print("Location permission not determined - requesting again")
                // Try requesting permission again if not determined
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    if self.authorizationStatus == .notDetermined {
                        self.locationManager.requestWhenInUseAuthorization()
                    }
                }
            @unknown default:
                print("Unknown location authorization status")
            }
        }
    }
}
