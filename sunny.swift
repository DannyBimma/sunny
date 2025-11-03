/*
Routine: A Simulation of the tech on-board the Thousand Sunny pirate ship,
from the One Piece manga and anime.
Author: Danny Bimma
Date: 2025-10-24
Copyright: 2025 Technomancer Pirate Captain
*/

import CoreLocation
import Foundation

/// Create an enum to represent the axis of a coordinate
/// (latitude or longitude)
enum Axis { case latitude, longitude }

// Create a struct to represent The Sunny's coordinates
struct Coordinate {
    let degrees: Int
    let minutes: Int
    let seconds: Int
    let isNegative: Bool

    /// Format coordinates with hemisphere (N/S/E/W)
    func hemiFormat(as axis: Axis) -> String {
        let hemi: String
        switch axis {
        case .latitude: hemi = isNegative ? "S" : "N"
        case .longitude: hemi = isNegative ? "W" : "E"
        }

        return "\(degrees)° \(minutes)'\(seconds)\" \(hemi)"
    }

    /// Convert (Degrees, Minutes, Seconds) back to decimal degrees
    func toDecimalDegrees() -> Double {
        let decimalMinutes = Double(minutes) / 60.0
        let decimalSeconds = Double(seconds) / 3600.0
        let magnitude = Double(degrees) + decimalMinutes + decimalSeconds

        return isNegative ? -magnitude : magnitude
    }

    /// Get user's real location coordinates
    static func getUserLocation() -> (latitude: Coordinate, longitude: Coordinate)? {
        let locator = LocationFetcher()

        return locator.fetchCurrentLocation()
    }

    /// Convert decimal degrees back to DMS
    static func fromDecimalDegrees(_ decimal: Double) -> Coordinate {
        let negative = decimal < 0
        let absolute = abs(decimal)
        let degrees = Int(absolute)
        let minutesDecimal = (absolute - Double(degrees)) * 60
        let minutes = Int(minutesDecimal)
        let seconds = Int((minutesDecimal - Double(minutes)) * 60)

        return Coordinate(
            degrees: degrees, minutes: minutes, seconds: seconds, isNegative: negative)
    }

    /// Move north by specified distance in km
    static func moveNorth(
        from location: (latitude: Coordinate, longitude: Coordinate), distanceKm: Double
    ) -> (latitude: Coordinate, longitude: Coordinate) {
        // Convert current coordinates to decimal degrees
        let currentLat = location.latitude.toDecimalDegrees()
        let currentLon = location.longitude.toDecimalDegrees()

        /// Calc new latitude
        /// 1 degree of latitude ≈ 111 km
        let latitudeChange = distanceKm / 111.0
        let newLat = currentLat + latitudeChange

        /// Longitude stays the same when moving straight north
        let newLatCoord = Coordinate.fromDecimalDegrees(newLat)
        let newLonCoord = Coordinate.fromDecimalDegrees(currentLon)

        return (latitude: newLatCoord, longitude: newLonCoord)
    }

    /// Move location south by specified distance in km
    static func moveSouth(
        from location: (latitude: Coordinate, longitude: Coordinate), distanceKm: Double
    ) -> (latitude: Coordinate, longitude: Coordinate) {
        /// Convert current coordinates to decimal degrees
        let currentLat = location.latitude.toDecimalDegrees()
        let currentLon = location.longitude.toDecimalDegrees()

        /// Calc new latitude
        /// 1 degree of latitude ≈ 111 km
        let latitudeChange = distanceKm / 111.0
        let newLat = currentLat - latitudeChange

        /// Longitude stays the same when moving straight south
        let newLatCoord = Coordinate.fromDecimalDegrees(newLat)
        let newLonCoord = Coordinate.fromDecimalDegrees(currentLon)

        return (latitude: newLatCoord, longitude: newLonCoord)
    }
}

/// Create a class to fetch location using CoreLocation
class LocationFetcher: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?
    private var isAuthorized: Bool {
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return true
        default:
            return false
        }
    }

    override init() {
        super.init()
        locationManager.delegate = self
        /// For accuracy on Mac (Wi‑Fi based positioning)
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }

    func fetchCurrentLocation() -> (latitude: Coordinate, longitude: Coordinate)? {
        /// Ensure Location Services are enabled globally
        guard CLLocationManager.locationServicesEnabled() else {
            print(
                "ERROR: Location Services may be disabled: \n System Settings > Privacy & Security > Location Services."
            )

            return nil
        }

        /// Request location auth (if needed wait briefly for response)
        if locationManager.authorizationStatus == .notDetermined {
            #if os(macOS)
                locationManager.requestAlwaysAuthorization()
            #else
                locationManager.requestWhenInUseAuthorization()
            #endif
            let authDeadline = Date().addingTimeInterval(8)
            while locationManager.authorizationStatus == .notDetermined && Date() < authDeadline {
                RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.1))
            }
        }

        /// Show help message if denied or restricted
        switch locationManager.authorizationStatus {
        case .denied, .restricted:
            print(
                "Location access denied/restricted. Enable it for 'sunny' in System Settings > Privacy & Security > Location Services."
            )
            return nil
        default:
            break
        }

        /// Start location updates (more reliable for CLI apps)
        locationManager.startUpdatingLocation()

        /// Pump run loop so CoreLocation can deliver delegate callbacks.
        let timeoutDate = Date().addingTimeInterval(12)
        while currentLocation == nil && Date() < timeoutDate {
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.1))
        }

        guard let location = currentLocation else {
            print(
                "Coordinates are unknown and mysterious. Make sure location services are enabled.")

            return nil
        }

        /// Stop updates once a fix is obtained
        locationManager.stopUpdatingLocation()

        /// Convert to Coordinate format
        let latCoord = Coordinate.fromDecimalDegrees(location.coordinate.latitude)
        let lonCoord = Coordinate.fromDecimalDegrees(location.coordinate.longitude)

        return (latitude: latCoord, longitude: lonCoord)
    }

    /// CLLocationManagerDelegate methods
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            currentLocation = location
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let nsError = error as NSError
        print(
            "Location error: domain=\(nsError.domain) code=\(nsError.code) desc=\(nsError.localizedDescription)"
        )
    }

    func locationManagerAuthChanged(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .notDetermined:
            #if os(macOS)
                manager.requestAlwaysAuthorization()
            #else
                manager.requestWhenInUseAuthorization()
            #endif
        case .authorizedAlways, .authorizedWhenInUse:
            /// If auth was granted after our initial request, start updates
            manager.startUpdatingLocation()
        case .denied, .restricted:
            print("Location access denied. Please enable location services in System Settings.")
        @unknown default:
            break
        }
    }
}

struct CoupDeBurst {
    /// Execute the Coup De Burst maneuver
    static func execute(
        from location: (latitude: Coordinate, longitude: Coordinate), distanceKm: Double
    ) -> (latitude: Coordinate, longitude: Coordinate) {
        print("\n=== COUP DE BURST ACTIVATED ===")
        print("Releasing compressed air from stern...")
        print("BOOOOOOOOM!")

        let distStr = String(format: "%.0f", distanceKm)

        print("The Thousand Sunny has been launched \(distStr) kilometer(s) north!\n")

        return Coordinate.moveNorth(from: location, distanceKm: distanceKm)
    }
}

struct ChickenVoyage {
    /// Execute the Chicken Voyage escape
    static func execute(
        from location: (latitude: Coordinate, longitude: Coordinate), distanceKm: Double
    ) -> (latitude: Coordinate, longitude: Coordinate) {
        print("\n=== CHICKEN VOYAGE ACTIVATED ===")
        print("Tactical retreat engaged!")
        print("Releasing compressed air from bow...")
        print("WHOOOOOOSH!")

        let distStr = String(format: "%.0f", distanceKm)

        print("The Thousand Sunny has retreated \(distStr) kilometer(s) south!\n")

        return Coordinate.moveSouth(from: location, distanceKm: distanceKm)
    }
}

struct RabbitScrew {
    /// Execute the Rabbit Screw
    static func sukuryū(
        from location: (latitude: Coordinate, longitude: Coordinate), distanceKm: Double
    ) -> (latitude: Coordinate, longitude: Coordinate) {
        print("\n=== RABBIT SCREW: SUKURYŪ ===")
        print(
            "Full power activated, Sunny now going all out… buckle up or huddle down, my Mugiwaras!"
        )
        print("The paddle wheels spin at maximum velocity!")
        print("VOOOOOOSSSHHHHH!")

        let distStr = String(format: "%.0f", distanceKm)

        print("The Sunny surges ahead by \(distStr) kilometer(s)!\n")

        let newLocation = Coordinate.moveNorth(from: location, distanceKm: distanceKm)

        print("New Position after Sukuryū Propulsion:")
        print("  Latitude:  \(newLocation.latitude.hemiFormat(as: .latitude))")
        print("  Longitude: \(newLocation.longitude.hemiFormat(as: .longitude))")
        print()

        return newLocation
    }
}

struct GaonCannon {
    /// Fire the Gaon Cannon
    static func ガオン砲(power: Int) {
        print("\n=== GAON CANNON ACTIVATED ===")
        print("Power level: \(power)")

        for _ in 0..<max(1, power) {
            print("AIR BLAST FIRED!!")
        }

        print("TARGET SUCESSFULY OBLITERATED!!")
        print("\n⚠️  WARNING: Cola-Cannons depleted! Restock urgently!")
        print()
    }
}

enum SoldierDock: Int {
    /// Contents of the Soldier Dock System
    case shiroMokuba = 1
    case miniMerry
    case sharkSubmerge
    case kruosaiIV
    case brachioTankV
    case inflatablePool

    /// Output info about specific dock channels
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

    /// Launch a vehicle from the dock
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
    /// The contents of the Usopp's Pop Greens Garden
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

    /// Output Pop Green info
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

// App entry point (no args)
func printUsage() {
    print("Usage: sunny <system> <number>")
    print("Systems:")
    print("  coupe <km>      - COUP DE BURST: move north by <km> km")
    print("  chicken <km>    - CHICKEN VOYAGE: move south by <km> km")
    print("  rabbit <km>     - RABBIT SCREW: move north by <km> km")
    print("  cannon <power>  - GAON CANNON: fire with power level")
    print("  dock <1-6>      - SOLDIER DOCK SYSTEM: describe + launch vehicle")
    print("  garden <1-14>   - USOPP'S GARDEN: show Pop Green info")
    print("  mikan <n>       - NAMI’S GARDEN: access warning (number ignored)")
    print("  fluer <n>       - ROBIN’S FLOWERS: access warning (number ignored)")
}

// App entry point (with args)
let args = CommandLine.arguments
if args.count == 1 {
    print("\n=== THE THOUSAND SUNNY'S CURRENT COORDINATES ===\n")
    print("Fetching current location...")

    if let loc = Coordinate.getUserLocation() {
        print("  Latitude:  \(loc.latitude.hemiFormat(as: .latitude))")
        print("  Longitude: \(loc.longitude.hemiFormat(as: .longitude))")
    } else {
        print("Unable to determine current coordinates.")
    }

    print("\nTip: run with arguments, e.g.\n  sunny coupe 2\n  sunny dock 3\n")
    printUsage()
} else {
    let cmd = args[1].lowercased()

    if args.count < 3 {
        print("Missing number argument.\n")
        printUsage()

        exit(1)
    }

    let numberStr = args[2]
    let numberDouble = Double(numberStr)
    let numberInt = Int(numberStr)

    switch cmd {
    case "coupe":
        guard let km = numberDouble, km >= 0 else {
            print("Invalid km: \(numberStr)")

            exit(1)
        }
        if let start = Coordinate.getUserLocation() {
            print("Initial Position:")
            print("  Latitude:  \(start.latitude.hemiFormat(as: .latitude))")
            print("  Longitude: \(start.longitude.hemiFormat(as: .longitude))")

            let end = CoupDeBurst.execute(from: start, distanceKm: km)

            print("New Position:")
            print("  Latitude:  \(end.latitude.hemiFormat(as: .latitude))")
            print("  Longitude: \(end.longitude.hemiFormat(as: .longitude))")
        } else {
            print("Unable to determine current coordinates.")
        }

    case "chicken":
        guard let km = numberDouble, km >= 0 else {
            print("Invalid km: \(numberStr)")

            exit(1)
        }
        if let start = Coordinate.getUserLocation() {
            print("Initial Position:")
            print("  Latitude:  \(start.latitude.hemiFormat(as: .latitude))")
            print("  Longitude: \(start.longitude.hemiFormat(as: .longitude))")

            let end = ChickenVoyage.execute(from: start, distanceKm: km)

            print("New Position:")
            print("  Latitude:  \(end.latitude.hemiFormat(as: .latitude))")
            print("  Longitude: \(end.longitude.hemiFormat(as: .longitude))")
        } else {
            print("Unable to determine current coordinates.")
        }

    case "rabbit":
        guard let km = numberDouble, km >= 0 else {
            print("Invalid km: \(numberStr)")

            exit(1)
        }
        if let start = Coordinate.getUserLocation() {
            let _ = RabbitScrew.sukuryū(from: start, distanceKm: km)
        } else {
            print("Unable to determine current coordinates.")
        }

    case "cannon":
        guard let power = numberInt, power >= 0 else {
            print("Invalid power: \(numberStr)")

            exit(1)
        }
        GaonCannon.ガオン砲(power: power)

    case "dock":
        guard let idx = numberInt, let dock = SoldierDock(rawValue: idx) else {
            print("Invalid dock number: \(numberStr). Use 1-6.")

            exit(1)
        }
        dock.displayInfo(for: dock)
        dock.launch()

    case "garden":
        guard let idx = numberInt, let pg = Garden(rawValue: idx) else {
            print("Invalid Pop Green number: \(numberStr). Use 1-14.")

            exit(1)
        }
        pg.displayInfo(for: pg)

    case "mikan":
        print(MikanGrove.access())

    case "fluer":
        print(FlowerBed.access())

    default:
        print("Unknown system: \(cmd)\n")
        printUsage()

        exit(1)
    }
}
