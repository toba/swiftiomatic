import SwiftSyntax

/// Enforce consistent use of `#file` or `#fileID` .
///
/// In Swift 6+, `#file` and `#fileID` have identical behavior (both produce `Module/File.swift` ).
/// This rule standardizes usage to `#fileID` by default. `#filePath` is unaffected.
///
/// Lint: Using the non-preferred file macro yields a lint warning.
///
/// Rewrite: The macro is replaced with the preferred spelling.
final class PreferFileID: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override static var group: ConfigurationGroup? { .idioms }
    override static var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }

    static func transform(
        _ node: MacroExpansionExprSyntax,
        original _: MacroExpansionExprSyntax,
        parent _: Syntax?,
        context: Context
    ) -> ExprSyntax {
        // Only handle bare #file / #fileID (no arguments, no trailing closure).
        guard node.arguments.isEmpty,
              node.trailingClosure == nil,
              node.genericArgumentClause == nil else { return ExprSyntax(node) }

        let macroName = node.macroName.text

        switch macroName {
            case "file":
                Self.diagnose(.preferFileID, on: node, context: context)
                var result = node
                result.macroName = result.macroName.with(\.tokenKind, .identifier("fileID"))
                return ExprSyntax(result)

            case "fileID": return ExprSyntax(node)

            default: return ExprSyntax(node)
        }
    }
}

fileprivate extension Finding.Message {
    static let preferFileID: Finding.Message =
        "replace '#file' with '#fileID'; they are equivalent in Swift 6+"
}
