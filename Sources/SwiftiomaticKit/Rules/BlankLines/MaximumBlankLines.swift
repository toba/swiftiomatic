/// Maximum consecutive blank lines.
package struct MaximumBlankLines: LayoutRule {
    package static let key = "maximumBlankLines"
    package static let group: ConfigurationGroup? = .blankLines
    package static let description = "Maximum consecutive blank lines."
    package static let defaultValue = 1
}
