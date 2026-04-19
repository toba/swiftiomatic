/// Break before each argument when wrapping.
package struct BeforeEachArgument: LayoutDescriptor {
    package static let key = "beforeEachArgument"
    package static let group: ConfigurationGroup? = .lineBreaks
    package static let description = "Break before each argument when wrapping."
    package static let defaultValue = false
}
