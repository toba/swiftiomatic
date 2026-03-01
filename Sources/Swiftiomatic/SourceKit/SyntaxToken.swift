/// Represents a single Swift syntax token.
struct SyntaxToken: Equatable, Encodable {
    let type: String
    let offset: ByteCount
    let length: ByteCount

    init(type: String, offset: ByteCount, length: ByteCount) {
        self.type = SourceKitSyntaxKind(rawValue: type)?.rawValue ?? type
        self.offset = offset
        self.length = length
    }

    var range: ByteRange {
        ByteRange(location: offset, length: length)
    }

    private enum CodingKeys: String, CodingKey {
        case type, offset, length
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(offset.value, forKey: .offset)
        try container.encode(length.value, forKey: .length)
    }
}

extension SyntaxToken: CustomStringConvertible {
    var description: String { toJSON(self) }
}
