import CoreLocation

@available(iOS 15.0, *)
public final class NMH3PrivacyLayer: Sendable {
    public init() {}

    public func processLocation(_ location: CLLocation) -> H3Index {
        var coord = location.coordinate
        defer {
            coord.latitude = 0
            coord.longitude = 0
        }
        return NMH3Kit.shared.cell(for: coord, resolution: .r9).index
    }

    public func obfuscatedIndex(_ index: H3Index, fuzz: Int = 1) -> H3Index {
        let ring = NMH3Kit.shared.kRing(around: H3Cell(index: index), k: fuzz)
        return ring.randomElement()?.index ?? index
    }
}
