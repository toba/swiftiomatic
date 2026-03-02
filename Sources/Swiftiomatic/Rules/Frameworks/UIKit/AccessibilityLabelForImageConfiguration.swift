struct AccessibilityLabelForImageConfiguration: RuleConfiguration {
    let id = "accessibility_label_for_image"
    let name = "Accessibility Label for Image"
    let summary = "Images that provide context should have an accessibility label or should be explicitly hidden from accessibility"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        AccessibilityLabelForImageRuleExamples.nonTriggeringExamples
    }
    var triggeringExamples: [Example] {
        AccessibilityLabelForImageRuleExamples.triggeringExamples
    }
    let rationale: String? = """
      In UIKit, a `UIImageView` was by default not an accessibility element, and would only be visible to VoiceOver \
      and other assistive technologies if the developer explicitly made them an accessibility element. In SwiftUI, \
      however, an `Image` is an accessibility element by default. If the developer does not explicitly hide them \
      from accessibility or give them an accessibility label, they will inherit the name of the image file, which \
      often creates a poor experience when VoiceOver reads things like "close icon white".

      Known false negatives for Images declared as instance variables and containers that provide a label but are \
      not accessibility elements. Known false positives for Images created in a separate function from where they \
      have accessibility properties applied.
      """
}
