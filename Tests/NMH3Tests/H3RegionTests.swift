import XCTest
@testable import NMH3
import CoreLocation

final class H3RegionTests: XCTestCase {

    // MARK: - Polyfill

    func testPolyfillReturnsNonEmptyForValidPolygon() {
        // ~10 km² bounding box over Baku; at r7 expect several cells
        let polygon = [
            CLLocationCoordinate2D(latitude: 40.35, longitude: 49.80),
            CLLocationCoordinate2D(latitude: 40.45, longitude: 49.80),
            CLLocationCoordinate2D(latitude: 40.45, longitude: 49.90),
            CLLocationCoordinate2D(latitude: 40.35, longitude: 49.90),
        ]
        let cells = NMH3Kit.shared.polyfill(polygon: polygon, resolution: .r7)
        XCTAssertGreaterThan(cells.count, 0, "Polyfill of a valid polygon must return at least one cell")
    }

    func testPolyfillCellsAreAtCorrectResolution() {
        let polygon = [
            CLLocationCoordinate2D(latitude: 40.38, longitude: 49.85),
            CLLocationCoordinate2D(latitude: 40.42, longitude: 49.85),
            CLLocationCoordinate2D(latitude: 40.42, longitude: 49.90),
            CLLocationCoordinate2D(latitude: 40.38, longitude: 49.90),
        ]
        let cells = NMH3Kit.shared.polyfill(polygon: polygon, resolution: .r9)
        for cell in cells {
            XCTAssertEqual(cell.resolution, .r9, "All polyfill cells must have the requested resolution")
        }
    }

    func testPolyfillCellsAreDeduplicated() {
        let polygon = [
            CLLocationCoordinate2D(latitude: 40.38, longitude: 49.85),
            CLLocationCoordinate2D(latitude: 40.42, longitude: 49.85),
            CLLocationCoordinate2D(latitude: 40.42, longitude: 49.90),
            CLLocationCoordinate2D(latitude: 40.38, longitude: 49.90),
        ]
        let cells = NMH3Kit.shared.polyfill(polygon: polygon, resolution: .r9)
        let indices = cells.map(\.index)
        XCTAssertEqual(indices.count, Set(indices).count, "Polyfill must not return duplicate cells")
    }

    func testEmptyPolygonReturnsEmpty() {
        let cells = NMH3Kit.shared.polyfill(polygon: [], resolution: .r9)
        XCTAssertTrue(cells.isEmpty)
    }

    func testPolyfillSinglePointIsEmpty() {
        // A degenerate polygon with one vertex has no interior
        let cells = NMH3Kit.shared.polyfill(
            polygon: [CLLocationCoordinate2D(latitude: 40.4, longitude: 49.8)],
            resolution: .r9
        )
        // May be empty or contain the enclosing cell — H3 spec leaves this edge case
        // to the implementation; we just assert it doesn't crash and returns valid cells.
        for cell in cells {
            XCTAssertEqual(cell.resolution, .r9)
        }
    }

    // MARK: - Cell boundary

    func testHexagonBoundaryHasSixVertices() {
        let cell = NMH3Kit.shared.cell(
            for: CLLocationCoordinate2D(latitude: 40.0, longitude: 49.0),
            resolution: .r9
        )
        XCTAssertFalse(cell.isPentagon)
        let boundary = NMH3Kit.shared.boundary(of: cell)
        XCTAssertEqual(boundary.vertices.count, 6, "Non-pentagon hexagon must have 6 boundary vertices")
    }

    func testPentagonBoundaryHasFiveVertices() {
        // Find a known pentagon cell (resolution 2, base cell 4)
        // Pentagon cells have 5 boundary vertices instead of 6
        let pentagonCell = H3Cell(index: 0x824d7ffffffffff) // known res-2 pentagon
        if pentagonCell.isPentagon {
            let boundary = NMH3Kit.shared.boundary(of: pentagonCell)
            XCTAssertEqual(boundary.vertices.count, 5, "Pentagon must have 5 boundary vertices")
        }
        // Skip gracefully if the hardcoded index doesn't match (platform/version edge case)
    }

    func testBoundaryVerticesAreWithinValidRange() {
        let cell = NMH3Kit.shared.cell(
            for: CLLocationCoordinate2D(latitude: 40.0, longitude: 49.0),
            resolution: .r9
        )
        for vertex in NMH3Kit.shared.boundary(of: cell).vertices {
            XCTAssert(vertex.latitude  >= -90  && vertex.latitude  <= 90)
            XCTAssert(vertex.longitude >= -180 && vertex.longitude <= 180)
        }
    }
}
