//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

extension Configuration {
  /// Creates a new `Configuration` with default values.
  ///
  /// This initializer is isolated to its own file to make it easier for users who are forking or
  /// building sm themselves to hardcode a different default configuration. To do this,
  /// simply replace this file with your own default initializer that sets the values to whatever
  /// you want.
  ///
  /// When sm reads a configuration file from disk, any values that are not specified in
  /// the JSON will be populated from this default configuration.
  package init() {
    self.rules = Self.defaultRuleEnablements

    // Layout setting defaults — each value comes from its LayoutDescriptor type.
    self.lineLength = LineLength.defaultValue
    self.tabWidth = TabWidth.defaultValue
    self.indentation = IndentationSetting.defaultValue
    self.respectsExistingLineBreaks = RespectsExistingLineBreaks.defaultValue
    self.spacesBeforeEndOfLineComments = SpacesBeforeEndOfLineComments.defaultValue
    self.spacesAroundRangeFormationOperators = SpacesAroundRangeFormationOperators.defaultValue
    self.prioritizeKeepingFunctionOutputTogether =
        PrioritizeKeepingFunctionOutputTogether.defaultValue
    self.multilineTrailingCommaBehavior = MultilineTrailingCommaBehaviorSetting.defaultValue
    self.multiElementCollectionTrailingCommas = MultiElementCollectionTrailingCommas.defaultValue
    self.reflowMultilineStringLiterals = ReflowMultilineStringLiterals.defaultValue
    self.indentBlankLines = IndentBlankLines.defaultValue
    self.indentConditionalCompilationBlocks = IndentConditionalCompilationBlocks.defaultValue
    self.maximumBlankLines = MaximumBlankLines.defaultValue
    self.lineBreakBeforeControlFlowKeywords = BeforeControlFlowKeywords.defaultValue
    self.lineBreakBeforeEachArgument = BeforeEachArgument.defaultValue
    self.lineBreakBeforeEachGenericRequirement = BeforeEachGenericRequirement.defaultValue
    self.lineBreakBetweenDeclarationAttributes = BetweenDeclarationAttributes.defaultValue
    self.lineBreakAroundMultilineExpressionChainComponents =
        AroundMultilineExpressionChainComponents.defaultValue
    self.lineBreakBeforeGuardConditions = BeforeGuardConditions.defaultValue

    // Rule-specific configuration defaults.
    self.fileScopedDeclarationPrivacy = FileScopedDeclarationPrivacyConfiguration()
    self.switchCaseIndentation = SwitchCaseIndentationConfiguration()
    self.noAssignmentInExpressions = NoAssignmentInExpressionsConfiguration()
    self.sortImports = SortImportsConfiguration()
    self.extensionAccessControl = ExtensionAccessControlConfiguration()
    self.patternLet = PatternLetConfiguration()
    self.urlMacro = URLMacroConfiguration()
    self.fileHeader = FileHeaderConfiguration()
    self.singleLineBodies = SingleLineBodiesConfiguration()
  }
}
