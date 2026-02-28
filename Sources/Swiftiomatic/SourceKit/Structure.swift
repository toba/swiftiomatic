// Vendored from SourceKitten (MIT) — see LICENSES/SourceKitten-MIT.txt

/// Represents the structural information in a Swift source file.
struct Structure {
    let dictionary: [String: SourceKitRepresentable]

    init(sourceKitResponse: [String: SourceKitRepresentable]) {
        var sourceKitResponse = sourceKitResponse
        _ = sourceKitResponse.removeValue(forKey: SwiftDocKey.syntaxMap.rawValue)
        dictionary = sourceKitResponse
    }

    init(file: File) throws {
        self.init(sourceKitResponse: try Request.editorOpen(file: file).send())
    }
}

extension Structure: CustomStringConvertible {
    var description: String { toJSON(toNSDictionary(dictionary)) }
}

extension Structure: Equatable {}

func == (lhs: Structure, rhs: Structure) -> Bool {
    lhs.dictionary.isEqualTo(rhs.dictionary)
}
