import XCTest
@testable import NMH3
import CoreLocation

final class H3EncoderTests: XCTestCase {
    
    /// Test round-trip conversion: Coordinate -> H3 -> Coordinate
    func testRoundTrip() {
        let coords = [
            CLLocationCoordinate2D(latitude: 40.3893, longitude: 49.8529), // Baku
            CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278), // London
            CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093), // Sydney
            CLLocationCoordinate2D(latitude: 0, longitude: 0) // Equator/Prime Meridian
        ]
        
        for coord in coords {
            for res in H3Resolution.allCases {
                let cell = NMH3Kit.shared.cell(for: coord, resolution: res)
                let center = NMH3Kit.shared.center(of: cell)
                
                // Allow small precision loss due to hex quantization
                XCTAssertEqual(center.latitude, coord.latitude, accuracy: 0.1, "Latitude mismatch at res \(res.rawValue)")
                XCTAssertEqual(center.longitude, coord.longitude, accuracy: 0.1, "Longitude mismatch at res \(res.rawValue)")
            }
        }
    }
    
    /// Test H3 string representation and restoration
    func testStringConversion() {
        let coord = CLLocationCoordinate2D(latitude: 40.4093, longitude: 49.8671)
        let cell = NMH3Kit.shared.cell(for: coord, resolution: .r9)
        
        let h3String = cell.string
        XCTAssertFalse(h3String.isEmpty)
        
        let restoredCell = NMH3Kit.shared.cell(from: h3String)
        XCTAssertNotNil(restoredCell)
        XCTAssertEqual(restoredCell?.index, cell.index)
        XCTAssertEqual(restoredCell?.resolution, .r9)
    }
    
    /// Test edge cases like poles
    func testEdgeCases() {
        let northPole = CLLocationCoordinate2D(latitude: 90, longitude: 0)
        let southPole = CLLocationCoordinate2D(latitude: -90, longitude: 0)
        
        let nCell = NMH3Kit.shared.cell(for: northPole, resolution: .r5)
        let sCell = NMH3Kit.shared.cell(for: southPole, resolution: .r5)
        
        XCTAssertNotEqual(nCell.index, sCell.index)
        XCTAssertEqual(nCell.resolution, .r5)
    }
    
    /// Test invalid string handling
    func testInvalidString() {
        let invalid = "not-a-hex-index"
        let cell = NMH3Kit.shared.cell(from: invalid)
        XCTAssertNil(cell)
    }
}
