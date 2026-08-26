import SwiftSyntax

/// Collapses simple enums with no associated values, no raw values, and no members other than cases
/// onto a single line.
///
/// ```swift
/// // Before
/// private enum Kind {
///     case chained
///     case forced
/// }
///
/// // After
/// private enum Kind { case chained, forced }
/// ```
///
/// The rule only applies when the collapsed form fits within the configured line length. Enums with
/// associated values, explicit raw value assignments, raw-value types (e.g. `: Int` , `: String` ),
/// computed properties, methods, or any non-case member are left untouched.
final class CollapseSimpleEnums: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override static var group: ConfigurationGroup? { .wrap }
    override static var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }

    static func transform(
        _ recursed: EnumDeclSyntax,
        original _: EnumDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        let maxLength = context.configuration[LineLength.self]
        guard isCollapsible(recursed) else { return DeclSyntax(recursed) }

        let allElements = collectElements(from: recursed)
        guard !allElements.isEmpty else { return DeclSyntax(recursed) }

        // Already on a single line — nothing to do.
        if recursed.memberBlock.members.count == 1,
           !recursed.memberBlock.rightBrace.leadingTrivia.containsNewlines {
            return DeclSyntax(recursed)
        }

        // Build the collapsed text to check line length.
        let caseList = allElements.map(\.trimmedDescription).joined(separator: ", ")
        let prefix = declPrefix(recursed)
        // "prefix { case a, b, c }"
        let collapsedLength = prefix.count + " { case ".count + caseList.count + " }".count
        let indent = recursed.leadingTrivia.indentation

        guard indent.count + collapsedLength <= maxLength else { return DeclSyntax(recursed) }

        Self.diagnose(.collapseSimpleEnum, on: recursed, context: context)

        // Build a single EnumCaseDeclSyntax with all elements comma-separated.
        let elements = EnumCaseElementListSyntax(
            allElements.enumerated().map { index, element in
                var el = element.with(\.leadingTrivia, []).with(\.trailingTrivia, [])
                el = index < allElements.count - 1
                    ? el.with(\.trailingComma, .commaToken(trailingTrivia: .space))
                    : el.with(\.trailingComma, nil)
                return el
            }
        )

        let caseDecl = EnumCaseDeclSyntax(
            leadingTrivia: .space,
            caseKeyword: .keyword(.case, trailingTrivia: .space),
            elements: elements
        )

        let member = MemberBlockItemSyntax(decl: caseDecl)
        let members = MemberBlockItemListSyntax([member])

        var result = recursed
        result.memberBlock = MemberBlockSyntax(
            leftBrace: .leftBraceToken(),
            members: members,
            rightBrace: .rightBraceToken(leadingTrivia: .space)
        )

        return .init(result)
    }
}

// MARK: - Helpers

fileprivate extension CollapseSimpleEnums {
    /// Whether the enum can be collapsed onto a single line.
    ///
    /// Raw-value-typed enums collapse whether or not the cases assign explicit raw values — the
    /// comma-separated form `enum E: Int { case a = 0, b = 1 }` carries the same semantics as the
    /// expanded form. Only associated values block collapsing.
    static func isCollapsible(_ node: EnumDeclSyntax) -> Bool {
        let members = node.memberBlock.members
        // Must have at least one member, all must be case declarations.
        guard !members.isEmpty else { return false }

        // The collapse rebuilds the member block from the case elements alone, so every comment
        // between the braces would be dropped.
        if node.memberBlock.containsComments() { return false }

        for member in members {
            guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else { return false }

            for element in caseDecl.elements where element.parameterClause != nil { return false }
        }

        return true
    }

    /// Collects all `EnumCaseElementSyntax` from the enum's case declarations.
    static func collectElements(from node: EnumDeclSyntax) -> [EnumCaseElementSyntax] {
        node.memberBlock.members.flatMap { member -> [EnumCaseElementSyntax] in
            guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else { return [] }
            return Array(caseDecl.elements)
        }
    }

    /// The text before the opening brace (e.g. "private enum Kind").
    static func declPrefix(_ node: EnumDeclSyntax) -> String {
        var text = ""

        for token in node.tokens(viewMode: .sourceAccurate) {
            if token.tokenKind == .leftBrace { break }
            text += token.text

            if !token.trailingTrivia.isEmpty { text += token.trailingTrivia.description }
        }
        // Trim any trailing whitespace before the brace.
        while text.last?.isWhitespace == true { text.removeLast() }
        return text
    }
}

// MARK: - Finding Messages

fileprivate extension Finding.Message {
    static let collapseSimpleEnum: Finding.Message = "collapse simple enum onto a single line"
}
