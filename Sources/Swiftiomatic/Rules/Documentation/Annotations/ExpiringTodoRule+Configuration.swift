struct ExpiringTodoConfiguration: RuleOptions {
  typealias Severity = SeverityConfiguration<Parent>

  struct DelimiterConfiguration: Equatable, AcceptableByConfigurationElement {
    static let `default`: DelimiterConfiguration = .init(opening: "[", closing: "]")

    fileprivate(set) var opening: String
    fileprivate(set) var closing: String

    init(fromAny value: Any, context ruleID: String) throws(SwiftiomaticError) {
      guard let dateDelimiters = value as? [String: String],
        let openingDelimiter = dateDelimiters["opening"],
        let closingDelimiter = dateDelimiters["closing"]
      else {
        throw .invalidConfiguration(ruleID: ruleID)
      }
      self.init(opening: openingDelimiter, closing: closingDelimiter)
    }

    init(opening: String, closing: String) {
      self.opening = opening
      self.closing = closing
    }

    func asOption() -> OptionType {
      .nest {
        "opening" => .string(opening)
        "closing" => .string(closing)
      }
    }
  }

  @ConfigurationElement(key: "approaching_expiry_severity")
  private(set) var approachingExpirySeverity = Severity(.warning)
  @ConfigurationElement(key: "expired_severity")
  private(set) var expiredSeverity = Severity(.error)
  @ConfigurationElement(key: "bad_formatting_severity")
  private(set) var badFormattingSeverity = Severity(.error)

  // sm:disable:next todo
  /// The number of days prior to expiry before the TODO emits a violation
  @ConfigurationElement(key: "approaching_expiry_threshold")
  private(set) var approachingExpiryThreshold = 15
  /// The opening/closing characters used to surround the expiry-date string
  @ConfigurationElement(key: "date_delimiters")
  private(set) var dateDelimiters = DelimiterConfiguration.default
  /// The format which should be used to the expiry-date string into a `Date` object
  @ConfigurationElement(key: "date_format")
  private(set) var dateFormat = "MM/dd/yyyy"
  /// The separator used for regex detection of the expiry-date string
  @ConfigurationElement(key: "date_separator")
  private(set) var dateSeparator = "/"
  typealias Parent = ExpiringTodoRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    if let value = configuration[$approachingExpirySeverity.key] {
      try approachingExpirySeverity.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$expiredSeverity.key] {
      try expiredSeverity.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$badFormattingSeverity.key] {
      try badFormattingSeverity.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$approachingExpiryThreshold.key] {
      try approachingExpiryThreshold.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$dateDelimiters.key] {
      try dateDelimiters.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$dateFormat.key] {
      try dateFormat.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$dateSeparator.key] {
      try dateSeparator.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
