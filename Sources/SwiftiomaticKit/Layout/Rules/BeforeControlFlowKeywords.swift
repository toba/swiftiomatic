/// Break before else/catch after closing brace.
package struct BeforeControlFlowKeywords: LayoutRule {
    package static let key = "beforeControlFlowKeywords"
    package static let group: ConfigurationGroup? = .lineBreaks
    package static let description = "Break before else/catch after closing brace."
    package static let defaultValue = false
}
