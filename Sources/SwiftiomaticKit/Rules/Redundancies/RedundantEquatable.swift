import SwiftSyntax

/// Remove a hand-written `Equatable` implementation when the compiler-synthesized
/// conformance would be equivalent.
///
/// For structs conforming to `Equatable` (or `Hashable`), if the `static func ==`
/// compares exactly the same stored instance properties that the compiler would
/// synthesize, the hand-written implementation is redundant and can be removed.
///
/// Closures, enums, and extension-based conformances are not handled.
///
/// The detection is heuristic (no type-checking).
///
/// Lint: A redundant `==` implementation raises a warning.
///
/// Rewrite: The `==` function is removed from the member block.
final class RedundantEquatable: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var defaultValue: BasicRuleValue { BasicRuleValue(rewrite: false, lint: .no) }
    override class var group: ConfigurationGroup? { .redundancies }

    static func transform(
        _ visited: StructDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        guard let inheritanceClause = visited.inheritanceClause,
            inheritanceClause.contains(named: "Equatable")
                || inheritanceClause.contains(named: "Hashable")
        else { return DeclSyntax(visited) }

        guard let removal = findRemovableEquatable(in: visited.memberBlock.members)
        else { return DeclSyntax(visited) }

        Self.diagnose(.removeRedundantEquatable, on: removal.funcDecl, context: context)

        var result = visited
        result.memberBlock.members = removeItem(
            at: removal.memberIndex,
            from: visited.memberBlock.members
        )
        return DeclSyntax(result)
    }

    // MARK: - Analysis

    private struct RemovableEquatable {
        let funcDecl: FunctionDeclSyntax
        let memberIndex: Int
    }

    private static func findRemovableEquatable(
        in members: MemberBlockItemListSyntax
    ) -> RemovableEquatable? {
        let storedProps = collectStoredPropertyNames(from: members)
        guard !storedProps.isEmpty else { return nil }

        for (index, member) in members.enumerated() {
            guard let funcDecl = member.decl.as(FunctionDeclSyntax.self),
                isEquatableOperator(funcDecl)
            else { continue }

            // Skip functions with attributes (e.g., @usableFromInline, @inlinable)
            guard funcDecl.attributes.isEmpty else { return nil }

            guard let comparedProps = parseComparedProperties(from: funcDecl),
                comparedProps == storedProps
            else { return nil }

            return RemovableEquatable(funcDecl: funcDecl, memberIndex: index)
        }

        return nil
    }

    // MARK: - Stored properties

    private static func collectStoredPropertyNames(
        from members: MemberBlockItemListSyntax
    ) -> Set<String> {
        var props = Set<String>()
        for member in members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                !varDecl.modifiers.contains(anyOf: [.static, .class]),
                varDecl.bindings.count == 1,
                let binding = varDecl.bindings.first,
                let identPattern = binding.pattern.as(IdentifierPatternSyntax.self)
            else { continue }

            // Skip computed properties (getter or explicit get/set)
            if let accessorBlock = binding.accessorBlock {
                switch accessorBlock.accessors {
                case .getter:
                    continue
                case .accessors(let accessors):
                    let isComputed = accessors.contains {
                        $0.accessorSpecifier.tokenKind == .keyword(.get)
                            || $0.accessorSpecifier.tokenKind == .keyword(.set)
                    }
                    if isComputed { continue }
                // willSet/didSet = still a stored property
                }
            }

            props.insert(identPattern.identifier.text)
        }
        return props
    }

    // MARK: - Equatable function detection

    private static func isEquatableOperator(_ funcDecl: FunctionDeclSyntax) -> Bool {
        guard funcDecl.name.tokenKind == .binaryOperator("=="),
            funcDecl.modifiers.contains(anyOf: [.static])
        else { return false }

        let params = funcDecl.signature.parameterClause.parameters
        guard params.count == 2 else { return false }

        let paramArray = Array(params)
        // Internal labels must be lhs/rhs
        let lhsLabel = paramArray[0].secondName?.text ?? paramArray[0].firstName.text
        let rhsLabel = paramArray[1].secondName?.text ?? paramArray[1].firstName.text
        guard lhsLabel == "lhs", rhsLabel == "rhs" else { return false }

        // Both parameters must have the same type
        guard paramArray[0].type.trimmedDescription == paramArray[1].type.trimmedDescription
        else { return false }

        return true
    }

    // MARK: - Parse compared properties

    private static func parseComparedProperties(
        from funcDecl: FunctionDeclSyntax
    ) -> Set<String>? {
        guard let body = funcDecl.body,
            let onlyItem = body.statements.firstAndOnly
        else { return nil }

        let expr: ExprSyntax
        if let returnStmt = onlyItem.item.as(ReturnStmtSyntax.self),
            let returnExpr = returnStmt.expression
        {
            expr = returnExpr
        } else if let exprStmt = onlyItem.item.as(ExpressionStmtSyntax.self) {
            expr = exprStmt.expression
        } else if let directExpr = onlyItem.item.as(ExprSyntax.self) {
            expr = directExpr
        } else {
            return nil
        }

        var props = Set<String>()
        guard parseComparisons(expr, into: &props) else { return nil }
        return props
    }

    private static func parseComparisons(
        _ expr: ExprSyntax,
        into props: inout Set<String>
    ) -> Bool {
        guard let infixExpr = expr.as(InfixOperatorExprSyntax.self),
            let binOp = infixExpr.operator.as(BinaryOperatorExprSyntax.self)
        else { return false }

        // lhs.prop == rhs.prop
        if binOp.operator.text == "==" {
            guard let lhsAccess = infixExpr.leftOperand.as(MemberAccessExprSyntax.self),
                let lhsBase = lhsAccess.base?.as(DeclReferenceExprSyntax.self),
                let rhsAccess = infixExpr.rightOperand.as(MemberAccessExprSyntax.self),
                let rhsBase = rhsAccess.base?.as(DeclReferenceExprSyntax.self)
            else { return false }

            let lhsName = lhsBase.baseName.text
            let rhsName = rhsBase.baseName.text
            guard
                (lhsName == "lhs" && rhsName == "rhs")
                    || (lhsName == "rhs" && rhsName == "lhs")
            else { return false }

            let lhsProp = lhsAccess.declName.baseName.text
            let rhsProp = rhsAccess.declName.baseName.text
            guard lhsProp == rhsProp else { return false }

            props.insert(lhsProp)
            return true
        }

        // expr1 && expr2
        if binOp.operator.text == "&&" {
            return parseComparisons(infixExpr.leftOperand, into: &props)
                && parseComparisons(infixExpr.rightOperand, into: &props)
        }

        return false
    }

    // MARK: - Member removal

    private static func removeItem(
        at targetIndex: Int,
        from members: MemberBlockItemListSyntax
    ) -> MemberBlockItemListSyntax {
        var newItems = [MemberBlockItemSyntax]()
        for (i, member) in members.enumerated() {
            if i == targetIndex { continue }
            newItems.append(member)
        }
        return MemberBlockItemListSyntax(newItems)
    }
}

extension Finding.Message {
    fileprivate static let removeRedundantEquatable: Finding.Message =
        "remove hand-written '==' operator; compiler-synthesized Equatable conformance is equivalent"
}
