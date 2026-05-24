import Foundation

@available(iOS 15.0, *)
public final class NMH3JailbreakDetector: Sendable {
    public init() {}

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
