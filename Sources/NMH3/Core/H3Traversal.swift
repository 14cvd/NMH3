import NMCH3

@available(iOS 15.0, macOS 13.0, *)
public extension NMH3Kit {
    @inline(__always)
    public func kRing(around cell: H3Cell, k: Int) -> [H3Cell] {
        NMH3KRing(cell.index, k).map { H3Cell(index: $0.uint64Value) }
    }

    @inline(__always)
    public func hexRing(around cell: H3Cell, k: Int) -> [H3Cell] {
        NMH3HexRing(cell.index, k).map { H3Cell(index: $0.uint64Value) }
    }

    @inline(__always)
    public func line(from: H3Cell, to: H3Cell) -> [H3Cell] {
        NMH3Line(from.index, to.index).map { H3Cell(index: $0.uint64Value) }
    }

    @inline(__always)
    public func distance(from: H3Cell, to: H3Cell) -> Int {
        NMH3Distance(from.index, to.index)
    }
}
