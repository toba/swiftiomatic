enum TypeBodyLengthCheckType: String, AcceptableByOptionElement, CaseIterable, Comparable {
  case `actor`
  case `class`
  case `enum`
  case `extension`
  case `protocol`
  case `struct`

  static func < (lhs: Self, rhs: Self) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}

struct TypeBodyLengthOptions: SeverityLevelsBasedRuleOptions {
  @OptionElement(isInline: true)
  var severityConfiguration = SeverityLevelsConfiguration<Parent>(
    warning: 250, error: 350,
  )
  @OptionElement(key: "excluded_types")
  private(set) var excludedTypes = Set<TypeBodyLengthCheckType>([.extension, .protocol])
  typealias Parent = TypeBodyLengthRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    do {
      try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
    } catch let issue where issue == SwiftiomaticError.nothingApplied(ruleID: Parent.identifier) {
      // Acceptable — severity is optional.
    }
    if let value = configuration[$excludedTypes.key] {
      try excludedTypes.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
