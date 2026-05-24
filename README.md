# NMH3

**NMH3** is a production-ready Swift Package providing a high-performance, privacy-first implementation of Uber's [H3 Geospatial Indexing System](https://h3geo.org/) for iOS and macOS.

This package is fully self-contained with no external dependencies. It features a highly optimized pure Objective-C/C core (`NMCH3`) wrapped in a modern, Swift 6 compatible, actor-isolated public API (`NMH3`).

## 🏗 Architecture

The package is divided into two distinct targets to maximize performance and interoperability:

*   **`NMCH3` (Objective-C Core):**
    *   Handles low-level mathematical operations: Icosahedron projections, base cell mapping, and hex boundary calculations.
    *   Optimized for zero heap allocations in performance-critical paths.
    *   Exposes a C-compatible interface for maximum speed.

*   **`NMH3` (Swift Public API):**
    *   Provides a modern developer experience using Swift Concurrency (async/await) and Combine.
    *   Integrates with MapKit for easy visualization.
    *   Implements a dedicated mobile layer for battery-efficient location tracking and dynamic geofencing.

---

## 🚀 Installation

Add NMH3 as a local dependency in your `Package.swift` or Xcode Project:

```swift
dependencies: [
    .package(path: "https://github.com/14cvd/NMH3.git")
    
],
targets: [
    .target(
        name: "YourFeatureModule",
        dependencies: ["NMH3"]
    )
]
```

---

## 📖 Key Features & Usage

### 1. Spatial Encoding and Decoding
Convert standard coordinates into H3 hexagonal indices and vice versa.

```swift
import CoreLocation
import NMH3

let coordinate = CLLocationCoordinate2D(latitude: 40.3893, longitude: 49.8529)

// 1. Encode coordinate to H3 Cell at resolution 9
let cell = NMH3Kit.shared.cell(for: coordinate, resolution: .r9)
print("H3 Index (Hex String): \(cell.string)")

// 2. Decode Cell back to center coordinate
let center = NMH3Kit.shared.center(of: cell)

// 3. Get precise hexagon boundary vertices
let boundary = NMH3Kit.shared.boundary(of: cell)
```

### 2. Privacy-First Location Tracking
`NMH3LocationManager` ensures that raw GPS coordinates never linger in memory. It immediately converts `CLLocation` objects into `H3Cell` indices and scrubs the original data.

```swift
import Combine
import NMH3

let locationManager = NMH3LocationManager()
locationManager.resolution = .r9 // Hex size (~0.1 km²)

locationManager.currentCellPublisher
    .sink { cell in
        print("User entered new hex: \(cell.string)")
    }
    .store(in: &cancellables)

locationManager.start()
```

### 3. Dynamic Geofencing (iOS Region Limit Workaround)
iOS natively limits apps to monitoring 20 `CLCircularRegion`s at once. `NMH3GeofenceManager` overcomes this by dynamically rotating monitored regions based on the user's surrounding H3 cells.

```swift
let geofenceManager = NMH3GeofenceManager()
let targetCells: [H3Cell] = [/* List of store location cells */]

geofenceManager.monitorCells(targetCells) { cell in
    print("Welcome! You entered store zone: \(cell.string)")
} onExit: { cell in
    print("You left the zone.")
}
```

### 4. Battery & Security
*   **Battery Optimization:** `NMH3BatteryOptimizer` automatically scales GPS precision based on battery level and device motion.
*   **Jailbreak Detection:** `NMH3JailbreakDetector` identifies compromised environments to prevent location spoofing.
*   **Encryption:** `NMH3Encryptor` provides CryptoKit-based sealing of H3 indices before network transmission.

### 5. MapKit Extensions
Easily visualize H3 cells on an `MKMapView`.

```swift
import MapKit
import NMH3

let mapView = MKMapView()
let cell = NMH3Kit.shared.cell(for: someCoord, resolution: .r9)

// Draw cell boundary on map
let overlay = mapView.addH3Cell(cell, color: .blue.withAlphaComponent(0.2))
```

---

## 🔒 Security Mandates
1.  **Zero-Retention:** Raw `CLLocationCoordinate2D` data must be zeroed immediately after conversion.
2.  **No Persistence:** H3 indices should be treated as ephemeral unless explicitly encrypted.
3.  **Anonymity:** Use `NMH3PrivacyLayer.obfuscatedIndex()` to shift indices by a neighbor offset before sending data to analytics.
