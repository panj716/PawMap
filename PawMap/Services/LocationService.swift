import Foundation
import CoreLocation
import Combine

/// Service for handling location services with Firebase integration
class LocationService: NSObject, ObservableObject {
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    
    // Default location (Ann Arbor, Michigan)
    static let defaultLocation = CLLocation(latitude: 42.2464, longitude: -83.7417)
    static let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 42.2464, longitude: -83.7417),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update every 10 meters
    }
    
    func requestLocationPermission() {
        guard authorizationStatus == .notDetermined else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func startLocationUpdates() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            print("Location permission not granted")
            return
        }
        
        guard CLLocationManager.locationServicesEnabled() else {
            print("Location services not enabled")
            return
        }
        
        print("Starting location updates...")
        locationManager.startUpdatingLocation()
        locationManager.requestLocation() // Request immediate location
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }
    
    func getCurrentLocation() -> CLLocation? {
        return location ?? Self.defaultLocation
    }
    
    func getCurrentRegion() -> MKCoordinateRegion {
        if let location = location {
            return MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
        return Self.defaultRegion
    }
    
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        
        DispatchQueue.main.async {
            self.location = newLocation
            self.isLoading = false
            print("Location updated: \(newLocation.coordinate)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
            print("Location error: \(error.localizedDescription)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
            print("Location authorization changed to: \(status.rawValue)")
            
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.startLocationUpdates()
            case .denied, .restricted:
                self.errorMessage = "Location access denied. Please enable location services in Settings."
            case .notDetermined:
                // Will be handled by requestLocationPermission
                break
            @unknown default:
                break
            }
        }
    }
}

// MARK: - MapKit Imports

import MapKit

