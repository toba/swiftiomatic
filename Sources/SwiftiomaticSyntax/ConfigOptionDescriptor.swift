/// The kind of value a configuration option accepts
public enum ConfigValueType: String, Sendable, Codable, Hashable {
    case bool
    case string
    case int
    case float
    case severity
    case list
    case `enum`
}

/// Describes a single configurable option for a rule, bridging both
/// ``RuleOptionsDescription`` (lint rules) and ``OptionDescriptor`` (format rules)
/// into a uniform representation for app UX and documentation.
public struct ConfigOptionDescriptor: Sendable, Codable, Hashable {
    /// The configuration key (e.g. "severity", "min_length")
    public let key: String

    /// Human-readable display name
    public let displayName: String

    /// Help text describing what this option controls
    public let help: String

    /// The type of value this option accepts
    public let valueType: ConfigValueType

    /// The default value as a string representation
    public let defaultValue: String?

    /// Valid values for enum-type options, `nil` for free-form values
    public let validValues: [String]?

    public init(
        key: String,
        displayName: String,
        help: String,
        valueType: ConfigValueType,
        defaultValue: String,
        validValues: [String]? = nil,
    ) {
        self.key = key
        self.displayName = displayName
        self.help = help
        self.valueType = valueType
        self.defaultValue = defaultValue
        self.validValues = validValues
    }
}

