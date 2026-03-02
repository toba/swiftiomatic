struct NoExtensionAccessModifierConfiguration: RuleConfiguration {
    let id = "no_extension_access_modifier"
    let name = "No Extension Access Modifier"
    let summary = "Prefer not to use extension access modifiers"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("extension String {}"),
              Example("\n\n extension String {}"),
              Example("nonisolated extension String {}"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("↓private extension String {}"),
              Example("↓public \n extension String {}"),
              Example("↓open extension String {}"),
              Example("↓internal extension String {}"),
              Example("↓fileprivate extension String {}"),
            ]
    }
}
