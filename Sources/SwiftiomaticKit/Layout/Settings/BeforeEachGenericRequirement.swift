/// Break before each generic requirement when wrapping.
package struct BeforeEachGenericRequirement: LayoutDescriptor {
    package static let key = "beforeEachGenericRequirement"
    package static let group: ConfigurationGroup? = .lineBreaks
    package static let description = "Break before each generic requirement when wrapping."
    package static let defaultValue = false
}
