/// A named group of related rules and settings in the configuration.
///
/// Groups appear as JSON objects at the config root. Rules and settings that
/// belong to a group are encoded inside their group's object; ungrouped items
/// live at the config root.
package struct ConfigurationGroup: Sendable, Hashable {
    package let key: Key

    package init(_ key: Key) { self.key = key }

    /// Init from raw string value (for code generation compatibility).
    package init?(rawValue: String) {
        guard let key = Key(rawValue: rawValue) else { return nil }
        self.key = key
    }

    /// Group key identifiers matching JSON object names.
    package enum Key: String, CaseIterable, Sendable, Codable {
        case sort
        case wrap
        case hoist
        case spaces
        case forcing
        case comments
        case blankLines
        case lineBreaks
        case indentation
        case redundancies
        case capitalization
    }

    // MARK: - Static accessors for use in rule/setting declarations

    package static let sort = ConfigurationGroup(.sort)
    package static let wrap = ConfigurationGroup(.wrap)
    package static let hoist = ConfigurationGroup(.hoist)
    package static let spaces = ConfigurationGroup(.spaces)
    package static let forcing = ConfigurationGroup(.forcing)
    package static let comments = ConfigurationGroup(.comments)
    package static let blankLines = ConfigurationGroup(.blankLines)
    package static let lineBreaks = ConfigurationGroup(.lineBreaks)
    package static let indentation = ConfigurationGroup(.indentation)
    package static let redundancies = ConfigurationGroup(.redundancies)
    package static let capitalization = ConfigurationGroup(.capitalization)
}
