/// A named group of related rules and settings in the configuration.
///
/// Groups appear as JSON objects at the config root. Rules and settings that
/// belong to a group are encoded inside their group's object; ungrouped items
/// live at the config root.
package enum ConfigGroup: String, CaseIterable, Sendable {
    case sort
    case wrap
    case hoist
    case forcing
    case comments
    case blankLines
    case lineBreaks
    case indentation
    case redundancies
    case capitalization
}

extension ConfigGroup: ConfigRepresentable {
    // Layout setting config properties are derived from LayoutDescriptor types
    // (see LayoutSettings). The schema generator reads them via
    // LayoutSettings.settings(in:) rather than this conformance.
}

/// Declares optional membership in a ``ConfigGroup``.
///
/// Items in a group encode/decode inside the group's JSON object.
/// Items with `nil` group live at the config root.
package protocol Groupable {
    /// The config group this item belongs to, or `nil` if ungrouped.
    static var group: ConfigGroup? { get }
}
