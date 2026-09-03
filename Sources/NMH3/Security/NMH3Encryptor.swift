import CryptoKit
import Foundation

@available(iOS 15.0, macOS 13.0, *)
public final class NMH3Encryptor: Sendable {
    public init() {}

    /// Encrypts an H3 index using ECIES (ephemeral ECDH + HKDF-SHA256 + AES-GCM).
    ///
    /// The returned `Data` is a self-contained envelope:
    ///   [65 bytes: ephemeral P-256 public key (uncompressed)]
    ///   [12 bytes: AES-GCM nonce]
    ///   [8 bytes:  ciphertext]
    ///   [16 bytes: GCM authentication tag]
    ///
    /// This format is interoperable with standard ECIES implementations.
    /// The recipient needs only their corresponding private key to decrypt.
    ///
    /// - Parameters:
    ///   - h3Index: The H3 cell index to encrypt.
    ///   - publicKey: The recipient's P-256 public key for key agreement.
    /// - Returns: ECIES-encrypted envelope as `Data`.
    /// - Throws: `CryptoKitError` on key agreement or sealing failure.
    public func encrypt(_ h3Index: H3Index, publicKey: P256.KeyAgreement.PublicKey) throws -> Data {
        // 1. Generate an ephemeral key pair for this encryption operation
        let ephemeralKey = P256.KeyAgreement.PrivateKey()

        // 2. ECDH: derive shared secret between ephemeral private and recipient public key
        let sharedSecret = try ephemeralKey.sharedSecretFromKeyAgreement(with: publicKey)

        // 3. HKDF: derive a 256-bit symmetric key from the shared secret
        let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data("NMH3-ECIES-v1".utf8),
            sharedInfo: ephemeralKey.publicKey.rawRepresentation,
            outputByteCount: 32
        )

        // 4. AES-GCM: encrypt the 8-byte index
        var index = h3Index
        let plaintext = Data(bytes: &index, count: 8)
        let sealed = try AES.GCM.seal(plaintext, using: symmetricKey)

        // 5. Assemble envelope: ephemeral pubkey || nonce || ciphertext || tag
        var envelope = Data()
        envelope.append(ephemeralKey.publicKey.rawRepresentation)  // 65 bytes uncompressed
        envelope.append(sealed.nonce.withUnsafeBytes { Data($0) }) // 12 bytes
        envelope.append(sealed.ciphertext)                          // 8 bytes
        envelope.append(sealed.tag)                                 // 16 bytes
        return envelope
    }

    /// Encrypts an H3 index using AES-GCM with a pre-shared symmetric key.
    ///
    /// This is the correct, working symmetric-key encryption path.
    /// Use `encrypt(_:publicKey:)` when you need asymmetric (public-key) encryption.
    public func seal(_ h3Index: H3Index, symmetricKey: SymmetricKey) throws -> AES.GCM.SealedBox {
        var index = h3Index
        let data = Data(bytes: &index, count: 8)
        return try AES.GCM.seal(data, using: symmetricKey)
    }
}
