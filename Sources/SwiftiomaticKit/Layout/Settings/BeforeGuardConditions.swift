/// Break before guard conditions.
package struct BeforeGuardConditions: LayoutDescriptor {
    package static let key = "beforeGuardConditions"
    package static let group: ConfigGroup? = .lineBreaks
    package static let description =
        "Break before guard conditions. When true, all conditions start on a new line below guard. When false, the first condition stays on the same line as guard."
    package static let defaultValue = true
    package static let schema: ConfigProperty.Schema = .bool(
        description: description, defaultValue: defaultValue
    )
    package static let keyPath = \Configuration.lineBreakBeforeGuardConditions
}
