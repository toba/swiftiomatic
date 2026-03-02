import Foundation
import SwiftSyntax

struct TodoRule {
    static let id = "todo"
    static let name = "Todo"
    static let summary = "TODOs and FIXMEs should be resolved."
    static var nonTriggeringExamples: [Example] {
        [
              Example("// notaTODO:"),
              Example("// notaFIXME:"),
            ]
    }
    static var triggeringExamples: [Example] {
        [
              Example("// ↓TODO:"),
              Example("// ↓FIXME:"),
              Example("// ↓TODO(note)"),
              Example("// ↓FIXME(note)"),
              Example("/* ↓FIXME: */"),
              Example("/* ↓TODO: */"),
              Example("/** ↓FIXME: */"),
              Example("/** ↓TODO: */"),
            ]
    }
  var options = TodoOptions()

}

extension TodoRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension TodoRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    private lazy var keywordRegex: CachedRegex = {
      let searchKeywords = configuration.only.map(\.rawValue).joined(separator: "|")
      return regex(#"\b((?:\#(searchKeywords))(?::|\b))"#)
    }()

    override func visitPost(_ node: TokenSyntax) {
      let leadingViolations = violations(
        in: node.leadingTrivia, offset: node.position)
      let trailingViolations = violations(
        in: node.trailingTrivia, offset: node.endPositionBeforeTrailingTrivia)
      violations.append(contentsOf: leadingViolations + trailingViolations)
    }

    private func violations(in trivia: Trivia, offset: AbsolutePosition) -> [SyntaxViolation] {
      var position = offset
      var result = [SyntaxViolation]()
      for piece in trivia {
        result.append(contentsOf: violations(in: piece, offset: position))
        position += piece.sourceLength
      }
      return result
    }

    private func violations(in piece: TriviaPiece, offset: AbsolutePosition) -> [SyntaxViolation] {
      let comment: String
      switch piece {
      case .blockComment(let text), .lineComment(let text),
        .docBlockComment(let text), .docLineComment(let text):
        comment = text
      default:
        return []
      }
      let matches = keywordRegex
        .matches(in: comment, range: comment.fullNSRange)
      return matches.reduce(into: []) { violations, match in
        guard let sub = match.output[1].substring else { return }
        let annotationRange = sub.startIndex..<sub.endIndex

        let maxLengthOfMessage = 30

        // customizing the reason message to be specific to fixme or todo
        let kind = comment[annotationRange].hasPrefix("FIXME") ? "FIXMEs" : "TODOs"
        let message = comment[annotationRange.upperBound...]
          .trimmingCharacters(in: .whitespaces)
          .truncated(maxLength: maxLengthOfMessage)
          .prefix { $0 != "\n" }

        let reason: String
        if message.isEmpty {
          reason = "\(kind) should be resolved"
        } else {
          reason = "\(kind) should be resolved (\(message))"
        }

        let violation = SyntaxViolation(
          position:
            offset
            .advanced(by: comment[..<annotationRange.lowerBound].utf8.count),
          reason: reason,
        )
        violations.append(violation)
      }
    }
  }
}

extension String {
  fileprivate func truncated(maxLength: Int) -> String {
    if utf16.count > maxLength {
      let end = index(startIndex, offsetBy: maxLength, limitedBy: endIndex) ?? endIndex
      return self[..<end] + "..."
    }
    return self
  }
}
