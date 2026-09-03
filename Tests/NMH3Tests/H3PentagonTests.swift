import XCTest
@testable import NMH3
import CoreLocation

/// Tests pentagon detection against publicly-documented H3 pentagon cells.
///
/// H3 has exactly 12 pentagon base cells per resolution. At resolution 0 these are the
/// 12 icosahedron vertices. The indices below are the canonical res-0 pentagon cells
/// from the H3 specification (https://h3geo.org/docs/core-library/basecells).
final class H3PentagonTests: XCTestCase {

    // Canonical resolution-0 pentagon H3 indices from getPentagons(res=0) in H3 C library v4.1.0
    private let knownPentagonIndices: [UInt64] = [
        0x8009fffffffffff,
        0x801dfffffffffff,
        0x8031fffffffffff,
        0x804dfffffffffff,
        0x8063fffffffffff,
        0x8075fffffffffff,
        0x807ffffffffffff,
        0x8091fffffffffff,
        0x80a7fffffffffff,
        0x80c3fffffffffff,
        0x80d7fffffffffff,
        0x80ebfffffffffff,
    ]

    func testPentagonDetectionForKnownPentagonCells() {
        for idx in knownPentagonIndices {
            let cell = H3Cell(index: idx)
            XCTAssertTrue(
                cell.isPentagon,
                "Cell \(cell.string) (index: \(String(idx, radix: 16))) should be detected as a pentagon"
            )
        }
    }

    func testExactlyTwelvePentagonsInList() {
        // The H3 spec mandates exactly 12 pentagons at every resolution.
        // Our list was generated via getPentagons(res=0) — verify it has exactly 12 entries
        // and that every one is confirmed as a pentagon by the library.
        XCTAssertEqual(knownPentagonIndices.count, 12, "H3 must have exactly 12 pentagon base cells")
        for idx in knownPentagonIndices {
            XCTAssertTrue(H3Cell(index: idx).isPentagon, "Index \(String(idx, radix: 16)) must be detected as pentagon")
        }
    }

    func testOrdinaryHexagonIsNotPentagon() {
        let cell = NMH3Kit.shared.cell(
            for: CLLocationCoordinate2D(latitude: 37.3382, longitude: -121.8863),
            resolution: .r9
        )
        XCTAssertFalse(cell.isPentagon, "Ordinary hexagon cell must not be detected as a pentagon")
    }

    func testPentagonHasFiveBoundaryVertices() {
        for idx in knownPentagonIndices {
            let cell = H3Cell(index: idx)
            let boundary = NMH3Kit.shared.boundary(of: cell)
            XCTAssertEqual(
                boundary.vertices.count, 5,
                "Pentagon \(cell.string) must have 5 boundary vertices, got \(boundary.vertices.count)"
            )
        }
    }
}
