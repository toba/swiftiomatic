/// Represents the structural information in a Swift source file.
struct Structure: Equatable {
    let dictionary: [String: SourceKitValue]

    init(sourceKitResponse: [String: SourceKitValue]) {
        var sourceKitResponse = sourceKitResponse
        _ = sourceKitResponse.removeValue(forKey: SwiftDocKey.syntaxMap.rawValue)
        dictionary = sourceKitResponse
    }

    init(file: File) throws(Request.Error) {
        try self.init(sourceKitResponse: Request.editorOpen(file: file).send())
    }
}

extension Structure: CustomStringConvertible {
    var description: String { toJSON(dictionary) }
}
