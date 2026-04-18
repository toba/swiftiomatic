/// All layout setting descriptors.
///
/// This is the single source of truth for layout setting metadata.
/// ``Configuration`` derives encode/decode from these; schema generators
/// read descriptions, defaults, and group membership from them.
package enum LayoutSettings {
    package static let all: [any LayoutDescriptor.Type] = [
        // Root-level
        LineLength.self,
        TabWidth.self,
        IndentationSetting.self,
        RespectsExistingLineBreaks.self,
        SpacesBeforeEndOfLineComments.self,
        SpacesAroundRangeFormationOperators.self,
        PrioritizeKeepingFunctionOutputTogether.self,
        MultilineTrailingCommaBehaviorSetting.self,
        MultiElementCollectionTrailingCommas.self,
        ReflowMultilineStringLiterals.self,
        // Grouped: .indentation
        IndentBlankLines.self,
        IndentConditionalCompilationBlocks.self,
        // Grouped: .blankLines
        MaximumBlankLines.self,
        // Grouped: .lineBreaks
        BeforeControlFlowKeywords.self,
        BeforeEachArgument.self,
        BeforeEachGenericRequirement.self,
        BetweenDeclarationAttributes.self,
        AroundMultilineExpressionChainComponents.self,
        BeforeGuardConditions.self,
    ]

    /// Root-level settings (group == nil).
    package static let rootSettings: [any LayoutDescriptor.Type] =
        all.filter { $0.group == nil }

    /// Settings belonging to a specific group.
    package static func settings(in group: ConfigGroup) -> [any LayoutDescriptor.Type] {
        all.filter { $0.group == group }
    }
}
