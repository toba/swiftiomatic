import Foundation
import CommonCrypto

extension Data {
    func sha256() -> Data {
        withUnsafeBytes { bytes in
            var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
            _ = CC_SHA256(bytes.baseAddress, CC_LONG(count), &hash)
            return Data(hash)
        }
    }

    var hexString: String {
        let hexDigits = Array("0123456789abcdef".unicodeScalars)
        var result = ""
        result.reserveCapacity(count * 2)
        for byte in self {
            result.unicodeScalars.append(hexDigits[Int(byte >> 4)])
            result.unicodeScalars.append(hexDigits[Int(byte & 0x0F)])
        }
        return result
    }
}

extension String {
    func sha256() -> String {
        // UTF-8 encoding of a Swift String cannot fail (String is always valid Unicode)
        data(using: .utf8)!.sha256().hexString
    }
}
