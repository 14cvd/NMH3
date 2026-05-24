import CoreLocation
import NMCH3

@available(iOS 15.0, macOS 13.0, *)
public extension NMH3Kit {
    @inline(__always)
    public func cell(for coordinate: CLLocationCoordinate2D, resolution: H3Resolution) -> H3Cell {
        H3Cell(index: NMH3GeoToH3(coordinate.latitude, coordinate.longitude, resolution.rawValue))
    }

    @inline(__always)
    public func cell(from string: String) -> H3Cell? {
        let idx = NMH3FromString(string)
        return NMH3IsValid(idx) ? H3Cell(index: idx) : nil
    }
}
