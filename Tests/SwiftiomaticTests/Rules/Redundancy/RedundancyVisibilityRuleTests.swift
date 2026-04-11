import Testing

@testable import SwiftiomaticKit

// MARK: - RedundantExtensionACLRule

@Suite(.rulesRegistered)
struct RedundantExtensionACLRuleTests {
  @Test func noViolationForDifferentACL() async {
    await assertNoViolation(
      RedundantExtensionACLRule.self,
      """
      public extension Foo {
          internal func bar() {}
      }
      """)
  }

  @Test func detectsRedundantExtensionACL() async {
    await assertViolates(
      RedundantExtensionACLRule.self,
      """
      public extension Foo {
          public func bar() {}
      }
      """)
  }
}

// MARK: - RedundantInternalRule

@Suite(.rulesRegistered)
struct RedundantInternalRuleTests {
  @Test func detectsRedundantInternal() async {
    await assertViolates(RedundantInternalRule.self, "internal class Foo {}")
  }

  @Test func noViolationForPublic() async {
    await assertNoViolation(RedundantInternalRule.self, "public class Foo {}")
  }
}
