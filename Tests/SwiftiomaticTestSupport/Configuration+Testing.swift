@testable import SwiftiomaticKit

extension Configuration {
  /// The default configuration to be used during unit tests.
  package static var forTesting: Configuration {
    var config = Configuration()
    config[MaximumBlankLines.self] = 1
    config[LineLength.self] = 100
    config[TabWidth.self] = 8
    config[IndentationSetting.self] = .spaces(2)
    config[RespectsExistingLineBreaks.self] = true
    config[BeforeControlFlowKeywords.self] = false
    config[BeforeEachArgument.self] = false
    config[BeforeEachGenericRequirement.self] = false
    config[KeepFunctionOutputTogether.self] = false
    config[IndentConditionalCompilationBlocks.self] = true
    config[AroundMultilineExpressionChainComponents.self] = false
    config[FileScopedDeclarationPrivacy.self] = FileScopedDeclarationPrivacyConfiguration()
    config[SwitchCaseIndentation.self] = SwitchCaseIndentationConfiguration()
    config[SpacesAroundRangeFormationOperators.self] = false
    config[NoAssignmentInExpressions.self] = NoAssignmentInExpressionsConfiguration()
    config[MultiElementCollectionTrailingCommas.self] = true
    config[IndentBlankLines.self] = false
    config[NoExtensionAccessLevel.self] = ExtensionAccessControlConfiguration()
    config[PatternLetPlacement.self] = PatternLetConfiguration()
    config[URLMacro.self] = URLMacroConfiguration()
    config[FileHeader.self] = FileHeaderConfiguration()
    config[WrapSingleLineBodies.self] = SingleLineBodiesConfiguration()
    return config
  }

  /// Creates a test configuration with only the named rule enabled.
  package static func forTesting(enabledRule: String) -> Configuration {
    var config = Configuration.forTesting
    config.disableAllRules()
    config.enableRule(named: enabledRule)
    return config
  }
}
