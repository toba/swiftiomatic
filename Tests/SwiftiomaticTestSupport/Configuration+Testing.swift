import SwiftiomaticKit

extension Configuration {
  /// The default configuration to be used during unit tests.
  package static var forTesting: Configuration {
    var config = Configuration()
    config.rules = Configuration.defaultRuleEnablements
    config[MaximumBlankLines.self] = 1
    config[LineLength.self] = 100
    config[TabWidth.self] = 8
    config[IndentationSetting.self] = .spaces(2)
    config[RespectsExistingLineBreaks.self] = true
    config[BeforeControlFlowKeywords.self] = false
    config[BeforeEachArgument.self] = false
    config[BeforeEachGenericRequirement.self] = false
    config[PrioritizeKeepingFunctionOutputTogether.self] = false
    config[IndentConditionalCompilationBlocks.self] = true
    config[AroundMultilineExpressionChainComponents.self] = false
    config[FileScopedDeclarationPrivacyConfiguration.self] = FileScopedDeclarationPrivacyConfiguration()
    config[SwitchCaseIndentationConfiguration.self] = SwitchCaseIndentationConfiguration()
    config[SpacesAroundRangeFormationOperators.self] = false
    config[NoAssignmentInExpressionsConfiguration.self] = NoAssignmentInExpressionsConfiguration()
    config[MultiElementCollectionTrailingCommas.self] = true
    config[IndentBlankLines.self] = false
    config[ExtensionAccessControlConfiguration.self] = ExtensionAccessControlConfiguration()
    config[PatternLetConfiguration.self] = PatternLetConfiguration()
    config[URLMacroConfiguration.self] = URLMacroConfiguration()
    config[FileHeaderConfiguration.self] = FileHeaderConfiguration()
    config[SingleLineBodiesConfiguration.self] = SingleLineBodiesConfiguration()
    return config
  }

  package static func forTesting(enabledRule: String) -> Configuration {
    var config = Configuration.forTesting
    config.rules = config.rules.mapValues({ _ in .off })
    config.rules[enabledRule] = .warning
    return config
  }
}
