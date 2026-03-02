import SwiftSyntax

struct ConditionalReturnsOnNewlineRule {
  var options = ConditionalReturnsOnNewlineOptions()

  static let configuration = ConditionalReturnsOnNewlineConfiguration()
}

extension ConditionalReturnsOnNewlineRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension ConditionalReturnsOnNewlineRule {}

extension ConditionalReturnsOnNewlineRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: IfExprSyntax) {
      if isReturn(node.body.statements.lastReturn, onTheSameLineAs: node.ifKeyword) {
        violations.append(node.ifKeyword.positionAfterSkippingLeadingTrivia)
        return
      }

      if let elseBody = node.elseBody?.as(CodeBlockSyntax.self),
        let elseKeyword = node.elseKeyword,
        isReturn(elseBody.statements.lastReturn, onTheSameLineAs: elseKeyword)
      {
        violations.append(node.ifKeyword.positionAfterSkippingLeadingTrivia)
      }
    }

    override func visitPost(_ node: GuardStmtSyntax) {
      if configuration.ifOnly {
        return
      }

      if isReturn(node.body.statements.lastReturn, onTheSameLineAs: node.guardKeyword) {
        violations.append(node.guardKeyword.positionAfterSkippingLeadingTrivia)
      }
    }

    private func isReturn(_ returnStmt: ReturnStmtSyntax?, onTheSameLineAs token: TokenSyntax)
      -> Bool
    {
      guard let returnStmt else {
        return false
      }

      return locationConverter.location(
        for: returnStmt.returnKeyword.positionAfterSkippingLeadingTrivia,
      ).line == locationConverter.location(for: token.positionAfterSkippingLeadingTrivia).line
    }
  }
}

extension CodeBlockItemListSyntax {
  fileprivate var lastReturn: ReturnStmtSyntax? {
    last?.item.as(ReturnStmtSyntax.self)
  }
}
