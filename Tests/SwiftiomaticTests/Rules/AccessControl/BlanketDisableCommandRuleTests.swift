import Testing

@testable import SwiftiomaticKit

@Suite(.rulesRegistered) struct BlanketDisableCommandRuleTests {
  // MARK: - Non-triggering (default config)

  @Test func disableWithMatchingEnableDoesNotTrigger() async {
    await assertNoViolation(
      BlanketDisableCommandRule.self,
      """
      // sm:disable unused_import
      // sm:enable unused_import
      """
    )
  }

  @Test func disableMultipleWithMatchingEnablesDoesNotTrigger() async {
    await assertNoViolation(
      BlanketDisableCommandRule.self,
      """
      // sm:disable unused_import unused_declaration
      // sm:enable unused_import
      // sm:enable unused_declaration
      """
    )
  }

  @Test func disableThisDoesNotTrigger() async {
    await assertNoViolation(BlanketDisableCommandRule.self, "// sm:disable:this unused_import")
  }

  @Test func disableNextDoesNotTrigger() async {
    await assertNoViolation(BlanketDisableCommandRule.self, "// sm:disable:next unused_import")
  }

  @Test func disablePreviousDoesNotTrigger() async {
    await assertNoViolation(
      BlanketDisableCommandRule.self, "// sm:disable:previous unused_import"
    )
  }

  // MARK: - Triggering (default config)

  @Test func blanketDisableWithoutEnableTriggers() async {
    await assertLint(
      BlanketDisableCommandRule.self,
      "// sm:disable 1️⃣unused_import",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func blanketDisableSecondRuleWithoutEnableTriggers() async {
    await assertLint(
      BlanketDisableCommandRule.self,
      """
      // sm:disable unused_import 1️⃣unused_declaration
      // sm:enable unused_import
      """,
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func duplicateDisableTriggers() async {
    await assertLint(
      BlanketDisableCommandRule.self,
      """
      // sm:disable unused_import
      // sm:disable 1️⃣unused_import
      // sm:enable unused_import
      """,
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func enableWithoutDisableTriggers() async {
    await assertLint(
      BlanketDisableCommandRule.self,
      "// sm:enable 1️⃣unused_import",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func disableAllTriggers() async {
    await assertViolates(BlanketDisableCommandRule.self, "// sm:disable all")
  }

  // MARK: - Allowed rules (default config includes file_length, single_test_class, etc.)

  @Test func allowedRuleFileLengthDoesNotTrigger() async {
    await assertNoViolation(BlanketDisableCommandRule.self, "// sm:disable file_length")
  }

  @Test func allowedRuleSingleTestClassDoesNotTrigger() async {
    await assertNoViolation(BlanketDisableCommandRule.self, "// sm:disable single_test_class")
  }

  // MARK: - always_blanket_disable configuration

  @Test func alwaysBlanketDisableAllowsBlanketDisable() async {
    await assertNoViolation(
      BlanketDisableCommandRule.self,
      "// sm:disable file_length\n// sm:enable file_length",
      configuration: ["always_blanket_disable": ["file_length"]]
    )
  }

  @Test func alwaysBlanketDisableRejectsEnable() async {
    await assertLint(
      BlanketDisableCommandRule.self,
      "// sm:disable file_length\n// sm:enable 1️⃣file_length",
      findings: [
        FindingSpec(
          "1️⃣",
          message:
            "The 'file_length' rule applies to the whole file and thus doesn't need to be re-enabled"
        ),
      ],
      configuration: ["always_blanket_disable": ["file_length"]]
    )
  }

  @Test func alwaysBlanketDisableRejectsDisablePrevious() async {
    await assertLint(
      BlanketDisableCommandRule.self,
      "// sm:disable:previous 1️⃣file_length",
      findings: [
        FindingSpec(
          "1️⃣",
          message:
            "The 'file_length' rule applies to the whole file and thus cannot be disabled locally with 'previous', 'this' or 'next'"
        ),
      ],
      configuration: ["always_blanket_disable": ["file_length"]]
    )
  }

  @Test func alwaysBlanketDisableRejectsDisableThis() async {
    await assertLint(
      BlanketDisableCommandRule.self,
      "// sm:disable:this 1️⃣file_length",
      findings: [
        FindingSpec(
          "1️⃣",
          message:
            "The 'file_length' rule applies to the whole file and thus cannot be disabled locally with 'previous', 'this' or 'next'"
        ),
      ],
      configuration: ["always_blanket_disable": ["file_length"]]
    )
  }

  @Test func alwaysBlanketDisableRejectsDisableNext() async {
    await assertLint(
      BlanketDisableCommandRule.self,
      "// sm:disable:next 1️⃣file_length",
      findings: [
        FindingSpec(
          "1️⃣",
          message:
            "The 'file_length' rule applies to the whole file and thus cannot be disabled locally with 'previous', 'this' or 'next'"
        ),
      ],
      configuration: ["always_blanket_disable": ["file_length"]]
    )
  }

  @Test func alwaysBlanketDisabledRuleIsAllowedAsBlanketDisable() async {
    await assertNoViolation(
      BlanketDisableCommandRule.self,
      "// sm:disable identifier_name\n",
      configuration: ["always_blanket_disable": ["identifier_name"], "allowed_rules": []]
    )
  }
}
