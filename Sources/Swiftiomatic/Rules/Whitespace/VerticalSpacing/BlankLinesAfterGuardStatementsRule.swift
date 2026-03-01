import SwiftSyntax

struct BlankLinesAfterGuardStatementsRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = BlankLinesAfterGuardStatementsConfiguration()

  static let description = RuleDescription(
    identifier: "blank_lines_after_guard_statements",
    name: "Blank Lines After Guard Statements",
    description:
      "There should be a blank line after the last guard statement before other code",
    scope: .format,
    nonTriggeringExamples: [
      Example(
        """
        guard let foo = bar else { return }

        print(foo)
        """),
      Example(
        """
        guard let a = b else { return }
        guard let c = d else { return }

        print(a, c)
        """),
    ],
    triggeringExamples: [
      Example(
        """
        guard let foo = bar else { return }
        ↓print(foo)
        """)
    ],
  )
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
