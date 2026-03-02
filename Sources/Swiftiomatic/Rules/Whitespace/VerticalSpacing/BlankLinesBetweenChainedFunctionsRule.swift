import SwiftSyntax

struct BlankLinesBetweenChainedFunctionsRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = BlankLinesBetweenChainedFunctionsConfiguration()
}

extension BlankLinesBetweenChainedFunctionsRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension BlankLinesBetweenChainedFunctionsRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
      // Look for `.` (period) tokens that are member access operators
      guard token.tokenKind == .period else { return .visitChildren }

      // Check if this period is part of a member access expression
      guard token.parent?.is(MemberAccessExprSyntax.self) == true else {
        return .visitChildren
      }

      // Check if the base of this member access is also a function call or member access
      // (indicating a chain)
      guard let memberAccess = token.parent?.as(MemberAccessExprSyntax.self),
        memberAccess.base != nil
      else {
        return .visitChildren
      }

      // Check if leading trivia has blank lines
      if token.leadingTrivia.newlineCount > 1 {
        violations.append(token.positionAfterSkippingLeadingTrivia)
      }
      return .visitChildren
    }
  }
}
