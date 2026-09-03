import XCTest
@testable import NMH3
import CoreLocation

/// Tests that encoding / decoding produces canonical H3 index values that are
/// bit-for-bit compatible with Uber's reference H3 implementation.
///
/// Reference values were generated using h3-go v4.1.0 and h3-js v4.1.0 for each coordinate.
final class H3EncoderTests: XCTestCase {

    // MARK: - Reference Value Tests (spec compliance gate)

    /// These known coordinate→index pairs are the primary regression guard.
    /// If any of these fail, the encoding is NOT compatible with standard H3.
    func testKnownReferenceValues() {
        // Reference values produced by the vendored H3 C library v4.1.0 (uber/h3).
        // These are the canonical indices for these exact coordinates at the given resolution.
        // If any of these fail after a library upgrade, compare against `h3 latLngToCell`
        // in the h3 CLI or h3-go to verify the expected value hasn't changed.
        let references: [(lat: Double, lng: Double, res: H3Resolution, expected: String)] = [
            // San Francisco Bay Area (San Jose)
            (37.3382, -121.8863, .r9,  "89283444927ffff"),
            // Eiffel Tower, Paris
            (48.8584,   2.2945, .r9,  "891fb46741bffff"),
            // Times Square, New York
            (40.7580,  -73.9855, .r9, "892a100d67bffff"),
            // Sydney Opera House
            (-33.8568, 151.2153, .r9, "89be0e35c0bffff"),
            // Baku city center
            (40.3893,  49.8529, .r9,  "892ce581d57ffff"),
            // Resolution 5 — coarser cell
            (37.3382, -121.8863, .r5,  "85283473fffffff"),
            // Resolution 12 — fine cell
            (37.3382, -121.8863, .r12, "8c28344492521ff"),
        ]

        for ref in references {
            let cell = NMH3Kit.shared.cell(
                for: CLLocationCoordinate2D(latitude: ref.lat, longitude: ref.lng),
                resolution: ref.res
            )
            XCTAssertEqual(
                cell.string, ref.expected,
                "[\(ref.lat), \(ref.lng)] res=\(ref.res.rawValue): expected \(ref.expected), got \(cell.string)"
            )
        }
    }

    // MARK: - Round-trip correctness

    /// The center of a cell, when re-encoded at the same resolution, must produce the same cell.
    func testRoundTrip() {
        let coords = [
            CLLocationCoordinate2D(latitude: 40.3893, longitude: 49.8529),   // Baku
            CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278),   // London
            CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093), // Sydney
            CLLocationCoordinate2D(latitude: 0, longitude: 0),               // Equator/Prime Meridian
        ]

        for coord in coords {
            for res in [H3Resolution.r3, .r6, .r9, .r12] {
                let cell = NMH3Kit.shared.cell(for: coord, resolution: res)
                let center = NMH3Kit.shared.center(of: cell)
                let roundTripped = NMH3Kit.shared.cell(for: center.coordinate, resolution: res)
                XCTAssertEqual(
                    cell.index, roundTripped.index,
                    "Round-trip failed at res \(res.rawValue): \(coord)"
                )
            }
        }
    }

    // MARK: - String serialisation

    func testStringConversion() {
        let coord = CLLocationCoordinate2D(latitude: 40.4093, longitude: 49.8671)
        let cell = NMH3Kit.shared.cell(for: coord, resolution: .r9)

        let h3String = cell.string
        XCTAssertFalse(h3String.isEmpty)
        XCTAssertEqual(h3String.count, 15, "H3 res-9 index should serialise to 15 hex chars")

        let restoredCell = NMH3Kit.shared.cell(from: h3String)
        XCTAssertNotNil(restoredCell)
        XCTAssertEqual(restoredCell?.index, cell.index)
        XCTAssertEqual(restoredCell?.resolution, .r9)
    }

    func testInvalidString() {
        let cell = NMH3Kit.shared.cell(from: "not-a-hex-index")
        XCTAssertNil(cell)
    }

    // MARK: - Edge cases

    func testPolarCoordinatesProduceDifferentCells() {
        let nCell = NMH3Kit.shared.cell(for: CLLocationCoordinate2D(latitude: 89.9, longitude: 0), resolution: .r5)
        let sCell = NMH3Kit.shared.cell(for: CLLocationCoordinate2D(latitude: -89.9, longitude: 0), resolution: .r5)
        XCTAssertNotEqual(nCell.index, sCell.index)
    }

    func testResolutionIsPreserved() {
        let coord = CLLocationCoordinate2D(latitude: 40.0, longitude: 49.0)
        for res in H3Resolution.allCases {
            let cell = NMH3Kit.shared.cell(for: coord, resolution: res)
            XCTAssertEqual(cell.resolution, res)
        }
    }

    func testBoundaryVertexCount() {
        // Non-pentagon cells have exactly 6 boundary vertices
        let cell = NMH3Kit.shared.cell(
            for: CLLocationCoordinate2D(latitude: 37.3382, longitude: -121.8863),
            resolution: .r9
        )
        XCTAssertFalse(cell.isPentagon, "Test prerequisite: cell must not be a pentagon")
        let boundary = NMH3Kit.shared.boundary(of: cell)
        XCTAssertEqual(boundary.vertices.count, 6)
    }
}
