import SwiftSyntax

struct BlankLinesBetweenChainedFunctionsRule {
    static let id = "blank_lines_between_chained_functions"
    static let name = "Blank Lines Between Chained Functions"
    static let summary = "There should be no blank lines between chained function calls"
    static let scope: Scope = .format
    static var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                [0, 1, 2]
                    .map { $0 * 2 }
                    .filter { $0 > 0 }
                """)
            ]
    }
    static var triggeringExamples: [Example] {
        [
              Example(
                """
                [0, 1, 2]
                    .map { $0 * 2 }

                    ↓.filter { $0 > 0 }
                """)
            ]
    }
  var options = SeverityConfiguration<Self>(.warning)

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
