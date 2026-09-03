import XCTest
@testable import NMH3
import CoreLocation

final class H3HierarchyTests: XCTestCase {

    private var cell9: H3Cell {
        NMH3Kit.shared.cell(for: CLLocationCoordinate2D(latitude: 40.4, longitude: 49.8), resolution: .r9)
    }

    // MARK: - Parent

    func testParentResolutionIsCorrect() {
        let parent = cell9.parent(at: .r8)
        XCTAssertEqual(parent.resolution, .r8)
    }

    func testParentIsCoarserThanChild() {
        // The parent cell at r8 should differ from the child cell at r9
        XCTAssertNotEqual(cell9.index, cell9.parent(at: .r8).index)
    }

    // MARK: - Children

    func testChildrenAtFinerResolutionContainsChild() {
        let parent = cell9.parent(at: .r8)
        let children = parent.children(at: .r9)
        XCTAssertTrue(
            children.contains(cell9),
            "Children of parent(r8) at r9 must include the original r9 cell"
        )
    }

    func testChildrenCountIsSevenForHexagon() {
        // Each non-pentagon hexagon has exactly 7 children at the next resolution
        XCTAssertFalse(cell9.isPentagon)
        let parent = cell9.parent(at: .r8)
        XCTAssertFalse(parent.isPentagon)
        let children = parent.children(at: .r9)
        XCTAssertEqual(children.count, 7, "Non-pentagon hex must have 7 children at +1 res")
    }

    func testChildrenHaveCorrectResolution() {
        let children = cell9.parent(at: .r8).children(at: .r9)
        for child in children {
            XCTAssertEqual(child.resolution, .r9)
        }
    }

    // MARK: - Parent/child round-trip

    func testParentChildRoundTrip() {
        // child.parent(at: r8).children(at: r9) must contain child
        let parent = cell9.parent(at: .r8)
        let siblings = parent.children(at: .r9)
        XCTAssertTrue(siblings.contains(cell9), "Parent→children round-trip must recover original child")
    }

    func testAncestorChain() {
        // Walking up the resolution chain: each parent must have lower resolution
        var cell = cell9
        for targetRes in stride(from: 8, through: 0, by: -1) {
            let parent = cell.parent(at: H3Resolution(rawValue: targetRes)!)
            XCTAssertEqual(parent.resolution.rawValue, targetRes)
            cell = parent
        }
    }

    // MARK: - Center child

    func testCenterChildResolution() {
        let centerChild = cell9.centerChild(at: .r10)
        XCTAssertEqual(centerChild.resolution, .r10)
    }

    func testCenterChildParentIsOriginal() {
        let centerChild = cell9.centerChild(at: .r10)
        let backToParent = centerChild.parent(at: .r9)
        XCTAssertEqual(backToParent.index, cell9.index)
    }

    // MARK: - Compact / Uncompact

    func testCompactUncompactIsInverse() {
        // Take a set of r9 cells and verify compact→uncompact recovers the same set
        let cells = Array(NMH3Kit.shared.kRing(around: cell9, k: 2))
        let res = H3Resolution.r9

        let compacted = NMH3Kit.shared.compact(cells)
        XCTAssertLessThanOrEqual(compacted.count, cells.count, "Compact must not grow the set")

        let uncompacted = NMH3Kit.shared.uncompact(compacted, to: res)
        XCTAssertEqual(
            Set(uncompacted.map(\.index)),
            Set(cells.map(\.index)),
            "Uncompact(Compact(cells)) must recover original cell set"
        )
    }

    func testFullyUniformRegionCompactsToSingleParent() {
        // If all 7 children of a parent are present, compact should produce just the parent
        let parent = cell9.parent(at: .r8)
        XCTAssertFalse(parent.isPentagon)
        let children = parent.children(at: .r9)
        XCTAssertEqual(children.count, 7)

        let compacted = NMH3Kit.shared.compact(children)
        XCTAssertEqual(compacted.count, 1)
        XCTAssertEqual(compacted.first?.index, parent.index)
    }
}
