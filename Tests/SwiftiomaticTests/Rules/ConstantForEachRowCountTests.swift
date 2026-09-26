@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct ConstantForEachRowCountTests: RuleTesting {
  private static let ifWithoutElse =
    "'if' without 'else' in a 'ForEach' row changes the row's view count. Add an 'else' branch or move the condition into a row 'View'"
  private static let nestedForEach =
    "'ForEach' directly inside a 'ForEach' row changes the row's view count. Wrap it in a container or a row 'View'"
  private static func severalViews(_ count: Int) -> String {
    "'ForEach' row builds \(count) top-level views. Wrap them in one container or a row 'View' so each element makes one view"
  }

  @Test func breadcrumbSeparatorFlagged() {
    assertLint(
      ConstantForEachRowCount.self,
      """
      HStack {
        1️⃣ForEach(Array(items.enumerated()), id: \\.offset) { index, item in
          2️⃣if index > 0 {
            Image(systemName: "chevron.compact.right")
          }
          Text(item.label)
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.severalViews(2)),
        FindingSpec("2️⃣", message: Self.ifWithoutElse),
      ]
    )
  }

  @Test func loneIfWithoutElseFlagged() {
    assertLint(
      ConstantForEachRowCount.self,
      """
      ForEach(items) { item in
        1️⃣if item.isVisible {
          Text(item.name)
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.ifWithoutElse)]
    )
  }

  @Test func elseIfChainWithoutFinalElseFlagged() {
    assertLint(
      ConstantForEachRowCount.self,
      """
      ForEach(items) { item in
        1️⃣if item.isA {
          Text("a")
        } else if item.isB {
          Text("b")
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.ifWithoutElse)]
    )
  }

  @Test func nestedForEachFlagged() {
    assertLint(
      ConstantForEachRowCount.self,
      """
      ForEach(sections) { section in
        1️⃣ForEach(section.rows) { row in
          Text(row.name)
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.nestedForEach)]
    )
  }

  @Test func contentLabelClosureChecked() {
    assertLint(
      ConstantForEachRowCount.self,
      """
      1️⃣ForEach(items, content: { item in
        Text(item.name)
        Divider()
      })
      """,
      findings: [FindingSpec("1️⃣", message: Self.severalViews(2))]
    )
  }

  @Test func constantRowsNotFlagged() {
    assertLint(
      ConstantForEachRowCount.self,
      """
      ForEach(items) { item in
        let label = item.name
        if item.isOn {
          Text(label).bold()
        } else {
          Text(label)
        }
      }
      ForEach(items) { item in
        switch item.kind {
        case .a: Text("a")
        case .b: Text("b")
        }
      }
      ForEach(sections) { section in
        HStack {
          ForEach(section.rows) { row in Text(row.name) }
        }
      }
      ForEach(items) { item in ItemView(item: item).padding() }
      """,
      findings: []
    )
  }
}
