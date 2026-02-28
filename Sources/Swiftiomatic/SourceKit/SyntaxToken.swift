/// Represents a single Swift syntax token.
struct SyntaxToken: Equatable {
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

extension SyntaxToken: CustomStringConvertible {
    var description: String { toJSON(dictionaryValue.bridge()) }
}
