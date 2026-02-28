// Vendored from SourceKitten (MIT) — see LICENSES/SourceKitten-MIT.txt

/// Represents a single Swift syntax token.
struct SyntaxToken {
    let type: String
    let offset: ByteCount
    let length: ByteCount

    var dictionaryValue: [String: Any] {
        ["type": type, "offset": offset.value, "length": length.value]
    }

    init(type: String, offset: ByteCount, length: ByteCount) {
        self.type = SourceKitSyntaxKind(rawValue: type)?.rawValue ?? type
        self.offset = offset
        self.length = length
    }

    var range: ByteRange {
        ByteRange(location: offset, length: length)
    }
}

extension SyntaxToken: Equatable {}

func == (lhs: SyntaxToken, rhs: SyntaxToken) -> Bool {
    (lhs.type == rhs.type) && (lhs.offset == rhs.offset) && (lhs.length == rhs.length)
}

extension SyntaxToken: CustomStringConvertible {
    var description: String { toJSON(dictionaryValue.bridge()) }
}
