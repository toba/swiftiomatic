@testable import SwiftiomaticKit

extension Configuration {
  /// The default configuration to be used during unit tests.
  package static var forTesting: Configuration {
    var config = Configuration()
    config[MaximumBlankLines.self] = 1
    config[LineLength.self] = 100
    config[TabWidth.self] = 8
    config[IndentationSetting.self] = .spaces(2)
    config[RespectExistingLineBreaks.self] = true
    config[PlaceElseCatchOnNewLine.self] = false
    config[BreakBeforeEachArgument.self] = false
    config[BreakBeforeGenericRequirement.self] = false
    config[KeepReturnTypeWithSignature.self] = false
    config[IndentConditionalCompilationBlocks.self] = true
    config[BreakAroundMultilineChainParts.self] = false
    config[UseFilePrivateForFileLocal.self] = FileScopedDeclarationPrivacyConfiguration()
    config[IndentSwitchCases.self] = IndentSwitchCasesConfiguration()
    config[SpaceAroundRangeOperators.self] = false
    config[NoAssignmentInExpressions.self] = NoAssignmentInExpressionsConfiguration()
    config[MultiElementCollectionTrailingCommas.self] = true
    config[IndentBlankLines.self] = false
    config[HoistExtensionAccess.self] = ExtensionAccessControlConfiguration()
    config[HoistCaseLet.self] = CaseLetConfiguration()
    config[UseURLMacroForURLLiterals.self] = URLMacroConfiguration()
    config[FileHeader.self] = FileHeaderConfiguration()
    config[LayoutSingleLineBodies.self] = LayoutSingleLineBodiesConfiguration()
    config[LayoutSwitchCaseBodies.self] = LayoutSwitchCaseBodiesConfiguration()
    config[NestedCallLayout.self] = NestedCallLayoutConfiguration()
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
