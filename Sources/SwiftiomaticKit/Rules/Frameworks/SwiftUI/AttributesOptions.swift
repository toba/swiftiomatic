struct AttributesOptions: SeverityBasedRuleOptions {
  @OptionElement(key: "severity")
  var severityConfiguration = SeverityOption<Parent>(.warning)
  @OptionElement(key: "attributes_with_arguments_always_on_line_above")
  private(set) var attributesWithArgumentsAlwaysOnNewLine = true
  @OptionElement(key: "always_on_same_line")
  private(set) var alwaysOnSameLine = Set<String>(["@IBAction", "@NSManaged"])
  @OptionElement(key: "always_on_line_above")
  private(set) var alwaysOnNewLine = Set<String>()
  typealias Parent = AttributesRule
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
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
