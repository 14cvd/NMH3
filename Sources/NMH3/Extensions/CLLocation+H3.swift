import CoreLocation

@available(iOS 15.0, *)
public extension CLLocation {
    public func h3Cell(resolution: H3Resolution) -> H3Cell {
        NMH3Kit.shared.cell(for: self.coordinate, resolution: resolution)
    }

    public func h3Index(resolution: H3Resolution) -> H3Index {
        h3Cell(resolution: resolution).index
    }
}
