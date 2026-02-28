// Vendored from SourceKitten (MIT) — see LICENSES/SourceKitten-MIT.txt

/// Represents a Swift file's syntax information.
struct SyntaxMap {
    let tokens: [SyntaxToken]

    init(tokens: [SyntaxToken]) {
        self.tokens = tokens
    }

    init(data: [SourceKitRepresentable]) {
        tokens = data.map { item in
            let dict = item as! [String: SourceKitRepresentable]
            return SyntaxToken(type: dict["key.kind"] as! String, offset: ByteCount(dict["key.offset"] as! Int64),
                               length: ByteCount(dict["key.length"] as! Int64))
        }
    }

    init(sourceKitResponse: [String: SourceKitRepresentable]) {
        self.init(data: SwiftDocKey.getSyntaxMap(sourceKitResponse)!)
    }

    init(file: File) throws {
        self.init(sourceKitResponse: try Request.editorOpen(file: file).send())
    }
}

// MARK: Support for enumerating doc-comment blocks

extension SyntaxToken {
    internal var isDocComment: Bool {
        SourceKitSyntaxKind.docComments().contains { $0.rawValue == type }
    }
}

extension SyntaxMap {
    internal var docCommentRanges: [ByteRange] {
        let docCommentBlocks = tokens.split { !$0.isDocComment }
        return docCommentBlocks.compactMap { ranges in
            ranges.first.flatMap { first in
                ranges.last.flatMap { last -> ByteRange? in
                    ByteRange(location: first.offset, length: last.offset + last.length - first.offset)
                }
            }
        }
    }

    internal final class DocCommentFinder {
        private var ranges: [ByteRange]
        private var previousOffset: ByteCount?

        internal init(syntaxMap: SyntaxMap) {
            self.ranges = syntaxMap.docCommentRanges
            self.previousOffset = nil
        }

        internal func getRangeForDeclaration(atOffset offset: ByteCount) -> ByteRange? {
            if let previousOffset = previousOffset {
                guard offset > previousOffset else { return nil }
            }

            let commentsBeforeDecl = ranges.prefix { $0.upperBound < offset }
            ranges.replaceSubrange(0..<commentsBeforeDecl.count, with: [])
            previousOffset = offset
            return commentsBeforeDecl.last
        }
    }

    internal func createDocCommentFinder() -> DocCommentFinder {
        DocCommentFinder(syntaxMap: self)
    }
}

extension SyntaxMap: CustomStringConvertible {
    var description: String {
        toJSON(tokens.map { $0.dictionaryValue })
    }
}

extension SyntaxMap: Equatable {}

func == (lhs: SyntaxMap, rhs: SyntaxMap) -> Bool {
    if lhs.tokens.count != rhs.tokens.count { return false }
    for (index, value) in lhs.tokens.enumerated() where rhs.tokens[index] != value {
        return false
    }
    return true
}
