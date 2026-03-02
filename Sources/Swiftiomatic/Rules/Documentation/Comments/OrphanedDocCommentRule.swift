import SwiftSyntax

struct OrphanedDocCommentRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = OrphanedDocCommentConfiguration()
}

extension OrphanedDocCommentRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension OrphanedDocCommentRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: TokenSyntax) {
      let pieces = node.leadingTrivia.pieces
      var iterator = pieces.enumerated().makeIterator()
      while let (index, piece) = iterator.next() {
        switch piece {
        case .docLineComment(let comment), .docBlockComment(let comment):
          // These patterns are often used for "file header" style comments
          if !comment.hasPrefix("////"), !comment.hasPrefix("/***") {
            if isOrphanedDocComment(with: &iterator) {
              let utf8Length = pieces[..<index]
                .reduce(0) { $0 + $1.sourceLength.utf8Length }
              violations.append(node.position.advanced(by: utf8Length))
            }
          }

        default:
          break
        }
      }
    }
  }
}

private func isOrphanedDocComment(
  with iterator: inout some IteratorProtocol<(offset: Int, element: TriviaPiece)>,
) -> Bool {
  while let (_, piece) = iterator.next() {
    switch piece {
    case .docLineComment, .docBlockComment,
      .carriageReturns, .carriageReturnLineFeeds, .newlines, .spaces:
      break

    case .lineComment, .blockComment:
      return true

    default:
      return false
    }
  }
  return false
}
