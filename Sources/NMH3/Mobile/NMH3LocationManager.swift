import CoreLocation
import Combine

/// Tracks the user's current H3 cell and publishes changes.
///
/// Optionally accepts an `NMH3BatteryOptimizer` to automatically scale GPS accuracy and
/// distance filter based on battery level and device motion state.
@available(iOS 15.0, *)
public final class NMH3LocationManager: NSObject, CLLocationManagerDelegate, @unchecked Sendable {
    private let manager = CLLocationManager()

    public let currentCellPublisher = PassthroughSubject<H3Cell, Never>()
    public let cellChangePublisher = PassthroughSubject<(old: H3Cell, new: H3Cell), Never>()

    public var resolution: H3Resolution = .r9 {
        didSet { applyResolutionConfig() }
    }

    private var currentCell: H3Cell?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    /// Creates a location manager.
    /// - Parameter batteryOptimizer: When provided, GPS accuracy and distance filter are
    ///   automatically adjusted whenever the battery profile or motion state changes.
    ///   Pass `nil` (the default) to use fixed resolution-based config.
    public init(batteryOptimizer: NMH3BatteryOptimizer? = nil) {
        super.init()
        manager.delegate = self
        applyResolutionConfig()

        if let optimizer = batteryOptimizer {
            // React to battery profile changes
            optimizer.batteryProfilePublisher
                .receive(on: RunLoop.main)
                .sink { [weak self] profile in
                    self?.applyBatteryProfile(profile)
                }
                .store(in: &cancellables)

            #if os(iOS)
            // Pause / resume updates based on motion state
            optimizer.isStationaryPublisher
                .receive(on: RunLoop.main)
                .sink { [weak self] stationary in
                    guard let self else { return }
                    if stationary {
                        // Device is not moving — increase distance filter significantly to
                        // suppress redundant wake-ups while still detecting large moves.
                        self.manager.distanceFilter = max(
                            self.resolution.hexRadiusKm * 1000.0,
                            500.0
                        )
                    } else {
                        // Device is moving — restore normal config
                        self.applyResolutionConfig()
                    }
                }
                .store(in: &cancellables)
            #endif
        }
    }

    // MARK: - Control

    public func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    public func start() {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
        manager.startUpdatingLocation()
    }

    public func stop() {
        manager.stopUpdatingLocation()
    }

    // MARK: - CLLocationManagerDelegate

    public func locationManager(_ m: CLLocationManager, didUpdateLocations locs: [CLLocation]) {
        guard let loc = locs.last else { return }

        // NOTE: CLLocationCoordinate2D is a value type. Zeroing a local copy has no effect
        // on the original CLLocation object or the locs array — it would be optimized away
        // as a dead store. The real privacy guarantee here is that we never persist the raw
        // coordinate: we only publish the H3 cell index and discard loc immediately after.
        let cell = NMH3Kit.shared.cell(for: loc.coordinate, resolution: resolution)
        if let old = currentCell {
            if old != cell {
                cellChangePublisher.send((old: old, new: cell))
                currentCellPublisher.send(cell)
                currentCell = cell
            }
        } else {
            currentCell = cell
            currentCellPublisher.send(cell)
        }
    }

    // MARK: - Private

    /// Applies accuracy and distance filter appropriate for the current resolution.
    private func applyResolutionConfig() {
        manager.distanceFilter = resolution.hexRadiusKm * 1000.0 * 0.4
        switch resolution.rawValue {
        case 0...8: manager.desiredAccuracy = kCLLocationAccuracyKilometer
        case 9...10: manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        default: manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        }
    }

    /// Overrides accuracy based on battery profile. Called by `NMH3BatteryOptimizer` subscription.
    private func applyBatteryProfile(_ profile: NMH3BatteryOptimizer.BatteryProfile) {
        switch profile {
        case .ultraLow:
            // Maximum battery conservation: coarsest accuracy, large distance filter
            manager.desiredAccuracy = kCLLocationAccuracyKilometer
            manager.distanceFilter = 500
        case .low:
            manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            manager.distanceFilter = 200
        case .balanced:
            // Fall back to resolution-based defaults
            applyResolutionConfig()
        case .high:
            // Allow full accuracy when battery is healthy
            manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            manager.distanceFilter = max(resolution.hexRadiusKm * 1000.0 * 0.2, 10.0)
        }
    }
}
