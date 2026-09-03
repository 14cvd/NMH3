import Foundation

@available(iOS 15.0, *)
public final class NMH3JailbreakDetector: Sendable {
    public init() {}

    /// Returns `true` if the device shows signs of being jailbroken.
    ///
    /// - Important: This is a **best-effort heuristic**, not a security boundary.
    ///   Static file-path checks (Cydia, MobileSubstrate, etc.) are trivially bypassed
    ///   by any modern path-hiding jailbreak tweak. The sandbox write test (`/private/`)
    ///   adds a small additional layer but is also bypassable.
    ///
    ///   Do **not** use the result of this method as the sole gate for sensitive
    ///   operations. Treat it as a weak signal to be combined with server-side checks,
    ///   certificate pinning, and other defence-in-depth measures.
    public func isCompromised() -> Bool {
        let paths = [
            "/Applications/Cydia.app",
            "/usr/sbin/sshd",
            "/bin/bash",
            "/Library/MobileSubstrate/MobileSubstrate.dylib"
        ]
        for path in paths {
            if FileManager.default.fileExists(atPath: path) { return true }
        }
        do {
            let testPath = "/private/jailbreak.txt"
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testPath)
            return true
        } catch {
            return false
        }
    }
}
