import NMCH3

public enum H3Resolution: Int, CaseIterable, Sendable, Codable {
    case r0 = 0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13, r14, r15
    public var hexRadiusKm: Double { NMH3HexRadiusKm(self.rawValue) }
    public var hexAreaKm2: Double { NMH3HexAreaKm2(self.rawValue) }
    public var edgeLengthKm: Double { NMH3EdgeLengthKm(self.rawValue) }
}
