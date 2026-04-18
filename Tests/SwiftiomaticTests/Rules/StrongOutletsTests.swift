@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct StrongOutletsTests: RuleTesting {

  @Test func removeWeakFromOutlet() {
    assertFormatting(
      StrongOutlets.self,
      input: """
        @IBOutlet 1️⃣weak var label: UILabel!
        """,
      expected: """
        @IBOutlet var label: UILabel!
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove 'weak' from @IBOutlet property"),
      ]
    )
  }

  @Test func removeWeakFromPrivateOutlet() {
    assertFormatting(
      StrongOutlets.self,
      input: """
        @IBOutlet private 1️⃣weak var label: UILabel!
        """,
      expected: """
        @IBOutlet private var label: UILabel!
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove 'weak' from @IBOutlet property"),
      ]
    )
  }

  @Test func removeWeakFromOutletOnSplitLine() {
    assertFormatting(
      StrongOutlets.self,
      input: """
        @IBOutlet
        1️⃣weak var label: UILabel!
        """,
      expected: """
        @IBOutlet
        var label: UILabel!
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove 'weak' from @IBOutlet property"),
      ]
    )
  }

  @Test func noRemoveWeakFromNonOutlet() {
    assertFormatting(
      StrongOutlets.self,
      input: """
        weak var label: UILabel!
        """,
      expected: """
        weak var label: UILabel!
        """,
      findings: []
    )
  }

  @Test func noRemoveWeakFromNonOutletAfterOutlet() {
    assertFormatting(
      StrongOutlets.self,
      input: """
        @IBOutlet 1️⃣weak var label1: UILabel!
        weak var label2: UILabel!
        """,
      expected: """
        @IBOutlet var label1: UILabel!
        weak var label2: UILabel!
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove 'weak' from @IBOutlet property"),
      ]
    )
  }

  @Test func noRemoveWeakFromDelegateOutlet() {
    assertFormatting(
      StrongOutlets.self,
      input: """
        @IBOutlet weak var delegate: UITableViewDelegate?
        """,
      expected: """
        @IBOutlet weak var delegate: UITableViewDelegate?
        """,
      findings: []
    )
  }

  @Test func noRemoveWeakFromDataSourceOutlet() {
    assertFormatting(
      StrongOutlets.self,
      input: """
        @IBOutlet weak var dataSource: UITableViewDataSource?
        """,
      expected: """
        @IBOutlet weak var dataSource: UITableViewDataSource?
        """,
      findings: []
    )
  }

  @Test func removeWeakFromOutletAfterDelegateOutlet() {
    assertFormatting(
      StrongOutlets.self,
      input: """
        @IBOutlet weak var delegate: UITableViewDelegate?
        @IBOutlet 1️⃣weak var label1: UILabel!
        """,
      expected: """
        @IBOutlet weak var delegate: UITableViewDelegate?
        @IBOutlet var label1: UILabel!
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove 'weak' from @IBOutlet property"),
      ]
    )
  }

  @Test func removeWeakFromOutletAfterDataSourceOutlet() {
    assertFormatting(
      StrongOutlets.self,
      input: """
        @IBOutlet weak var dataSource: UITableViewDataSource?
        @IBOutlet 1️⃣weak var label1: UILabel!
        """,
      expected: """
        @IBOutlet weak var dataSource: UITableViewDataSource?
        @IBOutlet var label1: UILabel!
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove 'weak' from @IBOutlet property"),
      ]
    )
  }
}
