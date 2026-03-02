import SwiftSyntax

struct MultilineArgumentsBracketsRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = MultilineArgumentsBracketsConfiguration()
}

extension MultilineArgumentsBracketsRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension MultilineArgumentsBracketsRule {}

extension MultilineArgumentsBracketsRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      guard let firstArgument = node.arguments.first,
        let leftParen = node.leftParen,
        let rightParen = node.rightParen
      else {
        return
      }

      let hasMultilineFirstArgument = hasLeadingNewline(firstArgument)
      let hasMultilineArgument = node.arguments
        .contains { argument in
          hasLeadingNewline(argument)
        }

      let hasMultilineRightParen = hasLeadingNewline(rightParen)

      if !hasMultilineFirstArgument, hasMultilineArgument {
        violations.append(leftParen.endPosition)
      }

      if !hasMultilineArgument, hasMultilineRightParen {
        violations.append(leftParen.endPosition)
      }

      if !hasMultilineRightParen, hasMultilineArgument {
        violations.append(rightParen.position)
      }
    }

    private func hasLeadingNewline(_ syntax: some SyntaxProtocol) -> Bool {
      syntax.leadingTrivia.contains(where: \.isNewline)
    }
  }
}
