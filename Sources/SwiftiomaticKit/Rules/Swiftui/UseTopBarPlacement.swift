import SwiftSyntax

/// Replace `.navigationBarLeading` / `.navigationBarTrailing` with `.topBarLeading` /
/// `.topBarTrailing` .
///
/// SwiftUI deprecates the `navigationBar` toolbar placements. The `topBar` placements have the same
/// meaning and work on every platform that has a top bar.
///
/// The rule matches an implicit member (`.navigationBarLeading`) or a member of
/// `ToolbarItemPlacement` . It does not check the type of an implicit member.
///
/// Lint: Using `.navigationBarLeading` or `.navigationBarTrailing` raises a warning.
///
/// Rewrite: The member name becomes `topBarLeading` or `topBarTrailing` . Trivia stays.
final class UseTopBarPlacement: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    static let rewriteOrder = 643

    override class var group: ConfigurationGroup? { .swiftui }

    private static let replacements = [
        "navigationBarLeading": "topBarLeading",
        "navigationBarTrailing": "topBarTrailing",
    ]

    static func transform(
        _ node: MemberAccessExprSyntax,
        original _: MemberAccessExprSyntax,
        parent _: Syntax?,
        context: Context
    ) -> ExprSyntax {
        let oldName = node.declName.baseName.text
        guard node.declName.argumentNames == nil,
              let newName = replacements[oldName] else { return ExprSyntax(node) }

        if let base = node.base {
            guard base.as(DeclReferenceExprSyntax.self)?.baseName.text == "ToolbarItemPlacement"
            else { return ExprSyntax(node) }
        }

        Self.diagnose(.useTopBar(newName, insteadOf: oldName), on: node, context: context)

        let newToken = node.declName.baseName.with(\.tokenKind, .identifier(newName))
        return ExprSyntax(node.with(\.declName.baseName, newToken))
    }
}

fileprivate extension Finding.Message {
    static func useTopBar(_ replacement: String, insteadOf name: String) -> Finding.Message {
        "replace '.\(name)' with '.\(replacement)'"
    }
}
