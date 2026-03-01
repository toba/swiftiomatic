struct ProhibitedSuperOptions: SeverityBasedRuleOptions {
  @OptionElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @OptionElement(key: "excluded")
  private(set) var excluded = [String]()
  @OptionElement(key: "included")
  private(set) var included = ["*"]

  private static let methodNames = [
    // NSFileProviderExtension
    "providePlaceholder(at:completionHandler:)",
    // NSTextInput
    "doCommand(by:)",
    // NSView
    "updateLayer()",
    // UIViewController
    "loadView()",
  ]

  var resolvedMethodNames: [String] {
    var names = [String]()
    if included.contains("*"), !excluded.contains("*") {
      names += Self.methodNames
    }
    names += included.filter { $0 != "*" }
    names = names.filter { !excluded.contains($0) }
    return names
  }

  typealias Parent = ProhibitedSuperRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$excluded.key] {
      try excluded.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$included.key] {
      try included.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
