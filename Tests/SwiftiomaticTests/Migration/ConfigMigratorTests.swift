import Foundation
import Testing

@testable import SwiftiomaticKit
@testable import SwiftiomaticSyntax

@Suite(.rulesRegistered) struct ConfigMigratorTests {
  // MARK: - SwiftLint Migration

  @Test func migrateSwiftLintDisabledRules() {
    var slConfig = SwiftLintConfig()
    slConfig.disabledRules = ["force_cast", "trailing_whitespace"]

    let result = ConfigMigrator.migrate(swiftlint: slConfig)

    #expect(result.configuration.disabledLintRules.contains("force_cast"))
    #expect(result.configuration.disabledLintRules.contains("trailing_whitespace"))
    #expect(result.mappedRuleCount == 2)
  }

  @Test func migrateSwiftLintOptInRules() {
    var slConfig = SwiftLintConfig()
    slConfig.optInRules = ["explicit_self", "number_separator"]

    let result = ConfigMigrator.migrate(swiftlint: slConfig)

    #expect(result.configuration.enabledLintRules.contains("explicit_self"))
    #expect(result.configuration.enabledLintRules.contains("number_separator"))
    #expect(result.mappedRuleCount == 2)
  }

  @Test func migrateSwiftLintOnlyRulesOverridesOptIn() {
    var slConfig = SwiftLintConfig()
    slConfig.optInRules = ["explicit_self"]
    slConfig.onlyRules = ["force_cast", "line_length"]

    let result = ConfigMigrator.migrate(swiftlint: slConfig)

    // only_rules takes precedence
    #expect(result.configuration.enabledLintRules.contains("force_cast"))
    #expect(result.configuration.enabledLintRules.contains("line_length"))
    #expect(!result.configuration.enabledLintRules.contains("explicit_self"))
  }

  @Test func migrateSwiftLintExactMatchRule() {
    var slConfig = SwiftLintConfig()
    slConfig.disabledRules = ["empty_count"]

    let result = ConfigMigrator.migrate(swiftlint: slConfig)

    #expect(result.configuration.disabledLintRules.contains("empty_count"))
    #expect(result.mappedRuleCount == 1)
  }

  @Test func migrateSwiftLintDeprecatedAlias() {
    var slConfig = SwiftLintConfig()
    slConfig.optInRules = ["redundant_self_in_closure"]

    let result = ConfigMigrator.migrate(swiftlint: slConfig)

    #expect(result.configuration.enabledLintRules.contains("redundant_self"))
    #expect(result.warnings.contains { $0.message.contains("Renamed") })
  }

  @Test func migrateSwiftLintUnmappedRuleWarns() {
    var slConfig = SwiftLintConfig()
    slConfig.disabledRules = ["completely_fake_rule"]

    let result = ConfigMigrator.migrate(swiftlint: slConfig)

    #expect(result.unmappedRuleCount == 1)
    #expect(result.warnings.contains { $0.identifier == "completely_fake_rule" })
  }

  @Test func migrateSwiftLintPathsAdvisory() {
    var slConfig = SwiftLintConfig()
    slConfig.includedPaths = ["Sources"]
    slConfig.excludedPaths = ["Pods"]

    let result = ConfigMigrator.migrate(swiftlint: slConfig)

    #expect(result.warnings.contains { $0.identifier == "included" })
    #expect(result.warnings.contains { $0.identifier == "excluded" })
  }

  @Test func migrateSwiftLintAnalyzerRules() {
    var slConfig = SwiftLintConfig()
    slConfig.analyzerRules = ["unused_import"]

    let result = ConfigMigrator.migrate(swiftlint: slConfig)

    #expect(result.configuration.enabledLintRules.contains("unused_import"))
  }

  // MARK: - SwiftFormat Migration

  @Test func migrateSwiftFormatDisabledRules() {
    var sfConfig = SwiftFormatConfig()
    sfConfig.disabledRules = ["redundantSelf", "trailingCommas"]

    let result = ConfigMigrator.migrate(swiftformat: sfConfig)

    #expect(result.configuration.disabledLintRules.contains("explicit_self"))
    #expect(result.configuration.disabledLintRules.contains("trailing_comma"))
  }

  @Test func migrateSwiftFormatIndent() {
    var sfConfig = SwiftFormatConfig()
    sfConfig.indent = "2"

    let result = ConfigMigrator.migrate(swiftformat: sfConfig)
    #expect(result.configuration.formatIndent == "  ")
  }

  @Test func migrateSwiftFormatTabIndent() {
    var sfConfig = SwiftFormatConfig()
    sfConfig.indent = "tab"

    let result = ConfigMigrator.migrate(swiftformat: sfConfig)
    #expect(result.configuration.formatIndent == "\t")
  }

  @Test func migrateSwiftFormatMaxWidth() {
    var sfConfig = SwiftFormatConfig()
    sfConfig.maxWidth = 100

    let result = ConfigMigrator.migrate(swiftformat: sfConfig)
    #expect(result.configuration.formatMaxWidth == 100)
  }

  @Test func migrateSwiftFormatCommas() {
    var sfConfig = SwiftFormatConfig()
    sfConfig.commas = "always"
    let result = ConfigMigrator.migrate(swiftformat: sfConfig)
    #expect(result.configuration.formatTrailingCommas == true)

    var sfConfig2 = SwiftFormatConfig()
    sfConfig2.commas = "inline"
    let result2 = ConfigMigrator.migrate(swiftformat: sfConfig2)
    #expect(result2.configuration.formatTrailingCommas == false)
  }

  // MARK: - Merge

  @Test func mergeBothConfigs() {
    var slConfig = SwiftLintConfig()
    slConfig.disabledRules = ["force_cast"]
    slConfig.optInRules = ["explicit_self"]

    var sfConfig = SwiftFormatConfig()
    sfConfig.disabledRules = ["trailingCommas"]
    sfConfig.maxWidth = 100

    let slResult = ConfigMigrator.migrate(swiftlint: slConfig)
    let sfResult = ConfigMigrator.migrate(swiftformat: sfConfig)
    let merged = ConfigMigrator.merge(swiftlint: slResult, swiftformat: sfResult)

    #expect(merged.configuration.disabledLintRules.contains("force_cast"))
    #expect(merged.configuration.disabledLintRules.contains("trailing_comma"))
    #expect(merged.configuration.enabledLintRules.contains("explicit_self"))
    #expect(merged.configuration.formatMaxWidth == 100)
  }

  @Test func mergeDeduplicatesRules() {
    var slConfig = SwiftLintConfig()
    slConfig.disabledRules = ["trailing_comma"]

    var sfConfig = SwiftFormatConfig()
    sfConfig.disabledRules = ["trailingCommas"]  // maps to trailing_comma

    let slResult = ConfigMigrator.migrate(swiftlint: slConfig)
    let sfResult = ConfigMigrator.migrate(swiftformat: sfConfig)
    let merged = ConfigMigrator.merge(swiftlint: slResult, swiftformat: sfResult)

    let count = merged.configuration.disabledLintRules.filter { $0 == "trailing_comma" }.count
    #expect(count == 1)
  }

  @Test func migrateSwiftLintDeduplicatesSameRule() {
    // Same rule appearing twice should be deduplicated
    var slConfig = SwiftLintConfig()
    slConfig.disabledRules = ["force_cast", "force_cast"]

    let result = ConfigMigrator.migrate(swiftlint: slConfig)

    let count = result.configuration.disabledLintRules.filter { $0 == "force_cast" }.count
    #expect(count == 1)
  }

  @Test func migrateSwiftLintDeduplicatesAliasAndCanonical() {
    // Deprecated alias and canonical name should deduplicate
    var slConfig = SwiftLintConfig()
    slConfig.optInRules = ["redundant_self_in_closure", "redundant_self"]

    let result = ConfigMigrator.migrate(swiftlint: slConfig)

    let count = result.configuration.enabledLintRules.filter { $0 == "redundant_self" }.count
    #expect(count == 1)
  }

  @Test func mergeDeduplicatesAcrossSources() {
    var slConfig = SwiftLintConfig()
    slConfig.disabledRules = ["trailing_comma"]

    var sfConfig = SwiftFormatConfig()
    sfConfig.disabledRules = ["trailingCommas"]  // maps to trailing_comma

    let slResult = ConfigMigrator.migrate(swiftlint: slConfig)
    let sfResult = ConfigMigrator.migrate(swiftformat: sfConfig)
    let merged = ConfigMigrator.merge(swiftlint: slResult, swiftformat: sfResult)

    let count = merged.configuration.disabledLintRules.filter { $0 == "trailing_comma" }.count
    #expect(count == 1)
  }

  // MARK: - SwiftFormat Config Options

  @Test func migrateSwiftFormatElsePosition() {
    var sfConfig = SwiftFormatConfig()
    sfConfig.rawOptions["else-position"] = "next-line"

    let result = ConfigMigrator.migrate(swiftformat: sfConfig)
    #expect(result.configuration.formatLineBreakBeforeControlFlowKeywords == true)
  }

  @Test func migrateSwiftFormatWrapArguments() {
    var sfConfig = SwiftFormatConfig()
    sfConfig.rawOptions["wrap-arguments"] = "before-first"

    let result = ConfigMigrator.migrate(swiftformat: sfConfig)
    #expect(result.configuration.formatLineBreakBeforeEachArgument == true)
  }

  @Test func migrateSwiftFormatPerRuleConfigs() {
    var sfConfig = SwiftFormatConfig()
    sfConfig.rawOptions["self"] = "remove"
    sfConfig.rawOptions["indent-case"] = "true"
    sfConfig.rawOptions["pattern-let"] = "hoist"

    let result = ConfigMigrator.migrate(swiftformat: sfConfig)

    #expect(result.configuration.lintRuleConfigs["explicit_self"] != nil)
    #expect(result.configuration.lintRuleConfigs["switch_case_alignment"] != nil)
    #expect(result.configuration.lintRuleConfigs["pattern_matching_keywords"] != nil)
  }
}
