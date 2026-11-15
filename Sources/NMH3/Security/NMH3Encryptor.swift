import CryptoKit
import Foundation

@available(iOS 15.0, macOS 13.0, *)
public final class NMH3Encryptor: Sendable {

    /// Errors thrown when an envelope cannot be decoded.
    public enum EnvelopeError: Error, Equatable {
        /// The envelope is not exactly `NMH3Encryptor.envelopeLength` bytes long.
        case invalidLength(Int)
        /// The decrypted payload is not an 8-byte H3 index.
        case invalidPayload
    }

    /// Size in bytes of the envelope produced by `encrypt(_:publicKey:)`.
    public static let envelopeLength = ephemeralKeyLength + nonceLength + indexLength + tagLength

    private static let ephemeralKeyLength = 65 // ANSI X9.63 uncompressed P-256 point (0x04 || X || Y)
    private static let nonceLength = 12
    private static let indexLength = 8
    private static let tagLength = 16
    private static let hkdfSalt = Data("NMH3-ECIES-v1".utf8)

    public init() {}

    /// Encrypts an H3 index for a recipient's P-256 public key.
    ///
    /// Scheme: ephemeral ECDH on P-256, HKDF-SHA256 key derivation, AES-256-GCM.
    ///
    /// Envelope layout (101 bytes):
    ///   [65 bytes: ephemeral P-256 public key, ANSI X9.63 uncompressed]
    ///   [12 bytes: AES-GCM nonce]
    ///   [ 8 bytes: ciphertext of the index, little-endian UInt64]
    ///   [16 bytes: AES-GCM authentication tag]
    ///
    /// Key derivation: HKDF-SHA256 over the ECDH shared secret with
    /// salt = "NMH3-ECIES-v1" (UTF-8), info = the 65-byte ephemeral public key,
    /// 32-byte output. A backend must use exactly these parameters to decrypt;
    /// `decrypt(_:privateKey:)` is the reference implementation.
    ///
    /// - Throws: `CryptoKitError` on key agreement or sealing failure.
    public func encrypt(_ h3Index: H3Index, publicKey: P256.KeyAgreement.PublicKey) throws -> Data {
        let ephemeralKey = P256.KeyAgreement.PrivateKey()
        let ephemeralPublic = ephemeralKey.publicKey.x963Representation

        let sharedSecret = try ephemeralKey.sharedSecretFromKeyAgreement(with: publicKey)
        let symmetricKey = Self.deriveKey(from: sharedSecret, ephemeralPublic: ephemeralPublic)

        let sealed = try AES.GCM.seal(Self.encode(h3Index), using: symmetricKey)

        var envelope = Data(capacity: Self.envelopeLength)
        envelope.append(ephemeralPublic)
        envelope.append(contentsOf: sealed.nonce)
        envelope.append(sealed.ciphertext)
        envelope.append(sealed.tag)
        return envelope
    }

    /// Decrypts an envelope produced by `encrypt(_:publicKey:)`.
    ///
    /// - Throws: `EnvelopeError` for a malformed envelope, `CryptoKitError` if the
    ///   key is wrong or the envelope was tampered with.
    public func decrypt(_ envelope: Data, privateKey: P256.KeyAgreement.PrivateKey) throws -> H3Index {
        guard envelope.count == Self.envelopeLength else {
            throw EnvelopeError.invalidLength(envelope.count)
        }
        let bytes = Data(envelope) // re-base indices at 0
        var offset = 0
        func take(_ n: Int) -> Data {
            defer { offset += n }
            return bytes.subdata(in: offset..<(offset + n))
        }
        let ephemeralPublic = take(Self.ephemeralKeyLength)
        let nonce = try AES.GCM.Nonce(data: take(Self.nonceLength))
        let ciphertext = take(Self.indexLength)
        let tag = take(Self.tagLength)

        let ephemeralKey = try P256.KeyAgreement.PublicKey(x963Representation: ephemeralPublic)
        let sharedSecret = try privateKey.sharedSecretFromKeyAgreement(with: ephemeralKey)
        let symmetricKey = Self.deriveKey(from: sharedSecret, ephemeralPublic: ephemeralPublic)

        let box = try AES.GCM.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: tag)
        return try Self.decode(AES.GCM.open(box, using: symmetricKey))
    }

    /// Encrypts an H3 index using AES-GCM with a pre-shared symmetric key.
    /// The plaintext is the index as a little-endian UInt64.
    public func seal(_ h3Index: H3Index, symmetricKey: SymmetricKey) throws -> AES.GCM.SealedBox {
        try AES.GCM.seal(Self.encode(h3Index), using: symmetricKey)
    }

    /// Decrypts a box produced by `seal(_:symmetricKey:)`.
    public func open(_ box: AES.GCM.SealedBox, symmetricKey: SymmetricKey) throws -> H3Index {
        try Self.decode(AES.GCM.open(box, using: symmetricKey))
    }

    // MARK: - Private

    private static func deriveKey(from secret: SharedSecret, ephemeralPublic: Data) -> SymmetricKey {
        secret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: hkdfSalt,
            sharedInfo: ephemeralPublic,
            outputByteCount: 32
        )
    }

    private static func encode(_ index: H3Index) -> Data {
        withUnsafeBytes(of: index.littleEndian) { Data($0) }
    }

    private static func decode(_ data: Data) throws -> H3Index {
        guard data.count == indexLength else { throw EnvelopeError.invalidPayload }
        var result: UInt64 = 0
        for (position, byte) in data.enumerated() {
            result |= UInt64(byte) << (8 * UInt64(position))
        }
        return result
    }
}
