import SwiftSyntax

struct AttributeNameSpacingRule {
  var options = SeverityConfiguration<Self>(.error)

  static let configuration = AttributeNameSpacingConfiguration()
}

extension AttributeNameSpacingRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension AttributeNameSpacingRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: DeclModifierSyntax) {
      guard node.detail != nil, node.name.trailingTrivia.isNotEmpty else {
        return
      }

      addViolation(
        startPosition: node.name.endPositionBeforeTrailingTrivia,
        endPosition: node.name.endPosition,
        replacement: "",
        reason: "There must not be any space between access control modifier and scope",
      )
    }

    override func visitPost(_ node: AttributeSyntax) {
      // Check for trailing trivia after the '@' sign. Handles cases like `@ MainActor` / `@ escaping`.
      if node.atSign.trailingTrivia.isNotEmpty {
        addViolation(
          startPosition: node.atSign.endPositionBeforeTrailingTrivia,
          endPosition: node.atSign.endPosition,
          replacement: "",
          reason: "Attributes must not have trivia between `@` and the identifier",
        )
      }

      let hasTrailingTrivia = node.attributeName.trailingTrivia.isNotEmpty

      // Handles cases like `@MyPropertyWrapper (param: 2)`.
      if node.arguments != nil, hasTrailingTrivia {
        addViolation(
          startPosition: node.attributeName.endPositionBeforeTrailingTrivia,
          endPosition: node.attributeName.endPosition,
          replacement: "",
          reason: "Attribute declarations with arguments must not have trailing trivia",
        )
      }

      if !hasTrailingTrivia, node.isEscaping {
        // Handles cases where escaping has the wrong spacing: `@escaping()`
        addViolation(
          startPosition: node.attributeName.endPositionBeforeTrailingTrivia,
          endPosition: node.attributeName.endPosition,
          replacement: " ",
          reason: "`@escaping` must have a trailing space before the associated type",
        )
      }
    }

    private func addViolation(
      startPosition: AbsolutePosition,
      endPosition: AbsolutePosition,
      replacement: String,
      reason: String,
    ) {
      let correction = SyntaxViolation.Correction(
        start: startPosition,
        end: endPosition,
        replacement: replacement,
      )

      let violation = SyntaxViolation(
        position: endPosition,
        reason: reason,
        severity: configuration.severity,
        correction: correction,
      )
      violations.append(violation)
    }
  }
}

extension AttributeSyntax {
  fileprivate var isEscaping: Bool {
    attributeNameText == "escaping"
  }
}
