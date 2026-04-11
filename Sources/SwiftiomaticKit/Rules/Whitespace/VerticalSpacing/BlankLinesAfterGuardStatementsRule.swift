import SwiftSyntax

struct BlankLinesAfterGuardStatementsRule {
  static let id = "blank_lines_after_guard_statements"
  static let name = "Blank Lines After Guard Statements"
  static let summary =
    "There should be a blank line after the last guard statement before other code"
  static let scope: Scope = .format
  static var nonTriggeringExamples: [Example] {
    [
      Example(
        """
        func test() {
          guard let foo = bar else { return }

          print(foo)
        }
        """,
      ),
      Example(
        """
        func test() {
          guard let a = b else { return }
          guard let c = d else { return }

          print(a, c)
        }
        """,
      ),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example(
        """
        func test() {
          guard let foo = bar else { return }
          ↓print(foo)
        }
        """,
      )
    ]
  }

  var options = SeverityOption<Self>(.warning)
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
