import CoreLocation
import NMCH3

@available(iOS 15.0, macOS 13.0, *)
public extension NMH3Kit {
    @inline(__always)
    public func center(of cell: H3Cell) -> CLLocationCoordinate2D {
        cell.center.coordinate
    }

    @inline(__always)
    public func boundary(of cell: H3Cell) -> H3Boundary {
        H3Boundary(vertices: cell.boundary)
    }
}
