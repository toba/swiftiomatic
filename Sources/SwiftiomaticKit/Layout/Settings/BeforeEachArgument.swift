/// Break before each argument when wrapping.
package struct BeforeEachArgument: LayoutDescriptor {
    package static let key = "beforeEachArgument"
    package static let group: ConfigGroup? = .lineBreaks
    package static let description = "Break before each argument when wrapping."
    package static let defaultValue = false
    package static let schema: ConfigProperty.Schema = .bool(
        description: description, defaultValue: defaultValue
    )
    package static let keyPath = \Configuration.lineBreakBeforeEachArgument
}
