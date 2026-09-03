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
        tampered[0] ^= 0xFF
        XCTAssertThrowsError(
            try AES.GCM.open(
                AES.GCM.SealedBox(nonce: sealed.nonce, ciphertext: tampered, tag: sealed.tag),
                using: key
            ),
            "Opening tampered ciphertext must throw an authentication error"
        )
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
