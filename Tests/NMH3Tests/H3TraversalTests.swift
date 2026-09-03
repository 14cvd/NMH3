import XCTest
@testable import NMH3
import CoreLocation

final class H3TraversalTests: XCTestCase {

    private var origin: H3Cell {
        NMH3Kit.shared.cell(for: CLLocationCoordinate2D(latitude: 37.3382, longitude: -121.8863), resolution: .r9)
    }

    // MARK: - k-ring

    func testKRingZeroReturnsOnlyOrigin() {
        let ring = NMH3Kit.shared.kRing(around: origin, k: 0)
        XCTAssertEqual(ring.count, 1)
        XCTAssertEqual(ring.first?.index, origin.index)
    }

    func testKRingOneHasSevenCells() {
        // For any non-pentagon cell, k=1 disk contains exactly 7 cells (origin + 6 neighbors)
        XCTAssertFalse(origin.isPentagon, "Test prereq: origin must not be a pentagon")
        let ring = NMH3Kit.shared.kRing(around: origin, k: 1)
        XCTAssertEqual(ring.count, 7, "k-ring(k=1) must return 7 cells for a hexagon")
    }

    func testKRingTwoHas19Cells() {
        XCTAssertFalse(origin.isPentagon)
        let ring = NMH3Kit.shared.kRing(around: origin, k: 2)
        XCTAssertEqual(ring.count, 19, "k-ring(k=2) must return 19 cells for a hexagon")
    }

    func testKRingContainsOrigin() {
        let ring = NMH3Kit.shared.kRing(around: origin, k: 3)
        XCTAssertTrue(ring.contains(origin))
    }

    func testKRingReturnsActualNeighbors() {
        // Every cell in kRing(k=1) except the origin must be at grid distance == 1
        let ring = NMH3Kit.shared.kRing(around: origin, k: 1)
        for cell in ring where cell != origin {
            let d = NMH3Kit.shared.distance(from: origin, to: cell)
            XCTAssertEqual(d, 1, "Neighbor \(cell.string) has grid distance \(d) instead of 1")
        }
    }

    // MARK: - Hex ring (exact ring, not disk)

    func testHexRingZeroContainsOnlyOrigin() {
        let ring = NMH3Kit.shared.hexRing(around: origin, k: 0)
        XCTAssertEqual(ring.count, 1)
        XCTAssertTrue(ring.contains(origin))
    }

    func testHexRingOneHasSixCells() {
        XCTAssertFalse(origin.isPentagon)
        let ring = NMH3Kit.shared.hexRing(around: origin, k: 1)
        XCTAssertEqual(ring.count, 6, "Hex ring k=1 must have exactly 6 cells for a hexagon")
        XCTAssertFalse(ring.contains(origin), "Hex ring must not contain the origin")
    }

    func testHexRingKCellsAreAllAtDistanceK() {
        let k = 2
        let ring = NMH3Kit.shared.hexRing(around: origin, k: k)
        for cell in ring {
            let d = NMH3Kit.shared.distance(from: origin, to: cell)
            XCTAssertEqual(d, k, "Hex ring(k=\(k)) cell \(cell.string) has distance \(d)")
        }
    }

    // MARK: - Grid distance

    func testDistanceSameCellIsZero() {
        let d = NMH3Kit.shared.distance(from: origin, to: origin)
        XCTAssertEqual(d, 0)
    }

    func testDistanceIsNotAlwaysOne() {
        // Cells several rings apart must produce distance > 1
        let far = NMH3Kit.shared.cell(
            for: CLLocationCoordinate2D(latitude: 37.36, longitude: -121.88),
            resolution: .r9
        )
        let d = NMH3Kit.shared.distance(from: origin, to: far)
        XCTAssertGreaterThan(d, 1, "Spatially separated cells must have grid distance > 1")
    }

    func testDistanceMatchesKRing() {
        // Any cell in kRing(k=3) but not kRing(k=2) must be at distance exactly 3
        let disk3 = Set(NMH3Kit.shared.kRing(around: origin, k: 3))
        let disk2 = Set(NMH3Kit.shared.kRing(around: origin, k: 2))
        let ring3 = disk3.subtracting(disk2)
        for cell in ring3 {
            let d = NMH3Kit.shared.distance(from: origin, to: cell)
            XCTAssertEqual(d, 3, "Ring-3 cell \(cell.string) has distance \(d) instead of 3")
        }
    }

    func testDistanceIsSymmetric() {
        let other = NMH3Kit.shared.kRing(around: origin, k: 2).first(where: { $0 != origin })!
        XCTAssertEqual(
            NMH3Kit.shared.distance(from: origin, to: other),
            NMH3Kit.shared.distance(from: other, to: origin)
        )
    }

    // MARK: - Line (grid path)

    func testLineIncludesEndpoints() {
        let start = origin
        let end = NMH3Kit.shared.kRing(around: origin, k: 3).sorted { $0.index < $1.index }.last!
        let path = NMH3Kit.shared.line(from: start, to: end)
        XCTAssertEqual(path.first?.index, start.index)
        XCTAssertEqual(path.last?.index, end.index)
    }

    func testLineToSelfHasOneCell() {
        let path = NMH3Kit.shared.line(from: origin, to: origin)
        XCTAssertEqual(path.count, 1)
    }

    func testLineLengthEqualsDistancePlusOne() {
        let neighbor = NMH3Kit.shared.kRing(around: origin, k: 1).first(where: { $0 != origin })!
        let d = NMH3Kit.shared.distance(from: origin, to: neighbor)
        let path = NMH3Kit.shared.line(from: origin, to: neighbor)
        XCTAssertEqual(path.count, d + 1, "Line length must be gridDistance + 1")
    }
}
