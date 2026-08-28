/// A named group of related rules and settings in the configuration.
///
/// Groups appear as JSON objects at the config root. Rules and settings that belong to a group are
/// encoded inside their group's object; ungrouped items live at the config root.
package enum ConfigurationGroup: String, CaseIterable, Sendable, Hashable, Codable {
    /// Spelled `ConfigurationGroup.Key` by callers that name the raw key type.
    package typealias Key = ConfigurationGroup

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
    /// Where line breaks are allowed or required (line length, break-before-X toggles). Distinct
    /// from `wrap` , which controls how multi-line constructs are formatted.
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
    /// How multi-line constructs are formatted (function chains, switch bodies, brace placement).
    /// Distinct from `lineBreaks` , which controls where breaks occur.
    case wrap
}
