import CoreLocation

@available(iOS 15.0, *)
public final class NMH3PrivacyLayer: Sendable {
    public init() {}

    /// Converts a `CLLocation` into an H3 cell index at resolution 9.
    ///
    /// - Note: This method does **not** scrub the raw coordinate from memory.
    ///   `CLLocationCoordinate2D` is a Swift value type; zeroing a local copy has no
    ///   effect on the original `CLLocation` object passed by the OS. True memory scrubbing
    ///   of Foundation objects is not achievable through this pattern on Apple platforms.
    ///   The privacy benefit here is narrower but real: raw coordinates are never stored in
    ///   any property or logged — only the H3 cell index is returned and used downstream.
    public func processLocation(_ location: CLLocation) -> H3Index {
        NMH3Kit.shared.cell(for: location.coordinate, resolution: .r9).index
    }

    /// Returns a randomised H3 index within `fuzz` grid steps of the given index.
    ///
    /// Use this before sending indices to analytics backends to reduce spatial precision
    /// without destroying the coarse-grained signal. A `fuzz` of 1 keeps the user within
    /// one hex step (~150 m at resolution 9); higher values increase anonymity further.
    public func obfuscatedIndex(_ index: H3Index, fuzz: Int = 1) -> H3Index {
        let ring = NMH3Kit.shared.kRing(around: H3Cell(index: index), k: fuzz)
        return ring.randomElement()?.index ?? index
    }
}
