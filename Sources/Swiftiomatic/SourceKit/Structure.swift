/// The structural information in a Swift source file as returned by SourceKit's `editor.open`
struct Structure: Equatable {
    /// The raw SourceKit response dictionary (with `key.syntaxmap` removed)
    let dictionary: [String: SourceKitValue]

    /// Create a structure from a raw SourceKit response, stripping the syntax map
    ///
    /// - Parameters:
    ///   - sourceKitResponse: The full response dictionary from an `editor.open` request.
    init(sourceKitResponse: [String: SourceKitValue]) {
        var sourceKitResponse = sourceKitResponse
        _ = sourceKitResponse.removeValue(forKey: SwiftDocKey.syntaxMap.rawValue)
        dictionary = sourceKitResponse
    }

    /// Create a structure by sending an `editor.open` request for the given file
    ///
    /// - Parameters:
    ///   - file: The ``File`` to open in SourceKit.
    init(file: File) throws(Request.Error) {
        try self.init(sourceKitResponse: Request.editorOpen(file: file).send())
    }
}

extension Structure: CustomStringConvertible {
    var description: String { toJSON(dictionary) }
}
