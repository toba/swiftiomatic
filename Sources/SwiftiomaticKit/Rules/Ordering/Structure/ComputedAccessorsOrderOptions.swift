import SwiftiomaticSyntax

struct ComputedAccessorsOrderOptions: SeverityBasedRuleOptions {
  enum Order: String, AcceptableByOptionElement {
    case getSet = "get_set"
    case setGet = "set_get"
  }

  @OptionElement(key: "severity")
  var severityConfiguration = SeverityOption<Parent>(.warning)
  @OptionElement(key: "order")
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
