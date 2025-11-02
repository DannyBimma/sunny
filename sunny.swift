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

    /// Convert (Degrees, Minutes, Seconds) back to decimal degrees
    func toDecimalDegrees() -> Double {
        let decimalMinutes = Double(minutes) / 60.0
        let decimalSeconds = Double(seconds) / 3600.0

        return Double(degrees) + decimalMinutes + decimalSeconds
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

    /// Move location north by specified distance in kilometers
    static func moveNorth(
        from location: (latitude: Coordinate, longitude: Coordinate), distanceKm: Double
    ) -> (latitude: Coordinate, longitude: Coordinate) {
        // Convert current coordinates to decimal degrees
        let currentLat = location.latitude.toDecimalDegrees()
        let currentLon = location.longitude.toDecimalDegrees()

        // Calculate new latitude
        // 1 degree of latitude ≈ 111 km
        let latitudeChange = distanceKm / 111.0
        let newLat = currentLat + latitudeChange

        // Longitude stays the same when moving straight north
        let newLatCoord = Coordinate.fromDecimalDegrees(newLat)
        let newLonCoord = Coordinate.fromDecimalDegrees(currentLon)

        return (latitude: newLatCoord, longitude: newLonCoord)
    }

    /// Move location south by specified distance in kilometers
    /// Returns new (latitude, longitude) coordinates
    static func moveSouth(
        from location: (latitude: Coordinate, longitude: Coordinate), distanceKm: Double
    ) -> (latitude: Coordinate, longitude: Coordinate) {
        // Convert current coordinates to decimal degrees
        let currentLat = location.latitude.toDecimalDegrees()
        let currentLon = location.longitude.toDecimalDegrees()

        // Calculate new latitude
        // 1 degree of latitude ≈ 111 km
        let latitudeChange = distanceKm / 111.0
        let newLat = currentLat - latitudeChange

        // Longitude stays the same when moving straight south
        let newLatCoord = Coordinate.fromDecimalDegrees(newLat)
        let newLonCoord = Coordinate.fromDecimalDegrees(currentLon)

        return (latitude: newLatCoord, longitude: newLonCoord)
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

struct CoupDeBurst {
    /// Execute the Coup De Burst maneuver
    static func execute(from location: (latitude: Coordinate, longitude: Coordinate)) -> (
        latitude: Coordinate, longitude: Coordinate
    ) {
        print("\n=== COUP DE BURST ACTIVATED ===")
        print("Releasing compressed air from stern...")
        print("BOOOOOOOOM!")
        print("The Thousand Sunny has been launched 1 kilometer north!\n")

        return Coordinate.moveNorth(from: location, distanceKm: 1.0)
    }
}

struct ChickenVoyage {
    /// Execute the Chicken Voyage maneuver
    static func execute(from location: (latitude: Coordinate, longitude: Coordinate)) -> (
        latitude: Coordinate, longitude: Coordinate
    ) {
        print("\n=== CHICKEN VOYAGE ACTIVATED ===")
        print("Tactical retreat engaged!")
        print("Releasing compressed air from bow...")
        print("WHOOOOOOSH!")
        print("The Thousand Sunny has retreated 1 kilometer south!\n")

        return Coordinate.moveSouth(from: location, distanceKm: 1.0)
    }
}

struct RabbitScrew {
    /// Propel the ship 5 degrees of latitude north at max speed
    static func sukuryū(from location: (latitude: Coordinate, longitude: Coordinate)) -> (
        latitude: Coordinate, longitude: Coordinate
    ) {
        print("\n=== RABBIT SCREW: SUKURYŪ ===")
        print(
            "Full power activated, Sunny now going all out… buckle up or huddle down, my Mugiwaras!"
        )
        print("The paddle wheels spin at maximum velocity!")
        print("VOOOOOOSSSHHHHH!")

        // Move 5 degrees of latitude north (5 degrees * 111 km/degree = 555 km)
        let newLocation = Coordinate.moveNorth(from: location, distanceKm: 555.0)

        print("\nNew Position after Sukuryū Propulsion:")
        print("  Latitude:  \(newLocation.latitude.formatted())")
        print("  Longitude: \(newLocation.longitude.formatted())")
        print()

        return newLocation
    }
}

struct GaonCannon {
    /// Fire the Gaon Cannon
    static func ガオン砲() {
        print("\n=== GAON CANNON ACTIVATED ===")

        print("AIR BLAST FIRED!!")
        print("TARGET SUCESSFULY OBLITERATED!!")
        print("\n⚠️  WARNING: Cola-Cannons depleted! Restock urgently!")

        print()
    }
}

// TEST: Get the user's real location and execute Coup De Burst
print("\n=== THE THOUSAND SUNNY'S CURRENT COORDINATES ===\n")
print("Fetching current location...")

if let location = Coordinate.getUserLocation() {
    print("Initial Position:")
    print("  Latitude:  \(location.latitude.formatted())")
    print("  Longitude: \(location.longitude.formatted())")

    // Activate Coup De Burst
    let newLocation = CoupDeBurst.execute(from: location)

    print("New Position (after Coup De Burst):")
    print("  Latitude:  \(newLocation.latitude.formatted())")
    print("  Longitude: \(newLocation.longitude.formatted())")

    // Activate Chicken Voyage
    let retreatLocation = ChickenVoyage.execute(from: newLocation)

    print("Final Position (after Chicken Voyage):")
    print("  Latitude:  \(retreatLocation.latitude.formatted())")
    print("  Longitude: \(retreatLocation.longitude.formatted())")

    // Activate Rabbit Screw Sukuryū
    _ = RabbitScrew.sukuryū(from: retreatLocation)
} else {
    print("Unable to determine current coordinates.")
}

// TEST: Fire the Gaon Cannon
print("\n=== WEAPONS TEST ===\n")
GaonCannon.ガオン砲()

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

    // Launch a vehicle from the dock
    func launch() {
        switch self {
        case .shiroMokuba:
            print("Launching Shiro Mokuba from Channel 1...")
            print("Nami's waver speeds across the water!")
        case .miniMerry:
            print("Launching the Mini Merry from Channel 2...")
            print("The mini shopping boat sets sail!")
        case .sharkSubmerge:
            print("Launching Shark Submerge from Channel 3...")
            print("Baby Meg dives beneath the waves!")
        case .kruosaiIV:
            print("Launching Kurosai IV from Channel 4...")
            print("The giant motorised rhinoceros roars to life!")
        case .brachioTankV:
            print("Launching Brachio Tank V from Channel 5...")
            print("The dinosaur tank rumbles forward with devastating power!")
        case .inflatablePool:
            print("Launching Inflatable Pool from Channel 6...")
            print("Suns out, buns out... but make sue Sanji is locked in!!")
        }
    }
}

enum Garden: Int {
    case sprinkler = 1
    case platanus_Shuriken
    case exploding_Pinecones
    case rafflesia
    case trampolia
    case humandrake
    case sleep_Grass
    case firework_Flowers
    case bamboo_Javelin
    case skull_Bomb_Grass
    case devil
    case impact_Wolf
    case boaty_Banana_Fan_Grass
    case sargasso

    // Output Pop Green info
    func displayInfo(for popGreen: Garden) {
        switch popGreen {
        case .sprinkler:
            print("#1 - Sprinkler:")
            print(
                "A plant that sprays water, useful for putting out fires or creating distractions.")
        case .platanus_Shuriken:
            print("#2 - Platanus Shuriken:")
            print("Sharp seed projectiles that can be thrown like shuriken for ranged attacks.")
        case .exploding_Pinecones:
            print("#3 - Exploding Pinecones:")
            print("Explosive pinecones that detonate on impact, causing significant damage.")
        case .rafflesia:
            print("#4 - Rafflesia:")
            print("A giant flower that releases a horrible stench to repel enemies.")
        case .trampolia:
            print("#5 - Trampolia:")
            print("A bouncy mushroom-like plant that can launch people or objects into the air.")
        case .humandrake:
            print("#6 - Humandrake:")
            print("A carnivorous plant that can grab and restrain enemies with its vines.")
        case .sleep_Grass:
            print("#7 - Sleep Grass:")
            print("Releases sleep-inducing spores that knock out anyone who inhales them.")
        case .firework_Flowers:
            print("#8 - Firework Flowers:")
            print("Flowers that burst into brilliant displays, useful for signals or distractions.")
        case .bamboo_Javelin:
            print("#9 - Bamboo Javelin:")
            print("Fast-growing bamboo that shoots out like a spear for piercing attacks.")
        case .skull_Bomb_Grass:
            print("#10 - Skull Bomb Grass:")
            print("A skull-shaped plant bomb with explosive capabilities.")
        case .devil:
            print("#11 - Devil:")
            print("A devilish plant with powerful offensive capabilities.")
        case .impact_Wolf:
            print("#12 - Impact Wolf:")
            print("Creates a wolf-shaped impact dial effect for devastating close-range attacks.")
        case .boaty_Banana_Fan_Grass:
            print("#13 - Boaty Banana Fan Grass:")
            print("A banana-shaped plant that can be used as a boat or flotation device.")
        case .sargasso:
            print("#14 - Sargasso:")
            print("Seaweed-like grass that can entangle and trap enemies.")
        }
    }
}

struct MikanGrove {
    /// Attempt to access Nami's precious mikan trees
    static func access() -> String {
        return "UNAUTHORISED ACCESS WARNING!! CONTACTING NAMI!!"
    }
}

struct FlowerBed {
    /// Attempt to access Robin's flower bed
    static func access() -> String {
        return "UNAUTHORISED ACCESS WARNING!! CONTACTING ROBIN!!"
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
print()

// TEST: Launch vehicles from Soldier Dock
print("\n=== LAUNCHING VEHICLES ===\n")

dock3.launch()
print()

dock5.launch()
print()

// TEST: Display Pop Green info from Usopp's Garden
print("\n=== USOPP'S GARDEN - POP GREEN INVENTORY ===\n")

let popGreen1 = Garden.rafflesia
popGreen1.displayInfo(for: .rafflesia)
print()

let popGreen2 = Garden.impact_Wolf
popGreen2.displayInfo(for: .impact_Wolf)
print()

let popGreen3 = Garden.trampolia
popGreen3.displayInfo(for: .trampolia)
print()

// TEST: Try to access protected gardens
print("\n=== RESTRICTED AREAS ===\n")

print("Attempting to pick mikans...")
print(MikanGrove.access())
print()

print("Attempting to visit flower bed...")
print(FlowerBed.access())
print()
