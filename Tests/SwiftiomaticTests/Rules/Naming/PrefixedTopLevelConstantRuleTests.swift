import Testing

@testable import SwiftiomaticKit

@Suite(.rulesRegistered) struct PrefixedTopLevelConstantRuleTests {
  // MARK: - Private only mode

  @Test func privateConstantWithoutPrefixViolatesInPrivateOnlyMode() async {
    await assertViolates(
      PrefixedTopLevelConstantRule.self,
      "private let Foo = 20.0",
      configuration: ["only_private": true])
  }

  @Test func fileprivateConstantWithoutPrefixViolatesInPrivateOnlyMode() async {
    await assertViolates(
      PrefixedTopLevelConstantRule.self,
      "fileprivate let foo = 20.0",
      configuration: ["only_private": true])
  }

  @Test func publicConstantDoesNotViolateInPrivateOnlyMode() async {
    await assertNoViolation(
      PrefixedTopLevelConstantRule.self,
      "let Foo = 20.0",
      configuration: ["only_private": true])
  }

  @Test func internalConstantDoesNotViolateInPrivateOnlyMode() async {
    await assertNoViolation(
      PrefixedTopLevelConstantRule.self,
      "internal let Foo = \"Foo\"",
      configuration: ["only_private": true])
  }

  @Test func explicitPublicConstantDoesNotViolateInPrivateOnlyMode() async {
    await assertNoViolation(
      PrefixedTopLevelConstantRule.self,
      "public let Foo = 20.0",
      configuration: ["only_private": true])
  }
}
