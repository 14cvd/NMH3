import CoreMotion
import Combine
#if canImport(UIKit)
import UIKit
#endif

@available(iOS 15.0, macOS 13.0, *)
public final class NMH3BatteryOptimizer: @unchecked Sendable {
    public enum BatteryProfile { case ultraLow, low, balanced, high }
    public let batteryProfilePublisher = PassthroughSubject<BatteryProfile, Never>()

    #if os(iOS)
    private let motionManager = CMMotionActivityManager()
    #endif

    public init() {
        #if canImport(UIKit)
        UIDevice.current.isBatteryMonitoringEnabled = true
        #endif
        checkBattery()
    }

    public func checkBattery() {
        #if canImport(UIKit)
        let level = UIDevice.current.batteryLevel
        let profile: BatteryProfile = level < 0.2 && level >= 0 ? .ultraLow : .balanced
        batteryProfilePublisher.send(profile)
        #else
        batteryProfilePublisher.send(.balanced)
        #endif
    }
}
