/// Trailing comma handling in multiline lists.
package struct MultilineTrailingCommaBehaviorSetting: LayoutDescriptor {
    package static let key = "multilineTrailingCommaBehavior"
    package static let description = "Trailing comma handling in multiline lists."
    package static let defaultValue: Configuration.MultilineTrailingCommaBehavior = .keptAsWritten
    package static let schema: ConfigProperty.Schema = .stringEnum(
        description: description,
        values: ["alwaysUsed", "neverUsed", "keptAsWritten"],
        defaultValue: "keptAsWritten"
    )
    package static let keyPath = \Configuration.multilineTrailingCommaBehavior
}
