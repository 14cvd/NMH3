import XCTest
@testable import NMH3
import CoreLocation

final class H3PerformanceTests: XCTestCase {
    
    /// Measure Coordinate to H3 indexing speed
    func testGeoToH3Performance() {
        let coord = CLLocationCoordinate2D(latitude: 40.3893, longitude: 49.8529)
        measure {
            for _ in 0..<10000 {
                _ = NMH3Kit.shared.cell(for: coord, resolution: .r9)
            }
        }
    }
    
    /// Measure k-ring generation speed
    func testKRingPerformance() {
        let cell = NMH3Kit.shared.cell(for: CLLocationCoordinate2D(latitude: 40.3893, longitude: 49.8529), resolution: .r9)
        measure {
            for _ in 0..<1000 {
                _ = NMH3Kit.shared.kRing(around: cell, k: 5)
            }
        }
    }
    
    /// Measure compacting performance
    func testCompactPerformance() {
        let origin = NMH3Kit.shared.cell(for: CLLocationCoordinate2D(latitude: 40, longitude: 49), resolution: .r9)
        let cells = NMH3Kit.shared.kRing(around: origin, k: 10)
        
        measure {
            _ = NMH3Kit.shared.compact(cells)
        }
    }
}
