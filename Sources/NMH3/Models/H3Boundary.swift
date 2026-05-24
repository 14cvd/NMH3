import MapKit

public struct H3Boundary: Sendable {
    public let vertices: [H3GeoCoord]
    public init(vertices: [H3GeoCoord]) {
        self.vertices = vertices
    }
    public func mkPolygon() -> MKPolygon {
        let coords = vertices.map { $0.coordinate }
        return MKPolygon(coordinates: coords, count: coords.count)
    }
    public func cgPath(in mapRect: MKMapRect) -> CGPath {
        return CGMutablePath()
    }
}
