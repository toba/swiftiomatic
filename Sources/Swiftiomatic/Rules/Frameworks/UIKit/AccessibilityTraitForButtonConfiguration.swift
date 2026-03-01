struct AccessibilityTraitForButtonConfiguration: RuleConfiguration {
    let id = "accessibility_trait_for_button"
    let name = "Accessibility Trait for Button"
    let summary = "All views with tap gestures added should include the .isButton or the .isLink accessibility traits"
    let isOptIn = true
}
