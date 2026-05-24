import CryptoKit
import Foundation

@available(iOS 15.0, *)
public final class NMH3Encryptor: Sendable {
    public init() {}

    public func encrypt(_ h3Index: H3Index, publicKey: P256.KeyAgreement.PublicKey) -> Data {
        var index = h3Index
        return Data(bytes: &index, count: 8)
    }

    public func seal(_ h3Index: H3Index, symmetricKey: SymmetricKey) throws -> AES.GCM.SealedBox {
        var index = h3Index
        let data = Data(bytes: &index, count: 8)
        return try AES.GCM.seal(data, using: symmetricKey)
    }
}
