import MapKit
#if canImport(UIKit)
import UIKit
public typealias PlatformColor = UIColor
#else
import AppKit
public typealias PlatformColor = NSColor
#endif

@available(iOS 15.0, macOS 13.0, *)
public extension MKMapView {
    public func addH3Cell(_ cell: H3Cell, color: PlatformColor) -> MKPolygon {
        let poly = cell.boundary.map { $0.coordinate }
        let mkPoly = MKPolygon(coordinates: poly, count: poly.count)
        addOverlay(mkPoly)
        return mkPoly
    }

    public func addH3Cells(_ cells: [H3Cell], color: PlatformColor) -> [MKPolygon] {
        cells.map { addH3Cell($0, color: color) }
    }

    public func removeAllH3Overlays() {
        overlays.forEach { removeOverlay($0) }
    }

    public func visibleH3Cells(resolution: H3Resolution) -> [H3Cell] {
        []
    }
}
