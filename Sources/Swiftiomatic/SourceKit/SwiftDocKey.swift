// Vendored from SourceKitten (MIT) — see LICENSES/SourceKitten-MIT.txt

/// SourceKit response dictionary keys.
enum SwiftDocKey: String {
    case annotatedDeclaration = "key.annotated_decl"
    case bodyLength           = "key.bodylength"
    case bodyOffset           = "key.bodyoffset"
    case diagnosticStage      = "key.diagnostic_stage"
    case elements             = "key.elements"
    case filePath             = "key.filepath"
    case fullXMLDocs          = "key.doc.full_as_xml"
    case kind                 = "key.kind"
    case length               = "key.length"
    case name                 = "key.name"
    case nameLength           = "key.namelength"
    case nameOffset           = "key.nameoffset"
    case offset               = "key.offset"
    case substructure         = "key.substructure"
    case syntaxMap            = "key.syntaxmap"
    case typeName             = "key.typename"
    case inheritedtypes       = "key.inheritedtypes"

    case docColumn            = "key.doc.column"
    case documentationComment = "key.doc.comment"
    case docDeclaration       = "key.doc.declaration"
    case docDiscussion        = "key.doc.discussion"
    case docFile              = "key.doc.file"
    case docLine              = "key.doc.line"
    case docName              = "key.doc.name"
    case docParameters        = "key.doc.parameters"
    case docResultDiscussion  = "key.doc.result_discussion"
    case docType              = "key.doc.type"
    case usr                  = "key.usr"
    case parsedDeclaration    = "key.parsed_declaration"
    case parsedScopeEnd       = "key.parsed_scope.end"
    case parsedScopeStart     = "key.parsed_scope.start"
    case swiftDeclaration     = "key.swift_declaration"
    case swiftName            = "key.swift_name"
    case alwaysDeprecated     = "key.always_deprecated"
    case alwaysUnavailable    = "key.always_unavailable"
    case deprecationMessage   = "key.deprecation_message"
    case unavailableMessage   = "key.unavailable_message"
    case annotations          = "key.annotations"
    case attributes           = "key.attributes"
    case attribute            = "key.attribute"

    // MARK: Typed Getters

    private static func get<T>(_ key: SwiftDocKey, _ dictionary: [String: SourceKitRepresentable]) -> T? {
        dictionary[key.rawValue] as! T?
    }

    private static func getByteCount(_ key: SwiftDocKey, _ dictionary: [String: SourceKitRepresentable]) -> ByteCount? {
        (dictionary[key.rawValue] as! Int64?).map(ByteCount.init)
    }

    internal static func getKind(_ dictionary: [String: SourceKitRepresentable]) -> String? { get(.kind, dictionary) }
    internal static func getSyntaxMap(_ dictionary: [String: SourceKitRepresentable]) -> [SourceKitRepresentable]? { get(.syntaxMap, dictionary) }
    internal static func getOffset(_ dictionary: [String: SourceKitRepresentable]) -> ByteCount? { getByteCount(.offset, dictionary) }
    internal static func getLength(_ dictionary: [String: SourceKitRepresentable]) -> ByteCount? { getByteCount(.length, dictionary) }
    internal static func getName(_ dictionary: [String: SourceKitRepresentable]) -> String? { get(.name, dictionary) }
    internal static func getTypeName(_ dictionary: [String: SourceKitRepresentable]) -> String? { get(.typeName, dictionary) }
    internal static func getAnnotatedDeclaration(_ dictionary: [String: SourceKitRepresentable]) -> String? { get(.annotatedDeclaration, dictionary) }
    internal static func getSubstructure(_ dictionary: [String: SourceKitRepresentable]) -> [[String: SourceKitRepresentable]]? { get(.substructure, dictionary) }
    internal static func getNameOffset(_ dictionary: [String: SourceKitRepresentable]) -> ByteCount? { getByteCount(.nameOffset, dictionary) }
    internal static func getNameLength(_ dictionary: [String: SourceKitRepresentable]) -> ByteCount? { getByteCount(.nameLength, dictionary) }
    internal static func getBodyOffset(_ dictionary: [String: SourceKitRepresentable]) -> ByteCount? { getByteCount(.bodyOffset, dictionary) }
    internal static func getBodyLength(_ dictionary: [String: SourceKitRepresentable]) -> ByteCount? { getByteCount(.bodyLength, dictionary) }
    internal static func getFullXMLDocs(_ dictionary: [String: SourceKitRepresentable]) -> String? { get(.fullXMLDocs, dictionary) }
}

extension SwiftDocKey {
    internal static func getBestOffset(_ dictionary: [String: SourceKitRepresentable]) -> ByteCount? {
        if let nameOffset = getNameOffset(dictionary), nameOffset > 0 {
            return nameOffset
        }
        return getOffset(dictionary)
    }
}
