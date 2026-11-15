import XCTest
@testable import NMH3
import CryptoKit

@available(iOS 15.0, macOS 13.0, *)
final class H3SecurityTests: XCTestCase {

    private let encryptor = NMH3Encryptor()

    // MARK: - ECIES encrypt() tests

    func testEncryptProducesNonPlaintextData() throws {
        let recipientKey = P256.KeyAgreement.PrivateKey()
        let index: H3Index = 0x8928308280fffff

        let ciphertext = try encryptor.encrypt(index, publicKey: recipientKey.publicKey)

        // The raw 8-byte index must NOT appear as a contiguous sequence in the output
        var rawIndex = index
        let indexBytes = Data(bytes: &rawIndex, count: 8)

        // Search for the 8-byte sequence in the ciphertext
        let found = ciphertext.windows(ofCount: 8).contains { Data($0) == indexBytes }
        XCTAssertFalse(found, "Plaintext index bytes must not appear in ECIES ciphertext")
    }

    func testEncryptProducesDifferentOutputEachCall() throws {
        // ECIES uses an ephemeral key — every encryption of the same plaintext must differ
        let recipientKey = P256.KeyAgreement.PrivateKey()
        let index: H3Index = 0x8928308280fffff

        let ct1 = try encryptor.encrypt(index, publicKey: recipientKey.publicKey)
        let ct2 = try encryptor.encrypt(index, publicKey: recipientKey.publicKey)

        XCTAssertNotEqual(ct1, ct2, "Two ECIES encryptions of the same plaintext must produce different ciphertext (ephemeral key)")
    }

    func testEncryptEnvelopeHasExpectedLength() throws {
        let recipientKey = P256.KeyAgreement.PrivateKey()
        let ciphertext = try encryptor.encrypt(0x8928308280fffff, publicKey: recipientKey.publicKey)

        // 65 (uncompressed P-256 pubkey) + 12 (GCM nonce) + 8 (ciphertext) + 16 (GCM tag)
        let expectedLength = 65 + 12 + 8 + 16
        XCTAssertEqual(ciphertext.count, expectedLength, "ECIES envelope must have exactly \(expectedLength) bytes")
    }

    // MARK: - Symmetric seal() tests

    func testSealAndOpenRoundTrip() throws {
        let key = SymmetricKey(size: .bits256)
        let index: H3Index = 0x8928308280fffff

        let sealed = try encryptor.seal(index, symmetricKey: key)
        let opened = try AES.GCM.open(sealed, using: key)

        var recovered: H3Index = 0
        _ = opened.withUnsafeBytes { ptr in
            memcpy(&recovered, ptr.baseAddress!, 8)
        }
        XCTAssertEqual(recovered, index, "seal() → open() round-trip must recover original H3 index")
    }

    func testSealProducesAuthenticatedCiphertext() throws {
        let key = SymmetricKey(size: .bits256)
        let sealed = try encryptor.seal(0x8928308280fffff, symmetricKey: key)

        // Tampered ciphertext must fail authentication
        var tampered = sealed.ciphertext
        tampered[tampered.startIndex] ^= 0xFF
        XCTAssertThrowsError(
            try AES.GCM.open(
                AES.GCM.SealedBox(nonce: sealed.nonce, ciphertext: tampered, tag: sealed.tag),
                using: key
            ),
            "Opening tampered ciphertext must throw an authentication error"
        )
    }

    // MARK: - decrypt() / open() tests

    func testEncryptDecryptRoundTrip() throws {
        let recipientKey = P256.KeyAgreement.PrivateKey()
        let index: H3Index = 0x8928308280fffff

        let envelope = try encryptor.encrypt(index, publicKey: recipientKey.publicKey)
        XCTAssertEqual(envelope.first, 0x04, "Envelope must start with an uncompressed X9.63 point")
        XCTAssertEqual(try encryptor.decrypt(envelope, privateKey: recipientKey), index)
    }

    func testDecryptWithWrongKeyThrows() throws {
        let recipientKey = P256.KeyAgreement.PrivateKey()
        let envelope = try encryptor.encrypt(0x8928308280fffff, publicKey: recipientKey.publicKey)

        XCTAssertThrowsError(try encryptor.decrypt(envelope, privateKey: P256.KeyAgreement.PrivateKey()))
    }

    func testDecryptTamperedEnvelopeThrows() throws {
        let recipientKey = P256.KeyAgreement.PrivateKey()
        var envelope = try encryptor.encrypt(0x8928308280fffff, publicKey: recipientKey.publicKey)
        envelope[envelope.index(envelope.startIndex, offsetBy: 80)] ^= 0x01 // inside the ciphertext

        XCTAssertThrowsError(try encryptor.decrypt(envelope, privateKey: recipientKey))
    }

    func testDecryptRejectsWrongLength() {
        XCTAssertThrowsError(try encryptor.decrypt(Data(count: 100), privateKey: P256.KeyAgreement.PrivateKey())) { error in
            XCTAssertEqual(error as? NMH3Encryptor.EnvelopeError, .invalidLength(100))
        }
    }

    func testDecryptAcceptsSlicedEnvelope() throws {
        let recipientKey = P256.KeyAgreement.PrivateKey()
        let index: H3Index = 0x8928308280fffff
        let envelope = try encryptor.encrypt(index, publicKey: recipientKey.publicKey)
        let framed = Data([0xAA, 0xBB]) + envelope
        let slice = framed[framed.index(framed.startIndex, offsetBy: 2)...]

        XCTAssertEqual(try encryptor.decrypt(Data(slice), privateKey: recipientKey), index)
        XCTAssertEqual(try encryptor.decrypt(slice, privateKey: recipientKey), index)
    }

    func testSealOpenRoundTrip() throws {
        let key = SymmetricKey(size: .bits256)
        let index: H3Index = 0x8928308280fffff

        let box = try encryptor.seal(index, symmetricKey: key)
        XCTAssertEqual(try encryptor.open(box, symmetricKey: key), index)
    }
}

// MARK: - Helpers

private extension Data {
    func windows(ofCount size: Int) -> AnySequence<Data.SubSequence> {
        guard count >= size else { return AnySequence([]) }
        return AnySequence((0...(count - size)).lazy.map { i in
            self[i..<(i + size)]
        })
    }
}
