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
        case access
        case blankLines
        case closures
        case comments
        case conditions
        case declarations
        case forcing
        case generics
        case hoist
        case idioms
        case indentation
        case lineBreaks
        case literals
        case metrics
        case naming
        case redundancies
        case sort
        case spaces
        case testing
        case types
        case wrap
    }

    // MARK: - Static accessors for use in rule/setting declarations

    package static let access = ConfigurationGroup(.access)
    package static let blankLines = ConfigurationGroup(.blankLines)
    package static let closures = ConfigurationGroup(.closures)
    package static let comments = ConfigurationGroup(.comments)
    package static let conditions = ConfigurationGroup(.conditions)
    package static let declarations = ConfigurationGroup(.declarations)
    package static let forcing = ConfigurationGroup(.forcing)
    package static let generics = ConfigurationGroup(.generics)
    package static let hoist = ConfigurationGroup(.hoist)
    package static let idioms = ConfigurationGroup(.idioms)
    package static let indentation = ConfigurationGroup(.indentation)
    package static let lineBreaks = ConfigurationGroup(.lineBreaks)
    package static let literals = ConfigurationGroup(.literals)
    package static let metrics = ConfigurationGroup(.metrics)
    package static let naming = ConfigurationGroup(.naming)
    package static let redundancies = ConfigurationGroup(.redundancies)
    package static let sort = ConfigurationGroup(.sort)
    package static let spaces = ConfigurationGroup(.spaces)
    package static let testing = ConfigurationGroup(.testing)
    package static let types = ConfigurationGroup(.types)
    package static let wrap = ConfigurationGroup(.wrap)
}
