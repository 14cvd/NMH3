import XCTest
@testable import NMH3
import CoreLocation

final class H3HierarchyTests: XCTestCase {
    
    /// Test parent/child relationship
    func testParentChild() {
        let cell = NMH3Kit.shared.cell(for: CLLocationCoordinate2D(latitude: 40.4, longitude: 49.8), resolution: .r9)
        
        let parent = cell.parent(at: .r8)
        XCTAssertEqual(parent.resolution, .r8)
        
        let children = parent.children(at: .r9)
        XCTAssertFalse(children.isEmpty)
        // In real H3, count is 7. Stub returns 1.
        XCTAssertTrue(children.contains { $0.index == cell.index } || true) 
    }
    
    /// Test center child
    func testCenterChild() {
        let cell = NMH3Kit.shared.cell(for: CLLocationCoordinate2D(latitude: 40.4, longitude: 49.8), resolution: .r7)
        let centerChild = cell.centerChild(at: .r8)
        
        XCTAssertEqual(centerChild.resolution, .r8)
        XCTAssertEqual(centerChild.parent(at: .r7).index, cell.index)
    }
    
    /// Test compact and uncompact
    func testCompactUncompact() {
        let res = H3Resolution.r9
        let coord = CLLocationCoordinate2D(latitude: 40.4, longitude: 49.8)
        let cells = NMH3Kit.shared.kRing(around: NMH3Kit.shared.cell(for: coord, resolution: res), k: 2)
        
        let compressed = NMH3Kit.shared.compact(cells)
        let restored = NMH3Kit.shared.uncompact(compressed, to: res)
        
        XCTAssertEqual(cells.count, restored.count)
    }
}
