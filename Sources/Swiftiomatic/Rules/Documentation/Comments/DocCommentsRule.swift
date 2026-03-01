import Foundation
import SwiftSyntax

struct DocCommentsRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = DocCommentsConfiguration()

  static let description = RuleDescription(
    identifier: "doc_comments",
    name: "Doc Comments",
    description:
      "API declarations should use doc comments (`///`) instead of regular comments (`//`)",
    scope: .suggest,
    nonTriggeringExamples: [
      Example(
        """
        /// A placeholder type
        class Foo {}
        """,
      ),
      Example(
        """
        class Foo {
          // TODO: implement
          func bar() {}
        }
        """,
      ),
    ],
    triggeringExamples: [
      Example(
        """
        ↓// A placeholder type
        class Foo {}
        """,
      ),
      Example(
        """
        class Foo {
          ↓// Does something
          func bar() {}
        }
        """,
      ),
    ],
  )
}

extension DocCommentsRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension DocCommentsRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionDeclSyntax) {
      checkForRegularComment(on: node)
    }

    override func visitPost(_ node: ClassDeclSyntax) {
      checkForRegularComment(on: node)
    }

    override func visitPost(_ node: StructDeclSyntax) {
      checkForRegularComment(on: node)
    }

    override func visitPost(_ node: EnumDeclSyntax) {
      checkForRegularComment(on: node)
    }

    override func visitPost(_ node: ProtocolDeclSyntax) {
      checkForRegularComment(on: node)
    }

    override func visitPost(_ node: VariableDeclSyntax) {
      checkForRegularComment(on: node)
    }

    override func visitPost(_ node: TypeAliasDeclSyntax) {
      checkForRegularComment(on: node)
    }

    private func checkForRegularComment(on node: some SyntaxProtocol) {
      let trivia = node.leadingTrivia

      // Look for line comments that aren't doc comments
      var hasRegularComment = false
      var commentPosition: AbsolutePosition?

      for (index, piece) in trivia.enumerated() {
        switch piece {
        case .lineComment(let text):
          // Skip directives (MARK, TODO, FIXME, etc.)
          let trimmed = text.dropFirst(2).trimmingCharacters(in: .whitespaces)
          if trimmed.hasPrefix("MARK:") || trimmed.hasPrefix("TODO:")
            || trimmed.hasPrefix("FIXME:") || trimmed.hasPrefix("sm:")
            || trimmed.hasPrefix("swiftlint:")
          {
            return
          }
          // Check it's not already a doc comment (///)
          if !text.hasPrefix("///") {
            hasRegularComment = true
            if commentPosition == nil {
              // Calculate position based on trivia pieces before this one
              var offset = node.position
              for i in 0..<index {
                offset = offset.advanced(
                  by: trivia[trivia.index(trivia.startIndex, offsetBy: i)].sourceLength.utf8Length)
              }
              commentPosition = offset
            }
          }
        default:
          break
        }
      }

      if hasRegularComment, let position = commentPosition {
        violations.append(position)
      }
    }
  }
}
