import Foundation
import CoreLocation

/// GPS rangefinder service using Core Location for distance calculations.
final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationService()

    private let manager = CLLocationManager()

    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var distanceToGreen: Int?

    private var greenLocation: CLLocation?

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 2 // update every 2 meters
        manager.activityType = .fitness
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func startTracking() {
        manager.startUpdatingLocation()
    }

    func stopTracking() {
        manager.stopUpdatingLocation()
    }

    func setGreenLocation(latitude: Double, longitude: Double) {
        greenLocation = CLLocation(latitude: latitude, longitude: longitude)
        updateDistanceToGreen()
    }

    func distanceTo(latitude: Double, longitude: Double) -> Int? {
        guard let current = currentLocation else { return nil }
        let target = CLLocation(latitude: latitude, longitude: longitude)
        let meters = current.distance(from: target)
        return Int(meters * 1.09361) // convert to yards
    }

    private func updateDistanceToGreen() {
        guard let current = currentLocation, let green = greenLocation else {
            distanceToGreen = nil
            return
        }
        let meters = current.distance(from: green)
        distanceToGreen = Int(meters * 1.09361)
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
        updateDistanceToGreen()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }
}
