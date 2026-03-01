struct PreferFinalClassesConfiguration: RuleConfiguration {
    let id = "prefer_final_classes"
    let name = "Prefer Final Classes"
    let summary = "Classes should be marked `final` unless designed for subclassing"
    let scope: Scope = .suggest
}
