/// The rule list containing all available rules built into SwiftLintCore.
let coreRules: [any Rule.Type] = [
    CustomRules.self,
    SuperfluousDisableCommandRule.self,
]
