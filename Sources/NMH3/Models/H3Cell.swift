import NMCH3

public typealias H3Index = UInt64

public struct H3Cell: Equatable, Hashable, CustomStringConvertible, Sendable {
    public let index: H3Index

    public init(index: H3Index) {
        self.index = index
    }

    public var resolution: H3Resolution {
        H3Resolution(rawValue: NMH3GetResolution(index)) ?? .r0
    }

    public var center: H3GeoCoord {
        let c = NMH3ToGeo(index)
        return H3GeoCoord(latitude: c.lat, longitude: c.lng)
    }

    public var boundary: [H3GeoCoord] {
        let arr = NMH3ToGeoBoundary(index)
        return arr.compactMap {
            var c = NMGeoCoord()
            $0.getValue(&c)
            return H3GeoCoord(latitude: c.lat, longitude: c.lng)
        }
    }

    public var string: String { NMH3ToString(index) }
    public var description: String { string }
    public var isPentagon: Bool { NMH3IsPentagon(index) }

    public func parent(at res: H3Resolution) -> H3Cell {
        H3Cell(index: NMH3ToParent(index, res.rawValue))
    }

    public func children(at res: H3Resolution) -> [H3Cell] {
        NMH3ToChildren(index, res.rawValue).map { H3Cell(index: $0.uint64Value) }
    }

    public func centerChild(at res: H3Resolution) -> H3Cell {
        H3Cell(index: NMH3ToCenterChild(index, res.rawValue))
    }
}
