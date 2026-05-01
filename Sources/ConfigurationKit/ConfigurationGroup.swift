/// A named group of related rules and settings in the configuration.
///
/// Groups appear as JSON objects at the config root. Rules and settings that belong to a group are
/// encoded inside their group's object; ungrouped items live at the config root.
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
        /// Collection-API idioms (`isEmpty`, `flatMap`, `contains`, `first/last(where:)`, etc.).
        case collections
        case comments
        case conditions
        /// Loop and iteration shape (`for`-loop vs `forEach`, `where` clauses on `for`).
        case controlFlow
        case declarations
        case generics
        case hoist
        case idioms
        case indentation
        /// Where line breaks are allowed or required (line length, break-before-X toggles).
        /// Distinct from `wrap` , which controls how multi-line constructs are formatted.
        case lineBreaks
        case literals
        case memory
        case metrics
        case naming
        case redundancies
        case sort
        case spaces
        /// SwiftUI-specific patterns (`@Entry`, `View.body`, `ForEach(id:)`).
        case swiftui
        case testing
        case types
        case unsafety
        /// How multi-line constructs are formatted (function chains, switch bodies, brace
        /// placement). Distinct from `lineBreaks` , which controls where breaks occur.
        case wrap
    }

    // MARK: - Static accessors for use in rule/setting declarations

    package static let access = ConfigurationGroup(.access)
    package static let blankLines = ConfigurationGroup(.blankLines)
    package static let closures = ConfigurationGroup(.closures)
    package static let collections = ConfigurationGroup(.collections)
    package static let comments = ConfigurationGroup(.comments)
    package static let conditions = ConfigurationGroup(.conditions)
    package static let controlFlow = ConfigurationGroup(.controlFlow)
    package static let declarations = ConfigurationGroup(.declarations)
    package static let generics = ConfigurationGroup(.generics)
    package static let hoist = ConfigurationGroup(.hoist)
    package static let idioms = ConfigurationGroup(.idioms)
    package static let indentation = ConfigurationGroup(.indentation)
    package static let lineBreaks = ConfigurationGroup(.lineBreaks)
    package static let literals = ConfigurationGroup(.literals)
    package static let memory = ConfigurationGroup(.memory)
    package static let metrics = ConfigurationGroup(.metrics)
    package static let naming = ConfigurationGroup(.naming)
    package static let redundancies = ConfigurationGroup(.redundancies)
    package static let sort = ConfigurationGroup(.sort)
    package static let spaces = ConfigurationGroup(.spaces)
    package static let swiftui = ConfigurationGroup(.swiftui)
    package static let testing = ConfigurationGroup(.testing)
    package static let types = ConfigurationGroup(.types)
    package static let unsafety = ConfigurationGroup(.unsafety)
    package static let wrap = ConfigurationGroup(.wrap)
}
