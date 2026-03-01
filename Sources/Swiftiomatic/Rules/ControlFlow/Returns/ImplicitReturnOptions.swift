struct ImplicitReturnOptions: SeverityBasedRuleOptions {
  enum ReturnKind: String, AcceptableByOptionElement, CaseIterable, Comparable {
    case closure
    case function
    case getter
    case `subscript`
    case initializer

    static func < (lhs: Self, rhs: Self) -> Bool {
      lhs.rawValue < rhs.rawValue
    }
  }

  static let defaultIncludedKinds = Set(ReturnKind.allCases)

  @OptionElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @OptionElement(key: "included")
  private(set) var includedKinds = Self.defaultIncludedKinds

  init(includedKinds: Set<ReturnKind> = Self.defaultIncludedKinds) {
    self.includedKinds = includedKinds
  }

  func isKindIncluded(_ kind: ReturnKind) -> Bool {
    includedKinds.contains(kind)
  }

  typealias Parent = ImplicitReturnRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$includedKinds.key] {
      try includedKinds.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
