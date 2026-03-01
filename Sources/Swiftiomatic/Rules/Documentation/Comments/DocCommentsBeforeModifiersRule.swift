import SwiftSyntax

struct DocCommentsBeforeModifiersRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "doc_comments_before_modifiers",
    name: "Doc Comments Before Modifiers",
    description: "Doc comments should appear before any modifiers or attributes",
    scope: .suggest,
    nonTriggeringExamples: [
      Example(
        """
        /// Doc comment
        @MainActor
        func foo() {}
        """,
      ),
      Example(
        """
        /// Doc comment
        public func foo() {}
        """,
      ),
    ],
    triggeringExamples: [
      Example(
        """
        @MainActor
        ↓/// Doc comment
        func foo() {}
        """,
      )
    ],
  )
}

extension DocCommentsBeforeModifiersRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension DocCommentsBeforeModifiersRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionDeclSyntax) {
      checkDocCommentPosition(
        modifiers: node.modifiers, attributes: node.attributes,
        keyword: node.funcKeyword)
    }

    override func visitPost(_ node: VariableDeclSyntax) {
      checkDocCommentPosition(
        modifiers: node.modifiers, attributes: node.attributes,
        keyword: node.bindingSpecifier)
    }

    override func visitPost(_ node: ClassDeclSyntax) {
      checkDocCommentPosition(
        modifiers: node.modifiers, attributes: node.attributes,
        keyword: node.classKeyword)
    }

    override func visitPost(_ node: StructDeclSyntax) {
      checkDocCommentPosition(
        modifiers: node.modifiers, attributes: node.attributes,
        keyword: node.structKeyword)
    }

    private func checkDocCommentPosition(
      modifiers: DeclModifierListSyntax,
      attributes: AttributeListSyntax,
      keyword: TokenSyntax,
    ) {
      // If there are no attributes/modifiers, nothing to check
      guard !attributes.isEmpty || !modifiers.isEmpty else { return }

      // Check if the keyword or any modifier has doc comments in its leading trivia
      // (which would mean they appear after attributes/modifiers)
      let tokensToCheck = modifiers.map(\.name) + [keyword]
      for token in tokensToCheck.dropFirst() {
        let trivia = token.leadingTrivia
        for piece in trivia {
          if case .docLineComment = piece {
            violations.append(token.positionAfterSkippingLeadingTrivia)
            return
          }
          if case .docBlockComment = piece {
            violations.append(token.positionAfterSkippingLeadingTrivia)
            return
          }
        }
      }
    }
  }
}
