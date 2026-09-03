# NMH3

> [!NOTE]
> **Backend Compatibility:** Output H3 indices are bit-for-bit compatible with Uber's canonical H3 format (v4.x). Indices produced by this library can be consumed directly by `h3-go`, `h3-pg`, `h3-js`, and any other standard H3 implementation.

**NMH3** is a Swift Package providing a high-performance implementation of Uber's [H3 Geospatial Indexing System](https://h3geo.org/) for iOS and macOS.

The package uses a vendored build of Uber's official open-source [H3 C core](https://github.com/uber/h3) (v4.1.0, Apache-2.0) as the `NMCH3` target, wrapped by a modern Swift 6–compatible API. This means all H3 indices are canonical, spec-compliant, and fully interoperable with any standard H3 backend.

## 🏗 Architecture

The package is divided into two targets:

*   **`NMCH3` (C + Objective-C):**
    *   Vendors the official Uber H3 C library (v4.1.0).
    *   Thin Objective-C wrappers expose the C functions to Swift.
    *   Handles: icosahedron projections, base-cell mapping, hex boundary calculations, hierarchical indexing, k-ring traversal, polyfill, grid distance, and compact/uncompact.

*   **`NMH3` (Swift Public API):**
    *   Modern developer experience using Combine.
    *   MapKit integration for visualisation.
    *   Mobile layer: battery-aware GPS scaling, motion-aware location tracking, and dynamic geofencing (overcomes iOS's 20-region limit via rotation).

---

## 🚀 Installation

```swift
dependencies: [
    .package(url: "https://github.com/14cvd/NMH3.git", from: "1.0.0")
],
targets: [
    .target(name: "YourFeatureModule", dependencies: ["NMH3"])
]
```

---

## 📖 Key Features & Usage

### 1. Spatial Encoding and Decoding

```swift
import CoreLocation
import NMH3

let coordinate = CLLocationCoordinate2D(latitude: 40.3893, longitude: 49.8529)

// Encode coordinate to H3 Cell at resolution 9
let cell = NMH3Kit.shared.cell(for: coordinate, resolution: .r9)
print("H3 Index: \(cell.string)")  // e.g. "8944c0b5153ffff"

// Decode Cell back to center coordinate
let center = NMH3Kit.shared.center(of: cell)

// Get hexagon boundary vertices (6 for hex, 5 for pentagon)
let boundary = NMH3Kit.shared.boundary(of: cell)
```

### 2. Privacy-Aware Location Tracking

`NMH3LocationManager` converts raw `CLLocation` updates to H3 cell indices immediately, without retaining the coordinate in any property. It dynamically adjusts GPS accuracy and distance filter based on resolution.

```swift
import Combine
import NMH3

let locationManager = NMH3LocationManager()
locationManager.resolution = .r9  // ~0.1 km² hex cells

locationManager.currentCellPublisher
    .sink { cell in print("User entered: \(cell.string)") }
    .store(in: &cancellables)

locationManager.start()
```

> **Note on "Zero-Retention":** `CLLocationCoordinate2D` is a Swift value type. It is not possible to scrub the original `CLLocation` object from memory by zeroing a local copy. The privacy guarantee here is narrower but real: the raw coordinate is never stored in any property, logged, or persisted — only the H3 cell index is published.

### 3. Battery-Aware Tracking

`NMH3BatteryOptimizer` monitors battery level and motion state, publishing a `BatteryProfile`. `NMH3LocationManager` subscribes to it and adjusts `desiredAccuracy` and `distanceFilter` automatically:

| Profile | Level | `desiredAccuracy` | `distanceFilter` |
|---|---|---|---|
| `.ultraLow` | <20% | `kCLLocationAccuracyKilometer` | 500 m |
| `.low` | 20–40% | `kCLLocationAccuracyHundredMeters` | 200 m |
| `.balanced` | 40–80% | Resolution-appropriate | Resolution-appropriate |
| `.high` | >80% | `kCLLocationAccuracyBestForNavigation` | ≥10 m |

When the device is stationary (via `CMMotionActivityManager`), the distance filter is raised further to suppress redundant wake-ups.

```swift
let optimizer = NMH3BatteryOptimizer()
let locationManager = NMH3LocationManager(batteryOptimizer: optimizer)
locationManager.start()
```

### 4. Dynamic Geofencing (iOS 20-Region Limit Workaround)

`NMH3GeofenceManager` overcomes iOS's 20 simultaneous monitored region limit by rotating the active set as the user moves. It subscribes to `NMH3LocationManager.currentCellPublisher` and uses `gridDisk` to find the nearest target cells, swapping far regions out and nearby ones in.

```swift
let locationManager = NMH3LocationManager()
let geofenceManager = NMH3GeofenceManager()
let targetCells: [H3Cell] = [/* store locations etc. */]

geofenceManager.monitorCells(targetCells, trackingWith: locationManager) { cell in
    print("Entered zone: \(cell.string)")
} onExit: { cell in
    print("Left zone: \(cell.string)")
}

locationManager.start()
```

### 5. Traversal & Hierarchy

```swift
let kit = NMH3Kit.shared

// Neighbours (k-ring disk, k=1 → 7 cells for a hexagon)
let neighbors = kit.kRing(around: cell, k: 1)

// Exact ring at distance k (6*k cells for a hexagon)
let ring = kit.hexRing(around: cell, k: 2)

// Grid distance between two cells
let dist = kit.distance(from: cellA, to: cellB)

// Shortest path through cells
let path = kit.line(from: cellA, to: cellB)

// Hierarchical parent/child
let parent = cell.parent(at: .r8)       // coarser cell
let children = parent.children(at: .r9) // 7 children (or 6 for a pentagon)

// Compact a set of cells (group uniform children into parents)
let compacted = kit.compact(manyCells)
let restored  = kit.uncompact(compacted, to: .r9)

// Fill a polygon with cells
let cells = kit.polyfill(polygon: coordinates, resolution: .r8)
```

### 6. Security

```swift
// Asymmetric encryption (ECIES: ephemeral P-256 + HKDF-SHA256 + AES-GCM)
let encryptor = NMH3Encryptor()
let envelope = try encryptor.encrypt(cell.index, publicKey: recipientPublicKey)

// Symmetric encryption (AES-GCM)
let sealed = try encryptor.seal(cell.index, symmetricKey: myKey)

// Jailbreak detection (best-effort heuristic — see API docs for caveats)
let isCompromised = NMH3JailbreakDetector().isCompromised()

// Privacy fuzzing: shift index by a random neighbour offset before analytics
let fuzzed = NMH3PrivacyLayer().obfuscatedIndex(cell.index, fuzz: 1)
```

---

## 🔒 Security Notes

1.  **Privacy:** Raw `CLLocationCoordinate2D` values are never stored in properties or logged — only H3 cell indices are retained. However, true memory scrubbing of Apple framework objects is not achievable via Swift value-type semantics.
2.  **Encryption:** `NMH3Encryptor.encrypt(_:publicKey:)` implements real ECIES (ephemeral ECDH + HKDF-SHA256 + AES-GCM). `seal(_:symmetricKey:)` uses AES-GCM directly.
3.  **Jailbreak detection:** `NMH3JailbreakDetector.isCompromised()` is a **best-effort heuristic** that checks static file paths and sandbox write access. It is bypassable by path-hiding tweaks and must not be used as a sole security gate. Combine with server-side checks and certificate pinning.
4.  **Backend interop:** H3 indices are canonical (bit-for-bit compatible with `h3-go`, `h3-pg`, `h3-js`, etc.).
