import Foundation
import SwiftSyntax

struct TodoRule: Rule {
  var configuration = TodoConfiguration()

  static let description = RuleDescription(
    identifier: "todo",
    name: "Todo",
    description: "TODOs and FIXMEs should be resolved.",
    nonTriggeringExamples: [
      Example("// notaTODO:"),
      Example("// notaFIXME:"),
    ],
    triggeringExamples: [
      Example("// ↓TODO:"),
      Example("// ↓FIXME:"),
      Example("// ↓TODO(note)"),
      Example("// ↓FIXME(note)"),
      Example("/* ↓FIXME: */"),
      Example("/* ↓TODO: */"),
      Example("/** ↓FIXME: */"),
      Example("/** ↓TODO: */"),
    ].skipWrappingInCommentTests(),
  )
}

extension TodoRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<ConfigurationType> {
    Visitor(configuration: configuration, file: file)
  }
}

extension TodoRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<ConfigurationType> {
    override func visitPost(_ node: TokenSyntax) {
      let leadingViolations = node.leadingTrivia.violations(
        offset: node.position,
        for: configuration.only,
      )
      let trailingViolations = node.trailingTrivia.violations(
        offset: node.endPositionBeforeTrailingTrivia,
        for: configuration.only,
      )
      violations.append(contentsOf: leadingViolations + trailingViolations)
    }
  }
}

extension Trivia {
  fileprivate func violations(
    offset: AbsolutePosition,
    for todoKeywords: [TodoConfiguration.TodoKeyword],
  ) -> [SyntaxViolation] {
    var position = offset
    var violations = [SyntaxViolation]()
    for piece in self {
      violations.append(contentsOf: piece.violations(offset: position, for: todoKeywords))
      position += piece.sourceLength
    }
    return violations
  }
}

extension TriviaPiece {
  fileprivate func violations(
    offset: AbsolutePosition,
    for todoKeywords: [TodoConfiguration.TodoKeyword],
  ) -> [SyntaxViolation] {
    switch self {
    case .blockComment(let comment),
      .lineComment(let comment),
      .docBlockComment(let comment),
      .docLineComment(let comment):
      // Construct a regex string considering only keywords.
      let searchKeywords = todoKeywords.map(\.rawValue).joined(separator: "|")
      let matches = regex(#"\b((?:\#(searchKeywords))(?::|\b))"#)
        .matches(in: comment, range: comment.bridge().fullNSRange)
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
    default:
      return []
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
