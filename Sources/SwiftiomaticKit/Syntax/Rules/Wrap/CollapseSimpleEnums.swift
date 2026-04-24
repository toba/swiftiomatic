import SwiftSyntax

/// Collapses simple enums with no associated values, no raw values, and no
/// members other than cases onto a single line.
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
/// The rule only applies when the collapsed form fits within the configured
/// line length. Enums with associated values, explicit raw value assignments,
/// raw-value types (e.g. `: Int`, `: String`), computed properties, methods,
/// or any non-case member are left untouched.
final class CollapseSimpleEnums: RewriteSyntaxRule<BasicRuleValue> {
    override class var key: String { "collapseSimpleEnums" }
    override class var group: ConfigurationGroup? { .wrap }
    override class var defaultValue: BasicRuleValue {
        BasicRuleValue(rewrite: false, lint: .no)
    }

    private var maxLength: Int { context.configuration[LineLength.self] }

    override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
        guard isCollapsible(node) else { return DeclSyntax(node) }

        let allElements = collectElements(from: node)
        guard !allElements.isEmpty else { return DeclSyntax(node) }

        // Already on a single line — nothing to do.
        if node.memberBlock.members.count == 1,
           !node.memberBlock.rightBrace.leadingTrivia.containsNewlines {
            return DeclSyntax(node)
        }

        // Build the collapsed text to check line length.
        let caseList = allElements.map(\.name.text).joined(separator: ", ")
        let prefix = declPrefix(node)
        // "prefix { case a, b, c }"
        let collapsedLength = prefix.count + " { case ".count + caseList.count + " }".count
        let indent = node.leadingTrivia.indentation

        guard indent.count + collapsedLength <= maxLength else {
            return DeclSyntax(node)
        }

        diagnose(.collapseSimpleEnum, on: node)

        // Build a single EnumCaseDeclSyntax with all elements comma-separated.
        let elements = EnumCaseElementListSyntax(
            allElements.enumerated().map { index, element in
                var el = element.with(\.leadingTrivia, []).with(\.trailingTrivia, [])
                if index < allElements.count - 1 {
                    el = el.with(\.trailingComma, .commaToken(trailingTrivia: .space))
                } else {
                    el = el.with(\.trailingComma, nil)
                }
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

        var result = node
        result.memberBlock = MemberBlockSyntax(
            leftBrace: .leftBraceToken(),
            members: members,
            rightBrace: .rightBraceToken(leadingTrivia: .space)
        )

        return DeclSyntax(result)
    }
}

// MARK: - Helpers

extension CollapseSimpleEnums {

    /// The known Swift raw-value types that disqualify an enum from collapsing.
    private static let rawValueTypes: Set<String> = [
        "Int", "Int8", "Int16", "Int32", "Int64",
        "UInt", "UInt8", "UInt16", "UInt32", "UInt64",
        "Float", "Double", "String", "Character",
    ]

    /// Whether the enum can be collapsed onto a single line.
    private func isCollapsible(_ node: EnumDeclSyntax) -> Bool {
        let members = node.memberBlock.members
        // Must have at least one member, all must be case declarations.
        guard !members.isEmpty else { return false }

        for member in members {
            guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else {
                return false
            }
            for element in caseDecl.elements {
                if element.parameterClause != nil { return false }
                if element.rawValue != nil { return false }
            }
        }

        // Reject enums with raw-value type inheritance (e.g. `: String`, `: Int`).
        if let inheritance = node.inheritanceClause {
            for inherited in inheritance.inheritedTypes {
                let name = inherited.type.trimmedDescription
                if Self.rawValueTypes.contains(name) { return false }
            }
        }

        return true
    }

    /// Collects all `EnumCaseElementSyntax` from the enum's case declarations.
    private func collectElements(from node: EnumDeclSyntax) -> [EnumCaseElementSyntax] {
        node.memberBlock.members.flatMap { member -> [EnumCaseElementSyntax] in
            guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else { return [] }
            return Array(caseDecl.elements)
        }
    }

    /// The text before the opening brace (e.g. "private enum Kind").
    private func declPrefix(_ node: EnumDeclSyntax) -> String {
        var text = ""
        for token in node.tokens(viewMode: .sourceAccurate) {
            if token.tokenKind == .leftBrace { break }
            text += token.text
            if !token.trailingTrivia.isEmpty {
                text += token.trailingTrivia.description
            }
        }
        // Trim any trailing whitespace before the brace.
        while text.last?.isWhitespace == true { text.removeLast() }
        return text
    }
}

// MARK: - Finding Messages

extension Finding.Message {
    fileprivate static let collapseSimpleEnum: Finding.Message =
        "collapse simple enum onto a single line"
}
