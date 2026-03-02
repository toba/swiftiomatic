struct AccessibilityTraitForButtonConfiguration: RuleConfiguration {
    let id = "accessibility_trait_for_button"
    let name = "Accessibility Trait for Button"
    let summary = "All views with tap gestures added should include the .isButton or the .isLink accessibility traits"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        AccessibilityTraitForButtonRuleExamples.nonTriggeringExamples
    }
    var triggeringExamples: [Example] {
        AccessibilityTraitForButtonRuleExamples.triggeringExamples
    }
    let rationale: String? = """
      The accessibility button and link traits are used to tell assistive technologies that an element is tappable. \
      When an element has one of these traits, VoiceOver will automatically read "button" or "link" after the \
      element's label to let the user know that they can activate it.

      When using a UIKit `UIButton` or SwiftUI `Button` or `Link`, the button trait is added by default, but when \
      you manually add a tap gesture recognizer to an element, you need to explicitly add the button or link trait. \

      In most cases the button trait should be used, but for buttons that open a URL in an external browser we use \
      the link trait instead. This rule attempts to catch uses of the SwiftUI `.onTapGesture` modifier where the \
      `.isButton` or `.isLink` trait is not explicitly applied.
      """
}
