@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct WarnForEachIdSelfTests: RuleTesting {
  @Test func idSelfFlagged() {
    assertLint(
      WarnForEachIdSelf.self,
      """
      ForEach(items, id: 1️⃣\\.self) { item in
        Text(String(describing: item))
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "'id: \\.self' is fragile — make the element 'Identifiable' or supply a stable id key path"),
      ]
    )
  }

  @Test func idKeyPathToPropertyNotFlagged() {
    assertLint(
      WarnForEachIdSelf.self,
      """
      ForEach(items, id: \\.id) { item in
        Text(item.name)
      }
      """,
      findings: []
    )
  }

  @Test func noIdArgumentNotFlagged() {
    assertLint(
      WarnForEachIdSelf.self,
      """
      ForEach(items) { item in
        Text(item.name)
      }
      """,
      findings: []
    )
  }

  @Test func nonForEachNotFlagged() {
    assertLint(
      WarnForEachIdSelf.self,
      """
      List(items, id: \\.self) { item in
        Text(String(describing: item))
      }
      """,
      findings: []
    )
  }
}
