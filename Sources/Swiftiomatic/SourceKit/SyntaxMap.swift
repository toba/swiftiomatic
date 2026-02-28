/// Represents a Swift file's syntax information.
struct SyntaxMap: Equatable {
    let tokens: [SyntaxToken]

    init(tokens: [SyntaxToken]) {
        self.tokens = tokens
    }

    init(data: [SourceKitValue]) {
        tokens = data.compactMap { item in
            guard let dict = item.dictionaryValue,
                  let type = dict["key.kind"]?.stringValue,
                  let offset = dict["key.offset"]?.int64Value,
                  let length = dict["key.length"]?.int64Value
            else { return nil }
            return SyntaxToken(type: type, offset: ByteCount(offset), length: ByteCount(length))
        }
    }

    init(sourceKitResponse: [String: SourceKitValue]) {
        self.init(data: SwiftDocKey.getSyntaxMap(sourceKitResponse) ?? [])
    }

    init(file: File) throws(Request.Error) {
        try self.init(sourceKitResponse: Request.editorOpen(file: file).send())
    }
}

// MARK: Support for enumerating doc-comment blocks

extension SyntaxToken {
    var isDocComment: Bool {
        SourceKitSyntaxKind.docComments().contains { $0.rawValue == type }
    }
}

extension SyntaxMap {
    var docCommentRanges: [ByteRange] {
        let docCommentBlocks = tokens.split { !$0.isDocComment }
        return docCommentBlocks.compactMap { ranges in
            ranges.first.flatMap { first in
                ranges.last.flatMap { last -> ByteRange? in
                    ByteRange(
                        location: first.offset,
                        length: last.offset + last.length - first.offset,
                    )
                }
            }
        }
    }

    final class DocCommentFinder {
        private var ranges: [ByteRange]
        private var previousOffset: ByteCount?

        init(syntaxMap: SyntaxMap) {
            ranges = syntaxMap.docCommentRanges
            previousOffset = nil
        }

        func getRangeForDeclaration(atOffset offset: ByteCount) -> ByteRange? {
            if let previousOffset {
                guard offset > previousOffset else { return nil }
            }

            let commentsBeforeDecl = ranges.prefix { $0.upperBound < offset }
            ranges.removeFirst(commentsBeforeDecl.count)
            previousOffset = offset
            return commentsBeforeDecl.last
        }
    }

    func createDocCommentFinder() -> DocCommentFinder {
        DocCommentFinder(syntaxMap: self)
    }
}

extension SyntaxMap: CustomStringConvertible {
    var description: String {
        toJSON(tokens.map(\.dictionaryValue))
    }
}
