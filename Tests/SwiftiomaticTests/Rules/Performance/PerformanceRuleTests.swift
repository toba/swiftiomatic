import Testing

@testable import SwiftiomaticKit

// MARK: - PreferCountWhereRule

@Suite(.rulesRegistered)
struct PreferCountWhereRuleTests {
  @Test func noViolationForDirectCount() async {
    await assertNoViolation(PreferCountWhereRule.self, "let count = array.count")
  }

  @Test func noViolationForCountWhere() async {
    await assertNoViolation(
      PreferCountWhereRule.self,
      "let count = array.count(where: { $0 > 0 })")
  }

  @Test func detectsFilterCount() async {
    await assertViolates(
      PreferCountWhereRule.self,
      "let count = array.filter { $0 > 0 }.count")
  }
}
