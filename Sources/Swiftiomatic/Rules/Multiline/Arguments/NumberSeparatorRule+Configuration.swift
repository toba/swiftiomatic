struct NumberSeparatorConfiguration: SeverityBasedRuleOptions {
  struct ExcludeRange: AcceptableByConfigurationElement, Equatable {
    private let min: Double
    private let max: Double

    func asOption() -> OptionType {
      .symbol("\(min) ..< \(max)")
    }

    init(fromAny value: Any, context ruleID: String) throws(SwiftiomaticError) {
      guard let values = value as? [String: Any],
        let min = values["min"] as? Double,
        let max = values["max"] as? Double
      else {
        throw .invalidConfiguration(ruleID: ruleID)
      }
      self.min = min
      self.max = max
    }

    func contains(_ value: Double) -> Bool {
      min <= value && value < max
    }
  }

  @ConfigurationElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @ConfigurationElement(key: "minimum_length")
  private(set) var minimumLength = 0
  @ConfigurationElement(key: "minimum_fraction_length")
  private(set) var minimumFractionLength: Int?
  @ConfigurationElement(key: "exclude_ranges")
  private(set) var excludeRanges = [ExcludeRange]()
  typealias Parent = NumberSeparatorRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$minimumLength.key] {
      try minimumLength.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$minimumFractionLength.key] {
      try minimumFractionLength.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$excludeRanges.key] {
      try excludeRanges.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
