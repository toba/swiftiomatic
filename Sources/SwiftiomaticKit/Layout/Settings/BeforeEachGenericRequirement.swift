/// Break before each generic requirement when wrapping.
package struct BeforeEachGenericRequirement: LayoutDescriptor {
    package static let key = "beforeEachGenericRequirement"
    package static let group: ConfigGroup? = .lineBreaks
    package static let description = "Break before each generic requirement when wrapping."
    package static let defaultValue = false
    package static let schema: ConfigProperty.Schema = .bool(
        description: description, defaultValue: defaultValue
    )
    package static let keyPath = \Configuration.lineBreakBeforeEachGenericRequirement
}
