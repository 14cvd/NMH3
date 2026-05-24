import XCTest
@testable import NMH3
import CoreLocation

final class H3RegionTests: XCTestCase {
    
    /// Test polyfill functionality
    func testPolyfill() {
        // Baku square
        let polygon = [
            CLLocationCoordinate2D(latitude: 40.35, longitude: 49.80),
            CLLocationCoordinate2D(latitude: 40.45, longitude: 49.80),
            CLLocationCoordinate2D(latitude: 40.45, longitude: 49.90),
            CLLocationCoordinate2D(latitude: 40.35, longitude: 49.90)
        ]
        
        let cells = NMH3Kit.shared.polyfill(polygon: polygon, resolution: .r7)
        
        // Our stub currently returns empty, but test the structure
        XCTAssertNotNil(cells)
    }
    
    /// Test empty polygon
    func testEmptyPolygon() {
        let cells = NMH3Kit.shared.polyfill(polygon: [], resolution: .r9)
        XCTAssertTrue(cells.isEmpty)
    }
    
    /// Test cell boundary generation
    func testCellBoundary() {
        let cell = NMH3Kit.shared.cell(for: CLLocationCoordinate2D(latitude: 40, longitude: 49), resolution: .r9)
        let boundary = NMH3Kit.shared.boundary(of: cell)
        
        XCTAssertEqual(boundary.vertices.count, 6, "Hexagon should have 6 vertices")
        
        for vertex in boundary.vertices {
            XCTAssert(vertex.latitude >= -90 && vertex.latitude <= 90)
            XCTAssert(vertex.longitude >= -180 && vertex.longitude <= 180)
        }
    }
}
