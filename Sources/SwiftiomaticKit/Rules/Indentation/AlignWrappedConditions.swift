import SwiftSyntax

/// Align wrapped conditions to the column after the keyword.
///
/// When enabled, continuation conditions in `if` , `guard` , and `while` statements align to the
/// first condition rather than using standard continuation indentation.
///
/// ```swift
/// // default (false):
/// if let attr = element.as(AttributeSyntax.self),
///     let name = attr.attributeName.as(IdentifierTypeSyntax.self) {
///
/// // aligned (true):
/// if let attr = element.as(AttributeSyntax.self),
///    let name = attr.attributeName.as(IdentifierTypeSyntax.self) {
///
/// guard let attr = element.as(AttributeSyntax.self),
///       let name = attr.attributeName.as(IdentifierTypeSyntax.self) else {
/// ```
package struct AlignWrappedConditions: LayoutRule {
    package static let group: ConfigurationGroup? = .indentation
    package static let description =
        "Align wrapped conditions to the column after the keyword (if/guard/while)."
    package static let defaultValue = false
}
