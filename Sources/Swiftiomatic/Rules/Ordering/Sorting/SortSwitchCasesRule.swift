import Foundation
import SwiftSyntax

struct SortSwitchCasesRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "sort_switch_cases",
    name: "Sort Switch Cases",
    description:
      "Switch case patterns with multiple comma-separated values should be sorted alphabetically",
    scope: .suggest,
    nonTriggeringExamples: [
      Example(
        """
        switch value {
        case .a, .b, .c:
          break
        }
        """,
      )
    ],
    triggeringExamples: [
      Example(
        """
        switch value {
        case ↓.c, .a, .b:
          break
        }
        """,
      )
    ],
  )
}

extension SortSwitchCasesRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension SortSwitchCasesRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: SwitchCaseLabelSyntax) {
      // Only check cases with multiple items
      guard node.caseItems.count > 1 else { return }

      // Extract names for each case item
      let names = node.caseItems.compactMap(\.pattern.trimmedDescription)

      guard names.count == node.caseItems.count else { return }

      let sorted = names.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
      if names != sorted {
        violations.append(node.caseItems.first!.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}
