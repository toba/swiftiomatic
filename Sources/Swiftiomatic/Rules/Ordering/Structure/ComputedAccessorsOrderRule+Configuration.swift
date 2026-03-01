struct ComputedAccessorsOrderConfiguration: SeverityBasedRuleOptions {
  enum Order: String, AcceptableByConfigurationElement {
    case getSet = "get_set"
    case setGet = "set_get"
  }

  @ConfigurationElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @ConfigurationElement(key: "order")
  private(set) var order = Order.getSet
  typealias Parent = ComputedAccessorsOrderRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$order.key] {
      try order.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
