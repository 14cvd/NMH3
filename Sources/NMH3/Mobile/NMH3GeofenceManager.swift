import CoreLocation

@available(iOS 15.0, *)
public final class NMH3GeofenceManager: @unchecked Sendable {
    private let manager = CLLocationManager()

    public init() {}

    public func monitorCells(_ cells: [H3Cell], onEntry: @escaping (H3Cell)->Void, onExit: @escaping (H3Cell)->Void) {
        for cell in cells.prefix(20) {
            let region = CLCircularRegion(
                center: cell.center.coordinate,
                radius: cell.resolution.hexRadiusKm * 1000 * 0.8,
                identifier: cell.string
            )
            region.notifyOnEntry = true
            region.notifyOnExit = true
            manager.startMonitoring(for: region)
        }
    }

    public func stopMonitoring(cell: H3Cell) {
        if let r = manager.monitoredRegions.first(where: { $0.identifier == cell.string }) {
            manager.stopMonitoring(for: r)
        }
    }

    public func stopAll() {
        manager.monitoredRegions.forEach { manager.stopMonitoring(for: $0) }
    }
}
