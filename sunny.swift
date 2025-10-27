/*
Routine: A Simulation of the tech on-board the Thousand Sunny pirate ship,
from the One Piece manga and anime.
Author: Danny Bimma
Date: 2025-10-24
Copyright: 2025 Technomancer Pirate Captain
*/

import CoreLocation
import Foundation

// Create a struct to represent The Sunny's coordinates
struct Coordinate {
    let degrees: Int
    let minutes: Int
    let seconds: Int

    /// Format the coordinate as a string
    func formatted() -> String {
        return "\(degrees)° \(minutes)'\(seconds)\""
    }

    /// Get user's real location coordinates
    static func getUserLocation() -> (latitude: Coordinate, longitude: Coordinate)? {
        let locator = LocationFetcher()

        return locator.fetchCurrentLocation()
    }

    /// Convert decimal degrees to (Degrees, Minutes, Seconds)
    static func fromDecimalDegrees(_ decimal: Double) -> Coordinate {
        let absolute = abs(decimal)
        let degrees = Int(absolute)
        let minutesDecimal = (absolute - Double(degrees)) * 60
        let minutes = Int(minutesDecimal)
        let seconds = Int((minutesDecimal - Double(minutes)) * 60)

        return Coordinate(degrees: degrees, minutes: minutes, seconds: seconds)
    }
}

// Create a class to fetch location using CoreLocation
class LocationFetcher: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?
    private let semaphore = DispatchSemaphore(value: 0)

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func fetchCurrentLocation() -> (latitude: Coordinate, longitude: Coordinate)? {
        // Request location authorisation
        locationManager.requestWhenInUseAuthorization()

        // Request a single location update
        locationManager.requestLocation()

        // Wait for location (with timeout)
        let timeout = DispatchTime.now() + .seconds(10)
        let result = semaphore.wait(timeout: timeout)

        guard result == .success, let location = currentLocation else {
            print(
                "Coordinates are unknown and mysterious. Make sure location services are enabled.")

            return nil
        }

        // Convert to Coordinate format
        let latCoord = Coordinate.fromDecimalDegrees(location.coordinate.latitude)
        let lonCoord = Coordinate.fromDecimalDegrees(location.coordinate.longitude)

        return (latitude: latCoord, longitude: lonCoord)
    }

    // CLLocationManagerDelegate methods
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            currentLocation = location
            semaphore.signal()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
        semaphore.signal()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            print("Location access denied. Please enable location services in System Preferences.")
            semaphore.signal()
        default:
            break
        }
    }
}

// Create an enum for the Soldier Dock System
enum SoldierDock: Int {
    // Dock contents
    case shiroMokuba = 1
    case miniMerry
    case sharkSubmerge
    case kruosaiIV
    case brachioTankV
    case inflatablePool

    // Show info about a specific dock channels
    func displayInfo(for dock: SoldierDock) {
        switch dock {
        case .shiroMokuba:
            print("Channel 1 - Shiro Mokuba:")
            print(
                "Waver owned by Nami, in the shape of a white horse. Orginally salvaged from a shipwreck in Jaya."
            )
        case .miniMerry:
            print("Channel 2 - Mini Merry:")
            print(
                "Small 4-person boat resembling the Going Merry. Built by Franky at Nami's request, for the exlusive use of shopping."
            )
        case .sharkSubmerge:
            print("Channel 3 - Shark Submerge:")
            print("3-person submersible shaped like a shark.")
        case .kruosaiIV:
            print("Channel 4 - Kurosai IV:")
            print(
                "Giant black motorcycle with 3-wheels and the head of a Rhinoceros. Built by Franky for unknown reasons."
            )
        case .brachioTankV:
            print("Channel 5 - Brachio Tank V:")
            print("Giant tank shaped like a Brachiosaurus. Built by Franky for obvious reasons.")
        case .inflatablePool:
            print("Channel 6 - Inflatable Pool:")
            print("Large inflatable pool for relaxation purposes.")
        }
    }
}

// TEST: Display info for each dock
print("=== THOUSAND SUNNY SOLDIER DOCK SYSTEM ===\n")

let dock1 = SoldierDock.shiroMokuba
dock1.displayInfo(for: .shiroMokuba)
print()

let dock2 = SoldierDock.miniMerry
dock2.displayInfo(for: .miniMerry)
print()

let dock3 = SoldierDock.sharkSubmerge
dock3.displayInfo(for: .sharkSubmerge)
print()

let dock4 = SoldierDock.kruosaiIV
dock4.displayInfo(for: .kruosaiIV)
print()

let dock5 = SoldierDock.brachioTankV
dock5.displayInfo(for: .brachioTankV)
print()

let dock6 = SoldierDock.inflatablePool
dock6.displayInfo(for: .inflatablePool)
