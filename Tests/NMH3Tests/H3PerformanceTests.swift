import XCTest
@testable import NMH3
import CoreLocation

final class H3PerformanceTests: XCTestCase {

    /// Measure Coordinate → H3 indexing speed (real H3 icosahedron math).
    func testGeoToH3Performance() {
        let coord = CLLocationCoordinate2D(latitude: 40.3893, longitude: 49.8529)
        measure {
            for _ in 0..<10_000 {
                _ = NMH3Kit.shared.cell(for: coord, resolution: .r9)
            }
        }
    }

    /// Measure k-ring generation speed (real BFS-based gridDisk).
    func testKRingPerformance() {
        let cell = NMH3Kit.shared.cell(for: CLLocationCoordinate2D(latitude: 40.3893, longitude: 49.8529), resolution: .r9)
        measure {
            for _ in 0..<1_000 {
                _ = NMH3Kit.shared.kRing(around: cell, k: 5)
            }
        }
    }

    /// Measure compaction speed.
    func testCompactPerformance() {
        let origin = NMH3Kit.shared.cell(for: CLLocationCoordinate2D(latitude: 40, longitude: 49), resolution: .r9)
        let cells = Array(NMH3Kit.shared.kRing(around: origin, k: 5))
        measure {
            _ = NMH3Kit.shared.compact(cells)
        }
    }

    /// Measure polyfill speed for a moderate-sized polygon.
    func testPolyfillPerformance() {
        let polygon = [
            CLLocationCoordinate2D(latitude: 40.35, longitude: 49.80),
            CLLocationCoordinate2D(latitude: 40.45, longitude: 49.80),
            CLLocationCoordinate2D(latitude: 40.45, longitude: 49.90),
            CLLocationCoordinate2D(latitude: 40.35, longitude: 49.90),
        ]
        measure {
            _ = NMH3Kit.shared.polyfill(polygon: polygon, resolution: .r8)
        }
    }
}
