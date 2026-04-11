import SwiftSyntax

struct NSLocalizedStringKeyRule {
  static let id = "nslocalizedstring_key"
  static let name = "NSLocalizedString Key"
  static let summary =
    "Static strings should be used as key/comment in NSLocalizedString in order for genstrings to work"
  static let isOptIn = true
  static var nonTriggeringExamples: [Example] {
    [
      Example("NSLocalizedString(\"key\", comment: \"\")"),
      Example("NSLocalizedString(\"key\" + \"2\", comment: \"\")"),
      Example("NSLocalizedString(\"key\", comment: \"comment\")"),
      Example(
        """
        NSLocalizedString("This is a multi-" +
            "line string", comment: "")
        """,
      ),
      Example(
        """
        let format = NSLocalizedString("%@, %@.", comment: "Accessibility label for a post in the post list." +
        " The parameters are the title, and date respectively." +
        " For example, \"Let it Go, 1 hour ago.\"")
        """,
      ),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example("NSLocalizedString(↓method(), comment: \"\")"),
      Example("NSLocalizedString(↓\"key_\\(param)\", comment: \"\")"),
      Example("NSLocalizedString(\"key\", comment: ↓\"comment with \\(param)\")"),
      Example("NSLocalizedString(↓\"key_\\(param)\", comment: ↓method())"),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension NSLocalizedStringKeyRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension NSLocalizedStringKeyRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      guard
        node.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text == "NSLocalizedString"
      else {
        return
      }

      if let keyArgument = node.arguments.first(where: { $0.label == nil })?.expression,
        keyArgument.hasViolation
      {
        violations.append(keyArgument.positionAfterSkippingLeadingTrivia)
      }

      if let commentArgument = node.arguments.first(where: { $0.label?.text == "comment" })?
        .expression,
        commentArgument.hasViolation
      {
        violations.append(commentArgument.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}

extension ExprSyntax {
  fileprivate var hasViolation: Bool {
    if let strExpr = `as`(StringLiteralExprSyntax.self) {
      return strExpr.segments.contains { segment in
        !segment.is(StringSegmentSyntax.self)
      }
    }

    if let sequenceExpr = `as`(SequenceExprSyntax.self) {
      return sequenceExpr.elements.contains { expr in
        if expr.is(BinaryOperatorExprSyntax.self) {
          return false
        }

        return expr.hasViolation
      }
    }

    return true
  }
}
