import CoreMotion
import Combine
#if canImport(UIKit)
import UIKit
#endif

/// Monitors device battery level and motion state, publishing a consolidated
/// `BatteryProfile` that `NMH3LocationManager` uses to dynamically scale GPS accuracy.
@available(iOS 15.0, macOS 13.0, *)
public final class NMH3BatteryOptimizer: @unchecked Sendable {

    // MARK: - Battery Profile

    public enum BatteryProfile: Equatable {
        /// <20% battery. Use coarsest accuracy and maximum distance filter.
        case ultraLow
        /// 20-40% battery. Reduce GPS accuracy significantly.
        case low
        /// 40-80% battery. Use resolution-appropriate defaults.
        case balanced
        /// >80% battery. Allow full GPS accuracy when needed.
        case high
    }

    // MARK: - Publishers

    /// Continuously emits the current `BatteryProfile` whenever battery level or
    /// charge state changes. `NMH3LocationManager` subscribes to this to auto-scale accuracy.
    public let batteryProfilePublisher = CurrentValueSubject<BatteryProfile, Never>(.balanced)

    // MARK: - Private State

    #if os(iOS)
    private let motionManager = CMMotionActivityManager()
    /// Most recently observed motion state; used to suppress updates when stationary.
    private(set) public var isStationary: Bool = false
    /// Fires when the device transitions between moving and stationary.
    public let isStationaryPublisher = CurrentValueSubject<Bool, Never>(false)
    #endif

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    public init() {
        #if canImport(UIKit)
        UIDevice.current.isBatteryMonitoringEnabled = true
        // Observe both level and state changes
        NotificationCenter.default.publisher(for: UIDevice.batteryLevelDidChangeNotification)
            .merge(with: NotificationCenter.default.publisher(for: UIDevice.batteryStateDidChangeNotification))
            .sink { [weak self] _ in self?.refreshBatteryProfile() }
            .store(in: &cancellables)
        #endif
        refreshBatteryProfile()
        startMotionUpdates()
    }

    // MARK: - Public

    /// Manually re-read the current battery state and emit a new profile.
    /// Useful after returning to foreground or when the system does not deliver a notification.
    public func refreshBatteryProfile() {
        batteryProfilePublisher.send(currentProfile())
    }

    // MARK: - Private

    private func currentProfile() -> BatteryProfile {
        #if canImport(UIKit)
        let level = UIDevice.current.batteryLevel
        // batteryLevel is -1 when monitoring is unavailable (e.g. Simulator, macOS)
        guard level >= 0 else { return .balanced }
        switch level {
        case ..<0.20: return .ultraLow
        case 0.20..<0.40: return .low
        case 0.40..<0.80: return .balanced
        default: return .high
        }
        #else
        return .balanced
        #endif
    }

    private func startMotionUpdates() {
        #if os(iOS)
        guard CMMotionActivityManager.isActivityAvailable() else { return }
        motionManager.startActivityUpdates(to: .main) { [weak self] activity in
            guard let self, let activity else { return }
            let stationary = activity.stationary
            if self.isStationary != stationary {
                self.isStationary = stationary
                self.isStationaryPublisher.send(stationary)
            }
        }
        #endif
    }
}
