/// Keep return type with closing parenthesis.
package struct KeepReturnTypeWithSignature: LayoutRule {
    package static let key = "keepReturnTypeWithSignature"
    package static let group: ConfigurationGroup? = .wrap
    package static let description = "Keep return type with closing parenthesis."
    package static let defaultValue = false
}
