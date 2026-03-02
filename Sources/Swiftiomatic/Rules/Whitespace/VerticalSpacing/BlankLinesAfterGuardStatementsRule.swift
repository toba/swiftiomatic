import SwiftSyntax

struct BlankLinesAfterGuardStatementsRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = BlankLinesAfterGuardStatementsConfiguration()
}

extension BlankLinesAfterGuardStatementsRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension BlankLinesAfterGuardStatementsRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: CodeBlockSyntax) {
      checkStatements(node.statements)
    }

    private func checkStatements(_ statements: CodeBlockItemListSyntax) {
      let items = Array(statements)
      for (index, item) in items.enumerated() {
        guard item.item.is(GuardStmtSyntax.self) else { continue }

        // Check if next statement is not a guard
        let nextIndex = index + 1
        guard nextIndex < items.count else { continue }
        let nextItem = items[nextIndex]
        if nextItem.item.is(GuardStmtSyntax.self) { continue }

        // Check if next item is a closing brace or operator (skip)
        // Check for blank line
        if nextItem.leadingTrivia.newlineCount < 2 {
          violations.append(nextItem.positionAfterSkippingLeadingTrivia)
        }
      }
    }
  }
}
