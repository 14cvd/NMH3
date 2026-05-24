import CoreLocation
import Combine

@available(iOS 15.0, *)
public final class NMH3LocationManager: NSObject, CLLocationManagerDelegate, @unchecked Sendable {
    private let manager = CLLocationManager()

    public let currentCellPublisher = PassthroughSubject<H3Cell, Never>()
    public let cellChangePublisher = PassthroughSubject<(old: H3Cell, new: H3Cell), Never>()

    public var resolution: H3Resolution = .r9 {
        didSet { updateConfig() }
    }

    private var currentCell: H3Cell?

    public override init() {
        super.init()
        manager.delegate = self
        updateConfig()
    }

    private func updateConfig() {
        manager.distanceFilter = resolution.hexRadiusKm * 1000.0 * 0.4
        switch resolution.rawValue {
        case 0...8: manager.desiredAccuracy = kCLLocationAccuracyKilometer
        case 9...10: manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        default: manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        }
    }

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

    public func locationManager(_ m: CLLocationManager, didUpdateLocations locs: [CLLocation]) {
        guard let loc = locs.last else { return }

        var coord = loc.coordinate
        defer {
            coord.latitude = 0
            coord.longitude = 0
        }

        let cell = NMH3Kit.shared.cell(for: coord, resolution: resolution)
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
}
