import CoreLocation
import NMCH3

@available(iOS 15.0, macOS 13.0, *)
public extension NMH3Kit {
    @inline(__always)
    public func polyfill(polygon: [CLLocationCoordinate2D], resolution: H3Resolution) -> [H3Cell] {
        let vals = polygon.map {
            var c = NMGeoCoord(lat: $0.latitude, lng: $0.longitude)
            return NSValue(bytes: &c, objCType: "{?=dd}")
        }
        return NMH3Polyfill(vals, resolution.rawValue).map { H3Cell(index: $0.uint64Value) }
    }
}
