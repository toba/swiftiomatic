/// SourceKit response dictionary keys.
enum SwiftDocKey: String {
    case annotatedDeclaration = "key.annotated_decl"
    case bodyLength = "key.bodylength"
    case bodyOffset = "key.bodyoffset"
    case diagnosticStage = "key.diagnostic_stage"
    case elements = "key.elements"
    case filePath = "key.filepath"
    case fullXMLDocs = "key.doc.full_as_xml"
    case kind = "key.kind"
    case length = "key.length"
    case name = "key.name"
    case nameLength = "key.namelength"
    case nameOffset = "key.nameoffset"
    case offset = "key.offset"
    case substructure = "key.substructure"
    case syntaxMap = "key.syntaxmap"
    case typeName = "key.typename"
    case inheritedtypes = "key.inheritedtypes"

    case docColumn = "key.doc.column"
    case documentationComment = "key.doc.comment"
    case docDeclaration = "key.doc.declaration"
    case docDiscussion = "key.doc.discussion"
    case docFile = "key.doc.file"
    case docLine = "key.doc.line"
    case docName = "key.doc.name"
    case docParameters = "key.doc.parameters"
    case docResultDiscussion = "key.doc.result_discussion"
    case docType = "key.doc.type"
    case usr = "key.usr"
    case parsedDeclaration = "key.parsed_declaration"
    case parsedScopeEnd = "key.parsed_scope.end"
    case parsedScopeStart = "key.parsed_scope.start"
    case swiftDeclaration = "key.swift_declaration"
    case swiftName = "key.swift_name"
    case alwaysDeprecated = "key.always_deprecated"
    case alwaysUnavailable = "key.always_unavailable"
    case deprecationMessage = "key.deprecation_message"
    case unavailableMessage = "key.unavailable_message"
    case annotations = "key.annotations"
    case attributes = "key.attributes"
    case attribute = "key.attribute"

    // MARK: Typed Getters

    private static func getString(
        _ key: SwiftDocKey, _ dictionary: [String: SourceKitValue],
    ) -> String? {
        dictionary[key.rawValue]?.stringValue
    }

    private static func getByteCount(
        _ key: SwiftDocKey, _ dictionary: [String: SourceKitValue],
    ) -> ByteCount? {
        dictionary[key.rawValue]?.int64Value.map(ByteCount.init)
    }

    static func getKind(_ dictionary: [String: SourceKitValue]) -> String? {
        getString(.kind, dictionary)
    }

    static func getSyntaxMap(_ dictionary: [String: SourceKitValue])
        -> [SourceKitValue]?
    { dictionary[syntaxMap.rawValue]?.arrayValue }
    static func getOffset(_ dictionary: [String: SourceKitValue]) -> ByteCount? {
        getByteCount(.offset, dictionary)
    }

    static func getLength(_ dictionary: [String: SourceKitValue]) -> ByteCount? {
        getByteCount(.length, dictionary)
    }

    static func getName(_ dictionary: [String: SourceKitValue]) -> String? {
        getString(.name, dictionary)
    }

    static func getTypeName(_ dictionary: [String: SourceKitValue]) -> String? {
        getString(.typeName, dictionary)
    }

    static func getAnnotatedDeclaration(_ dictionary: [String: SourceKitValue])
        -> String?
    { getString(.annotatedDeclaration, dictionary) }
    static func getSubstructure(_ dictionary: [String: SourceKitValue]) -> [[String:
            SourceKitValue]]?
    {
        dictionary[substructure.rawValue]?.arrayValue?.compactMap(\.dictionaryValue)
    }

    static func getNameOffset(_ dictionary: [String: SourceKitValue]) -> ByteCount? {
        getByteCount(.nameOffset, dictionary)
    }

    static func getNameLength(_ dictionary: [String: SourceKitValue]) -> ByteCount? {
        getByteCount(.nameLength, dictionary)
    }

    static func getBodyOffset(_ dictionary: [String: SourceKitValue]) -> ByteCount? {
        getByteCount(.bodyOffset, dictionary)
    }

    static func getBodyLength(_ dictionary: [String: SourceKitValue]) -> ByteCount? {
        getByteCount(.bodyLength, dictionary)
    }

    static func getFullXMLDocs(_ dictionary: [String: SourceKitValue]) -> String? {
        getString(.fullXMLDocs, dictionary)
    }
}

extension SwiftDocKey {
    static func getBestOffset(_ dictionary: [String: SourceKitValue]) -> ByteCount? {
        if let nameOffset = getNameOffset(dictionary), nameOffset > 0 {
            return nameOffset
        }
        return getOffset(dictionary)
    }
}
