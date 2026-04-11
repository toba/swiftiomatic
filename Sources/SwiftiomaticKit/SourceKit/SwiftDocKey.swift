/// SourceKit response dictionary keys (`key.*` strings)
///
/// Provides both raw key constants and typed static accessors that extract
/// values from a `[String: SourceKitValue]` dictionary.
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

  // MARK: Typed Accessors

  private static func string(
    _ key: SwiftDocKey, from dictionary: [String: SourceKitValue],
  ) -> String? {
    dictionary[key.rawValue]?.stringValue
  }

  private static func byteCount(
    _ key: SwiftDocKey, from dictionary: [String: SourceKitValue],
  ) -> ByteCount? {
    dictionary[key.rawValue]?.int64Value.map(ByteCount.init)
  }

  /// Extract the `key.kind` string from a response dictionary
  ///
  /// - Parameters:
  ///   - dictionary: The SourceKit response dictionary.
  static func kind(from dictionary: [String: SourceKitValue]) -> String? {
    string(.kind, from: dictionary)
  }

  /// Extract the `key.syntaxmap` array from a response dictionary
  ///
  /// - Parameters:
  ///   - dictionary: The SourceKit response dictionary.
  static func syntaxMap(from dictionary: [String: SourceKitValue]) -> [SourceKitValue]? {
    dictionary[syntaxMap.rawValue]?.arrayValue
  }

  /// Extract the `key.offset` byte count from a response dictionary
  ///
  /// - Parameters:
  ///   - dictionary: The SourceKit response dictionary.
  static func offset(from dictionary: [String: SourceKitValue]) -> ByteCount? {
    byteCount(.offset, from: dictionary)
  }

  /// Extract the `key.length` byte count from a response dictionary
  ///
  /// - Parameters:
  ///   - dictionary: The SourceKit response dictionary.
  static func length(from dictionary: [String: SourceKitValue]) -> ByteCount? {
    byteCount(.length, from: dictionary)
  }

  /// Extract the `key.name` string from a response dictionary
  ///
  /// - Parameters:
  ///   - dictionary: The SourceKit response dictionary.
  static func name(from dictionary: [String: SourceKitValue]) -> String? {
    string(.name, from: dictionary)
  }

  /// Extract the `key.typename` string from a response dictionary
  ///
  /// - Parameters:
  ///   - dictionary: The SourceKit response dictionary.
  static func typeName(from dictionary: [String: SourceKitValue]) -> String? {
    string(.typeName, from: dictionary)
  }

  /// Extract the `key.annotated_decl` string from a response dictionary
  ///
  /// - Parameters:
  ///   - dictionary: The SourceKit response dictionary.
  static func annotatedDeclaration(from dictionary: [String: SourceKitValue]) -> String? {
    string(.annotatedDeclaration, from: dictionary)
  }

  /// Extract the `key.substructure` array of dictionaries from a response dictionary
  ///
  /// - Parameters:
  ///   - dictionary: The SourceKit response dictionary.
  static func substructure(from dictionary: [String: SourceKitValue]) -> [[String:
    SourceKitValue]]?
  {
    dictionary[substructure.rawValue]?.arrayValue?.compactMap(\.dictionaryValue)
  }

  /// Extract the `key.nameoffset` byte count from a response dictionary
  ///
  /// - Parameters:
  ///   - dictionary: The SourceKit response dictionary.
  static func nameOffset(from dictionary: [String: SourceKitValue]) -> ByteCount? {
    byteCount(.nameOffset, from: dictionary)
  }

  /// Extract the `key.namelength` byte count from a response dictionary
  ///
  /// - Parameters:
  ///   - dictionary: The SourceKit response dictionary.
  static func nameLength(from dictionary: [String: SourceKitValue]) -> ByteCount? {
    byteCount(.nameLength, from: dictionary)
  }

  /// Extract the `key.bodyoffset` byte count from a response dictionary
  ///
  /// - Parameters:
  ///   - dictionary: The SourceKit response dictionary.
  static func bodyOffset(from dictionary: [String: SourceKitValue]) -> ByteCount? {
    byteCount(.bodyOffset, from: dictionary)
  }

  /// Extract the `key.bodylength` byte count from a response dictionary
  ///
  /// - Parameters:
  ///   - dictionary: The SourceKit response dictionary.
  static func bodyLength(from dictionary: [String: SourceKitValue]) -> ByteCount? {
    byteCount(.bodyLength, from: dictionary)
  }

  /// Extract the `key.doc.full_as_xml` string from a response dictionary
  ///
  /// - Parameters:
  ///   - dictionary: The SourceKit response dictionary.
  static func fullXMLDocs(from dictionary: [String: SourceKitValue]) -> String? {
    string(.fullXMLDocs, from: dictionary)
  }

  /// Return the name offset if available and non-zero, otherwise fall back to the general offset
  ///
  /// - Parameters:
  ///   - dictionary: The SourceKit response dictionary.
  static func bestOffset(from dictionary: [String: SourceKitValue]) -> ByteCount? {
    if let nameOffset = nameOffset(from: dictionary), nameOffset > 0 {
      return nameOffset
    }
    return offset(from: dictionary)
  }
}
