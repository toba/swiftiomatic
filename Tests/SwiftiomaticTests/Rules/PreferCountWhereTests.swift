@testable import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct PreferCountWhereTests: RuleTesting {
  @Test func trailingClosureFilterCount() {
    assertFormatting(
      PreferCountWhere.self,
      input: """
        let n = items.1️⃣filter { $0.isValid }.count
        """,
      expected: """
        let n = items.count(where: { $0.isValid })
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer 'count(where:)' over 'filter(_:).count'"),
      ]
    )
  }

  @Test func parenthesizedClosureFilterCount() {
    assertFormatting(
      PreferCountWhere.self,
      input: """
        let n = items.1️⃣filter({ $0.isValid }).count
        """,
      expected: """
        let n = items.count(where: { $0.isValid })
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer 'count(where:)' over 'filter(_:).count'"),
      ]
    )
  }

  @Test func chainedFilterCount() {
    assertFormatting(
      PreferCountWhere.self,
      input: """
        let n = items.sorted().1️⃣filter { $0.isActive }.count
        """,
      expected: """
        let n = items.sorted().count(where: { $0.isActive })
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer 'count(where:)' over 'filter(_:).count'"),
      ]
    )
  }

  @Test func filterWithoutCount() {
    assertFormatting(
      PreferCountWhere.self,
      input: """
        let filtered = items.filter { $0.isValid }
        """,
      expected: """
        let filtered = items.filter { $0.isValid }
        """,
      findings: []
    )
  }

  @Test func countWithoutFilter() {
    assertFormatting(
      PreferCountWhere.self,
      input: """
        let n = items.count
        """,
      expected: """
        let n = items.count
        """,
      findings: []
    )
  }

  @Test func filterCountAsMethodCall() {
    assertFormatting(
      PreferCountWhere.self,
      input: """
        let n = items.filter { $0.isValid }.count(of: "x")
        """,
      expected: """
        let n = items.filter { $0.isValid }.count(of: "x")
        """,
      findings: []
    )
  }

  @Test func countWhereAlreadyUsed() {
    assertFormatting(
      PreferCountWhere.self,
      input: """
        let n = items.count(where: { $0.isValid })
        """,
      expected: """
        let n = items.count(where: { $0.isValid })
        """,
      findings: []
    )
  }

  @Test func filterWithMultipleArgs() {
    assertFormatting(
      PreferCountWhere.self,
      input: """
        let n = items.filter(isIncluded: predicate, limit: 10).count
        """,
      expected: """
        let n = items.filter(isIncluded: predicate, limit: 10).count
        """,
      findings: []
    )
  }
}
