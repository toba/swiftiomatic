import SwiftSyntax

/// Use `@Entry` macro for `EnvironmentValues` instead of manual `EnvironmentKey` conformance.
///
/// Recognizes `EnvironmentKey` -conforming structs/enums paired with `EnvironmentValues` extension
/// properties and replaces them with `@Entry var` declarations.
///
/// Lint: A lint warning is raised when an `EnvironmentKey` property can be replaced with `@Entry` .
///
/// Rewrite: The `EnvironmentKey` type is removed and the property is replaced with `@Entry var` .
final class UseAtEntryNotEnvironmentKey: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }

    override static var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }

    // MARK: - Types

    struct KeyInfo {
        let name: String
        let defaultValue: DefaultValue?
        let statementIndex: Int
    }

    enum DefaultValue {
        case expression(ExprSyntax)
        case closureBody(statements: CodeBlockItemListSyntax, rightBraceTrivia: Trivia)
    }

    // MARK: - State

    /// Per-file mutable state held as a typed lazy property on `Context` .
    final class State {
        var environmentKeys: [String: KeyInfo] = [:]
        var matchedKeys: Set<String> = []
    }

    // MARK: - Pre-scan

    static func willEnter(_ node: SourceFileSyntax, context: Context) {
        let state = context.preferEnvironmentEntryState
        Self.collectEnvironmentKeys(from: node.statements, into: &state.environmentKeys)
    }

    // MARK: - Static transform

    static func transform(
        _ node: SourceFileSyntax,
        original _: SourceFileSyntax,
        parent _: Syntax?,
        context: Context
    ) -> SourceFileSyntax {
        let state = context.preferEnvironmentEntryState
        guard !state.environmentKeys.isEmpty else { return node }

        let newStatements = rewriteStatements(
            node.statements,
            environmentKeys: state.environmentKeys,
            matchedKeys: &state.matchedKeys,
            context: context
        )
        guard !state.matchedKeys.isEmpty else { return node }

        var result = node
        result.statements = newStatements
        return result
    }

    private static func collectEnvironmentKeys(
        from statements: CodeBlockItemListSyntax,
        into environmentKeys: inout [String: KeyInfo]
    ) {
        for (index, item) in statements.enumerated() {
            guard case let .decl(decl) = item.item else { continue }

            if let structDecl = decl.as(StructDeclSyntax.self) {
                collectIfEnvironmentKey(
                    name: structDecl.name.text,
                    inheritanceClause: structDecl.inheritanceClause,
                    members: structDecl.memberBlock.members,
                    statementIndex: index,
                    into: &environmentKeys
                )
            } else if let enumDecl = decl.as(EnumDeclSyntax.self) {
                collectIfEnvironmentKey(
                    name: enumDecl.name.text,
                    inheritanceClause: enumDecl.inheritanceClause,
                    members: enumDecl.memberBlock.members,
                    statementIndex: index,
                    into: &environmentKeys
                )
            }
        }
    }

    private static func collectIfEnvironmentKey(
        name: String,
        inheritanceClause: InheritanceClauseSyntax?,
        members: MemberBlockItemListSyntax,
        statementIndex: Int,
        into environmentKeys: inout [String: KeyInfo]
    ) {
        guard let inheritanceClause,
              inheritanceClause.contains(named: "EnvironmentKey"),
              let onlyMember = members.firstAndOnly,
              let varDecl = onlyMember.decl.as(VariableDeclSyntax.self),
              let binding = varDecl.bindings.first,
              let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
              pattern.identifier.text == "defaultValue" else { return }

        environmentKeys[name] = KeyInfo(
            name: name,
            defaultValue: extractDefaultValue(from: binding),
            statementIndex: statementIndex
        )
    }

    private static func extractDefaultValue(from binding: PatternBindingSyntax) -> DefaultValue? {
        if let initializer = binding.initializer { return .expression(initializer.value.trimmed) }
        guard let accessorBlock = binding.accessorBlock else { return nil }

        switch accessorBlock.accessors {
            case let .getter(body):
                if let onlyItem = body.firstAndOnly {
                    if case let .expr(expr) = onlyItem.item { return .expression(expr.trimmed) }

                    if case let .stmt(stmt) = onlyItem.item,
                       let returnStmt = stmt.as(ReturnStmtSyntax.self),
                       let expr = returnStmt.expression
                    {
                        return .expression(expr.trimmed)
                    }
                }
                return .closureBody(
                    statements: body,
                    rightBraceTrivia: accessorBlock.rightBrace.leadingTrivia
                )
            case .accessors: return nil
        }
    }

    private static func rewriteStatements(
        _ statements: CodeBlockItemListSyntax,
        environmentKeys: [String: KeyInfo],
        matchedKeys: inout Set<String>,
        context: Context
    ) -> CodeBlockItemListSyntax {
        var items = Array(statements)

        for (index, item) in items.enumerated() {
            guard case let .decl(decl) = item.item,
                  let extDecl = decl.as(ExtensionDeclSyntax.self),
                  extDecl.extendedType.trimmedDescription == "EnvironmentValues" else { continue }

            let rewritten = rewriteEnvironmentValuesExtension(
                extDecl,
                environmentKeys: environmentKeys,
                matchedKeys: &matchedKeys,
                context: context
            )
            items[index].item = .decl(DeclSyntax(rewritten))
        }

        guard !matchedKeys.isEmpty else { return CodeBlockItemListSyntax(items) }

        let removedIndices = Set(matchedKeys.compactMap { environmentKeys[$0]?.statementIndex })
        var filteredItems = [CodeBlockItemSyntax]()
        var removedFirst = false

        for (index, item) in items.enumerated() {
            if removedIndices.contains(index) {
                if index == 0 { removedFirst = true }
                continue
            }
            filteredItems.append(item)
        }

        if removedFirst, var first = filteredItems.first {
            first.leadingTrivia = Trivia(
                pieces: first.leadingTrivia.drop {
                    switch $0 {
                        case .newlines, .carriageReturns, .carriageReturnLineFeeds, .spaces, .tabs:
                            true
                        default: false
                    }
                })
            filteredItems[0] = first
        }

        return .init(filteredItems)
    }

    private static func rewriteEnvironmentValuesExtension(
        _ extDecl: ExtensionDeclSyntax,
        environmentKeys: [String: KeyInfo],
        matchedKeys: inout Set<String>,
        context: Context
    ) -> ExtensionDeclSyntax {
        var capturedMatched = matchedKeys
        let newMembers = extDecl.memberBlock.members.map { member -> MemberBlockItemSyntax in
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                  let rewritten = rewriteEnvironmentProperty(
                      varDecl,
                      environmentKeys: environmentKeys,
                      matchedKeys: &capturedMatched,
                      context: context
                  ) else { return member }
            var result = member
            result.decl = DeclSyntax(rewritten)
            return result
        }
        matchedKeys = capturedMatched
        var result = extDecl
        result.memberBlock.members = MemberBlockItemListSyntax(newMembers)
        return result
    }

    private static func rewriteEnvironmentProperty(
        _ varDecl: VariableDeclSyntax,
        environmentKeys: [String: KeyInfo],
        matchedKeys: inout Set<String>,
        context: Context
    ) -> VariableDeclSyntax? {
        guard let binding = varDecl.bindings.first,
              let accessorBlock = binding.accessorBlock,
              hasGetterAndSetter(accessorBlock) else { return nil }

        let keyName = varDecl.tokens(viewMode: .sourceAccurate).lazy
            .compactMap { token -> String? in
                guard case let .identifier(text) = token.tokenKind,
                      environmentKeys[text] != nil else { return nil }
                return text
            }
            .first

        guard let keyName, let keyInfo = environmentKeys[keyName] else { return nil }

        matchedKeys.insert(keyName)
        Self.diagnose(.useEntryMacro, on: varDecl, context: context)

        var newBinding = binding
        newBinding.accessorBlock = nil

        if var typeAnnotation = newBinding.typeAnnotation {
            typeAnnotation.type = typeAnnotation.type.trimmed
            newBinding.typeAnnotation = typeAnnotation
        }

        switch keyInfo.defaultValue {
            case let .expression(expr):
                newBinding.initializer = InitializerClauseSyntax(
                    equal: .equalToken(leadingTrivia: .space, trailingTrivia: .space),
                    value: ExprSyntax(expr)
                )
            case let .closureBody(statements, rightBraceTrivia):
                let closure = ClosureExprSyntax(
                    statements: statements,
                    rightBrace: .rightBraceToken(leadingTrivia: rightBraceTrivia)
                )
                let call = FunctionCallExprSyntax(
                    calledExpression: ExprSyntax(closure),
                    leftParen: .leftParenToken(),
                    arguments: [],
                    rightParen: .rightParenToken()
                )
                newBinding.initializer = InitializerClauseSyntax(
                    equal: .equalToken(leadingTrivia: .space, trailingTrivia: .space),
                    value: ExprSyntax(call)
                )
            case nil: break
        }

        var result = varDecl
        result.bindings = PatternBindingListSyntax([newBinding])

        return addEntryAttribute(to: result)
    }

    private static func hasGetterAndSetter(_ accessorBlock: AccessorBlockSyntax) -> Bool {
        guard case let .accessors(accessors) = accessorBlock.accessors else { return false }
        var hasGetter = false
        var hasSetter = false

        for accessor in accessors {
            switch accessor.accessorSpecifier.tokenKind {
                case .keyword(.get): hasGetter = true
                case .keyword(.set): hasSetter = true
                default: break
            }
        }
        return hasGetter && hasSetter
    }

    private static func addEntryAttribute(to varDecl: VariableDeclSyntax) -> VariableDeclSyntax {
        var result = varDecl
        let savedTrivia: Trivia

        if let firstModifier = result.modifiers.first {
            savedTrivia = firstModifier.leadingTrivia
            result.modifiers[result.modifiers.startIndex] = firstModifier.with(\.leadingTrivia, [])
        } else {
            savedTrivia = result.bindingSpecifier.leadingTrivia
            result.bindingSpecifier = result.bindingSpecifier.with(\.leadingTrivia, [])
        }

        let entryAttr = AttributeSyntax(
            atSign: .atSignToken(leadingTrivia: savedTrivia),
            attributeName: IdentifierTypeSyntax(
                name: TokenSyntax(
                    .identifier("Entry"),
                    trailingTrivia: .space,
                    presence: .present
                ))
        )

        var elements = Array(result.attributes)
        elements.insert(AttributeListSyntax.Element(entryAttr), at: 0)
        result.attributes = AttributeListSyntax(elements)

        return result
    }
}

fileprivate extension Finding.Message {
    static let useEntryMacro: Finding.Message =
        "use '@Entry' macro instead of manual 'EnvironmentKey' conformance"
}
