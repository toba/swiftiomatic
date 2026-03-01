/// A single Swift syntax token from a SourceKit syntax map
struct SyntaxToken: Equatable, Encodable {
    /// The SourceKit syntax type UID string (e.g. `source.lang.swift.syntaxtype.keyword`)
    let type: String
    /// The starting byte offset in the source file
    let offset: ByteCount
    /// The length of this token in bytes
    let length: ByteCount

    /// Create a syntax token
    ///
    /// Normalizes the type string through ``SourceKitSyntaxKind`` if recognized.
    ///
    /// - Parameters:
    ///   - type: The SourceKit syntax type UID string.
    ///   - offset: The byte offset.
    ///   - length: The byte length.
    init(type: String, offset: ByteCount, length: ByteCount) {
        self.type = SourceKitSyntaxKind(rawValue: type)?.rawValue ?? type
        self.offset = offset
        self.length = length
    }

    /// The ``ByteRange`` spanning this token
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
