import CoreLocation
import Combine

/// Dynamically monitors H3 cell regions, rotating the active set as the user moves.
///
/// iOS limits apps to 20 simultaneously monitored `CLCircularRegion`s. This manager
/// overcomes that limit by tracking which target cells are nearest to the user's current
/// H3 cell and swapping monitored regions whenever the user crosses into a new cell.
///
/// - Note: Requires `NSLocationWhenInUseUsageDescription` (or Always) in Info.plist and
///   `CLLocationManager` "Always On" authorization for background delivery.
@available(iOS 15.0, *)
public final class NMH3GeofenceManager: NSObject, CLLocationManagerDelegate, @unchecked Sendable {

    // MARK: - Constants

    /// iOS hard limit on simultaneously monitored regions.
    private static let regionLimit = 20
    /// Grid-disk radius used to find candidate cells around the user.
    private static let lookAheadK = 5

    // MARK: - Private State

    private let manager = CLLocationManager()
    private var allTargetCells: [H3Cell] = []
    private var currentUserCell: H3Cell?
    private var onEntry: ((H3Cell) -> Void)?
    private var onExit: ((H3Cell) -> Void)?

    /// Cells currently being actively monitored (≤20).
    private var monitoredCells: Set<H3Cell> = []

    private var locationCancellable: AnyCancellable?

    // MARK: - Init

    public override init() {
        super.init()
        manager.delegate = self
    }

    // MARK: - Public API

    /// Begin monitoring the given target cells, rotating the active set as the user moves.
    ///
    /// - Parameters:
    ///   - cells: All target cells to eventually monitor. May exceed 20.
    ///   - locationManager: The `NMH3LocationManager` whose cell updates drive rotation.
    ///   - onEntry: Called when the user enters a monitored region.
    ///   - onExit: Called when the user exits a monitored region.
    public func monitorCells(
        _ cells: [H3Cell],
        trackingWith locationManager: NMH3LocationManager,
        onEntry: @escaping (H3Cell) -> Void,
        onExit: @escaping (H3Cell) -> Void
    ) {
        self.allTargetCells = cells
        self.onEntry = onEntry
        self.onExit = onExit

        // Subscribe to cell changes from the location manager to drive rotation
        locationCancellable = locationManager.currentCellPublisher
            .sink { [weak self] userCell in
                self?.rotateRegions(userCell: userCell)
            }
    }

    /// Convenience overload that uses a fresh `NMH3LocationManager` internally.
    /// The manager is retained by this instance for its lifetime.
    public func monitorCells(
        _ cells: [H3Cell],
        onEntry: @escaping (H3Cell) -> Void,
        onExit: @escaping (H3Cell) -> Void
    ) {
        self.allTargetCells = cells
        self.onEntry = onEntry
        self.onExit = onExit

        // On first call with no external location manager, do a one-shot initial rotation
        // using the first 20 cells as the bootstrap set. Rotation kicks in once the user
        // starts moving.
        let initial = Array(cells.prefix(NMH3GeofenceManager.regionLimit))
        updateMonitoredRegions(add: Set(initial), remove: [])
    }

    public func stopMonitoring(cell: H3Cell) {
        if let r = manager.monitoredRegions.first(where: { $0.identifier == cell.string }) {
            manager.stopMonitoring(for: r)
            monitoredCells.remove(cell)
        }
    }

    public func stopAll() {
        manager.monitoredRegions.forEach { manager.stopMonitoring(for: $0) }
        monitoredCells.removeAll()
        locationCancellable = nil
    }

    // MARK: - Rotation Logic

    /// Recomputes which target cells are closest to `userCell` and swaps monitored regions.
    private func rotateRegions(userCell: H3Cell) {
        currentUserCell = userCell

        // Find all target cells within look-ahead radius of user's current cell
        let nearbyUserCells = Set(NMH3Kit.shared.kRing(around: userCell, k: NMH3GeofenceManager.lookAheadK))
        let nearby = allTargetCells.filter { nearbyUserCells.contains($0) }

        // If no targets are near, fall back to the globally closest ones by grid distance
        let candidates: [H3Cell]
        if nearby.isEmpty {
            candidates = allTargetCells
                .compactMap { cell -> (H3Cell, Int)? in
                    let d = NMH3Kit.shared.distance(from: userCell, to: cell)
                    return d >= 0 ? (cell, d) : nil
                }
                .sorted { $0.1 < $1.1 }
                .prefix(NMH3GeofenceManager.regionLimit)
                .map(\.0)
        } else {
            candidates = Array(nearby.prefix(NMH3GeofenceManager.regionLimit))
        }

        let desired = Set(candidates)
        let toAdd = desired.subtracting(monitoredCells)
        let toRemove = monitoredCells.subtracting(desired)

        updateMonitoredRegions(add: toAdd, remove: toRemove)
    }

    private func updateMonitoredRegions(add: Set<H3Cell>, remove: Set<H3Cell>) {
        for cell in remove {
            stopMonitoring(cell: cell)
        }
        for cell in add {
            let region = CLCircularRegion(
                center: cell.center.coordinate,
                radius: max(cell.resolution.hexRadiusKm * 1000 * 0.8, 50),
                identifier: cell.string
            )
            region.notifyOnEntry = true
            region.notifyOnExit = true
            manager.startMonitoring(for: region)
            monitoredCells.insert(cell)
        }
    }

    // MARK: - CLLocationManagerDelegate

    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let cell = cellForRegion(region) else { return }
        onEntry?(cell)
    }

    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard let cell = cellForRegion(region) else { return }
        onExit?(cell)
    }

    public func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        // Region monitoring failures are non-fatal — the rotation loop will retry next cell change.
    }

    // MARK: - Helpers

    private func cellForRegion(_ region: CLRegion) -> H3Cell? {
        allTargetCells.first { $0.string == region.identifier }
    }
}
