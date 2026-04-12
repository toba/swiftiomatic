import SwiftiomaticSyntax

struct AttributePlacementOptions: SeverityBasedRuleOptions {
  @OptionElement(key: "severity")
  var severityConfiguration = SeverityOption<Parent>(.warning)
  @OptionElement(key: "attributes_with_arguments_always_on_line_above")
  private(set) var attributesWithArgumentsAlwaysOnNewLine = true
  @OptionElement(key: "always_on_same_line")
  private(set) var alwaysOnSameLine = Set<String>(["@IBAction", "@NSManaged"])
  @OptionElement(key: "always_on_line_above")
  private(set) var alwaysOnNewLine = Set<String>()
  @OptionElement(key: "inline_when_fits")
  private(set) var inlineWhenFits = false
  @OptionElement(key: "max_width")
  private(set) var maxWidth = 120
  typealias Parent = AttributePlacementRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$attributesWithArgumentsAlwaysOnNewLine.key] {
      try attributesWithArgumentsAlwaysOnNewLine.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$alwaysOnSameLine.key] {
      try alwaysOnSameLine.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$alwaysOnNewLine.key] {
      try alwaysOnNewLine.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$inlineWhenFits.key] {
      try inlineWhenFits.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$maxWidth.key] {
      try maxWidth.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
