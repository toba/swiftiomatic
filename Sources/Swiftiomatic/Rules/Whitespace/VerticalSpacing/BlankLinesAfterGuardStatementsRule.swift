import SwiftSyntax

struct BlankLinesAfterGuardStatementsRule: Rule {
  var configuration = SeverityConfiguration<Self>(.warning)

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
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<ConfigurationType> {
    Visitor(configuration: configuration, file: file)
  }
}

extension BlankLinesAfterGuardStatementsRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<ConfigurationType> {
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
        let trivia = nextItem.leadingTrivia
        var newlineCount = 0
        for piece in trivia {
          switch piece {
          case .newlines(let count):
            newlineCount += count
          case .carriageReturns(let count), .carriageReturnLineFeeds(let count):
            newlineCount += count
          default:
            break
          }
        }
        if newlineCount < 2 {
          violations.append(nextItem.positionAfterSkippingLeadingTrivia)
        }
      }
    }
  }
}
