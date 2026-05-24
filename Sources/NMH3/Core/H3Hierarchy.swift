import NMCH3

@available(iOS 15.0, macOS 13.0, *)
public extension NMH3Kit {
    @inline(__always)
    public func compact(_ cells: [H3Cell]) -> [H3Cell] {
        NMH3Compact(cells.map { NSNumber(value: $0.index) }).map { H3Cell(index: $0.uint64Value) }
    }

    @inline(__always)
    public func uncompact(_ cells: [H3Cell], to res: H3Resolution) -> [H3Cell] {
        NMH3Uncompact(cells.map { NSNumber(value: $0.index) }, res.rawValue).map { H3Cell(index: $0.uint64Value) }
    }
}
