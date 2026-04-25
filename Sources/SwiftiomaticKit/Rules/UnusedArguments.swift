import SwiftSyntax

/// Mark unused function arguments with `_`.
///
/// Detects unused parameters in functions, initializers, subscripts, closures,
/// and for-loop variables, and replaces them with `_`.
///
/// For named function parameters, the internal name is replaced with `_`
/// (e.g., `func foo(bar: Int)` → `func foo(bar _: Int)`). For unnamed
/// parameters, the name is removed (`func foo(_ bar: Int)` → `func foo(_: Int)`).
///
/// For operator functions and subscripts, the parameter name is replaced
/// with `_` directly since external labels are unnecessary.
///
/// Lint: When a parameter or loop variable is unused.
///
/// Format: The unused parameter or variable is replaced with `_`.
final class UnusedArguments: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {

    // MARK: - Functions

    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        let visited = super.visit(node)
        guard var result = visited.as(FunctionDeclSyntax.self) else { return visited }
        guard let body = result.body else { return visited }

        let isOperator: Bool

        switch node.name.tokenKind {
            case .binaryOperator, .prefixOperator, .postfixOperator:
                isOperator = true
            default:
                isOperator = false
        }

        var params = Array(result.signature.parameterClause.parameters)
        var changed = false

        for (i, param) in params.enumerated() {
            guard let name = internalName(of: param), name != "_" else { continue }
            guard !isNameUsed(name, in: body) else { continue }

            let nameToken = param.secondName ?? param.firstName
            diagnose(.unusedArgument(name), on: nameToken)
            params[i] = markUnused(param, isOperator: isOperator)
            changed = true
        }

        guard changed else { return visited }
        result.signature.parameterClause.parameters = FunctionParameterListSyntax(params)
        return .init(result)
    }

    // MARK: - Initializers

    override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
        let visited = super.visit(node)
        guard var result = visited.as(InitializerDeclSyntax.self) else { return visited }
        guard let body = result.body else { return visited }

        var params = Array(result.signature.parameterClause.parameters)
        var changed = false

        for (i, param) in params.enumerated() {
            guard let name = internalName(of: param), name != "_" else { continue }
            guard !isNameUsed(name, in: body) else { continue }

            let nameToken = param.secondName ?? param.firstName
            diagnose(.unusedArgument(name), on: nameToken)
            params[i] = markUnused(param, isOperator: false)
            changed = true
        }

        guard changed else { return visited }
        result.signature.parameterClause.parameters = FunctionParameterListSyntax(params)
        return .init(result)
    }

    // MARK: - Subscripts

    override func visit(_ node: SubscriptDeclSyntax) -> DeclSyntax {
        let visited = super.visit(node)
        guard var result = visited.as(SubscriptDeclSyntax.self) else { return visited }

        var params = Array(result.parameterClause.parameters)
        var changed = false

        for (i, param) in params.enumerated() {
            guard let name = internalName(of: param), name != "_" else { continue }
            guard !isSubscriptParamUsed(name, in: result) else { continue }

            let nameToken = param.secondName ?? param.firstName
            diagnose(.unusedArgument(name), on: nameToken)
            params[i] = markUnused(param, isOperator: true)
            changed = true
        }

        guard changed else { return visited }
        result.parameterClause.parameters = FunctionParameterListSyntax(params)
        return .init(result)
    }

    // MARK: - Closures

    override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
        let visited = super.visit(node)
        guard var result = visited.as(ClosureExprSyntax.self) else { return visited }
        guard var signature = result.signature,
            let paramClause = signature.parameterClause
        else { return visited }

        switch paramClause {
            case let .simpleInput(params):
                var newParams = Array(params)
                var changed = false

                for (i, param) in params.enumerated() {
                    let name = param.name.text
                    guard name != "_", !name.hasPrefix("$") else { continue }
                    guard !isNameUsed(name, in: result.statements) else { continue }

                    diagnose(.unusedClosureArgument(name), on: param.name)
                    newParams[i] = param.with(
                        \.name,
                        .wildcardToken(
                            leadingTrivia: param.name.leadingTrivia,
                            trailingTrivia: param.name.trailingTrivia))
                    changed = true
                }

                guard changed else { return visited }
                signature.parameterClause = .simpleInput(
                    ClosureShorthandParameterListSyntax(newParams))
                result.signature = signature
                return ExprSyntax(result)

            case var .parameterClause(clause):
                var params = Array(clause.parameters)
                var changed = false

                for (i, param) in params.enumerated() {
                    guard let name = internalClosureName(of: param),
                        name != "_", !name.hasPrefix("$")
                    else { continue }
                    guard !isNameUsed(name, in: result.statements) else { continue }

                    let nameToken = param.secondName ?? param.firstName
                    diagnose(.unusedClosureArgument(name), on: nameToken)
                    params[i] = markClosureUnused(param)
                    changed = true
                }

                guard changed else { return visited }
                clause.parameters = ClosureParameterListSyntax(params)
                signature.parameterClause = .parameterClause(clause)
                result.signature = signature
                return ExprSyntax(result)
        }
    }

    // MARK: - For Loops

    override func visit(_ node: ForStmtSyntax) -> StmtSyntax {
        let visited = super.visit(node)
        guard var result = visited.as(ForStmtSyntax.self) else { return visited }

        // Skip pattern-matching for loops (for case ...)
        guard result.caseKeyword == nil else { return visited }

        let body = result.body.statements
        let whereClause = result.whereClause

        if let identPattern = result.pattern.as(IdentifierPatternSyntax.self) {
            let name = identPattern.identifier.text
            guard name != "_" else { return visited }

            let usedInBody = isNameUsed(name, in: body)
            let usedInWhere = whereClause.map { isNameUsed(name, in: $0) } ?? false
            guard !usedInBody, !usedInWhere else { return visited }

            diagnose(.unusedForLoopVariable(name), on: identPattern.identifier)
            result.pattern = PatternSyntax(
                WildcardPatternSyntax(
                    wildcard: .wildcardToken(
                        leadingTrivia: identPattern.identifier.leadingTrivia,
                        trailingTrivia: identPattern.identifier.trailingTrivia)))
            return StmtSyntax(result)

        } else if let tuplePattern = result.pattern.as(TuplePatternSyntax.self) {
            var elements = Array(tuplePattern.elements)
            var changed = false

            for (i, element) in elements.enumerated() {
                guard let ident = element.pattern.as(IdentifierPatternSyntax.self) else { continue }
                let name = ident.identifier.text
                guard name != "_" else { continue }

                let usedInBody = isNameUsed(name, in: body)
                let usedInWhere = whereClause.map { isNameUsed(name, in: $0) } ?? false
                guard !usedInBody, !usedInWhere else { continue }

                diagnose(.unusedForLoopVariable(name), on: ident.identifier)
                elements[i] = element.with(
                    \.pattern,
                    PatternSyntax(
                        WildcardPatternSyntax(
                            wildcard: .wildcardToken(
                                leadingTrivia: ident.identifier.leadingTrivia,
                                trailingTrivia: ident.identifier.trailingTrivia))))
                changed = true
            }

            guard changed else { return visited }
            result.pattern = PatternSyntax(
                tuplePattern.with(
                    \.elements,
                    TuplePatternElementListSyntax(elements)))
            return StmtSyntax(result)
        }

        return visited
    }

    // MARK: - Usage Detection

    /// Check if `name` is referenced as a variable (not member or label)
    /// anywhere in `syntax`, excluding references shadowed by local declarations.
    private func isNameUsed(_ name: String, in syntax: some SyntaxProtocol) -> Bool {
        let boundaryID = Syntax(syntax).id

        // Check for shorthand optional bindings: `if let foo` is sugar for `if let foo = foo`
        // and counts as a use of the outer `foo`.
        if hasShorthandBinding(name, in: syntax) { return true }

        for token in syntax.tokens(viewMode: .sourceAccurate)
        where matchesIdentifier(token, name: name) {

            // Must be DeclReferenceExprSyntax.baseName
            guard let declRef = token.parent?.as(DeclReferenceExprSyntax.self),
                declRef.baseName.id == token.id
            else { continue }

            // Exclude member access position (foo.bar — bar is not a variable use)
            if let memberAccess = declRef.parent?.as(MemberAccessExprSyntax.self),
                memberAccess.declName.id == declRef.id
            {
                continue
            }

            // Check if shadowed by a local declaration
            if isShadowed(ref: declRef, name: name, boundaryID: boundaryID) { continue }

            return true
        }
        return false
    }

    /// Detect shorthand `if let name` / `guard let name` (no initializer)
    /// which implicitly references the outer variable.
    private func hasShorthandBinding(
        _ name: String, in syntax: some SyntaxProtocol
    ) -> Bool {
        for child in syntax.children(viewMode: .sourceAccurate) {
            if let binding = child.as(OptionalBindingConditionSyntax.self),
                binding.initializer == nil,
                let ident = binding.pattern.as(IdentifierPatternSyntax.self),
                ident.identifier.text == name
            {
                return true
            }
            if hasShorthandBinding(name, in: child) { return true }
        }
        return false
    }

    private func matchesIdentifier(_ token: TokenSyntax, name: String) -> Bool {
        switch token.tokenKind {
            case let .identifier(text):
                if text == name { return true }

                if text.hasPrefix("`"), text.hasSuffix("`"), text.count > 2 {
                    return String(text.dropFirst().dropLast()) == name
                }
                return false
            default:
                return false
        }
    }

    /// Walk up from `ref` toward `boundaryID`, checking for shadowing declarations.
    private func isShadowed(
        ref: DeclReferenceExprSyntax,
        name: String,
        boundaryID: SyntaxIdentifier
    ) -> Bool {
        var current = Syntax(ref)

        while let parent = current.parent {
            if parent.id == boundaryID { return false }

            // Statement list: preceding siblings may declare the name
            if let stmtList = parent.as(CodeBlockItemListSyntax.self) {
                for stmt in stmtList {
                    // Stop at the statement containing our reference
                    if ref.position >= stmt.position, ref.position < stmt.endPosition { break }
                    guard stmt.endPosition <= ref.position else { break }
                    if statementDeclares(name, in: stmt) { return true }
                }
            }

            // Condition list: preceding conditions may bind the name
            if let condList = parent.as(ConditionElementListSyntax.self) {
                for cond in condList {
                    if ref.position >= cond.position, ref.position < cond.endPosition { break }
                    guard cond.endPosition <= ref.position else { break }
                    if conditionBinds(name, in: cond) { return true }
                }
            }

            // Closure parameters shadow the name
            if let closure = parent.as(ClosureExprSyntax.self) {
                if closureBinds(name, in: closure) { return true }
            }

            // For-loop pattern shadows in body and where clause (not sequence)
            if let forStmt = parent.as(ForStmtSyntax.self) {
                let inBody = current.id == Syntax(forStmt.body).id
                let inWhere = forStmt.whereClause.map { current.id == Syntax($0).id } ?? false

                if inBody || inWhere, patternContains(name, in: forStmt.pattern) { return true }
            }

            // If-expression: conditions shadow inside the body
            if let ifExpr = parent.as(IfExprSyntax.self),
                current.id == Syntax(ifExpr.body).id
            {
                for cond in ifExpr.conditions where conditionBinds(name, in: cond) { return true }
            }

            // Switch case pattern binds the name
            if let switchCase = parent.as(SwitchCaseSyntax.self),
                let caseLabel = switchCase.label.as(SwitchCaseLabelSyntax.self)
            {
                for item in caseLabel.caseItems where patternContains(name, in: item.pattern) {
                    return true
                }
            }

            // Nested function parameters shadow in the body
            if let funcDecl = parent.as(FunctionDeclSyntax.self),
                let body = funcDecl.body, current.id == Syntax(body).id
            {
                if funcDecl.signature.parameterClause.parameters.contains(where: {
                    internalName(of: $0) == name
                }) {
                    return true
                }
            }

            // Nested initializer parameters shadow in the body
            if let initDecl = parent.as(InitializerDeclSyntax.self),
                let body = initDecl.body, current.id == Syntax(body).id
            {
                if initDecl.signature.parameterClause.parameters.contains(where: {
                    internalName(of: $0) == name
                }) {
                    return true
                }
            }

            current = parent
        }
        return false
    }

    // MARK: - Shadow Helpers

    private func statementDeclares(_ name: String, in stmt: CodeBlockItemSyntax) -> Bool {
        if let varDecl = stmt.item.as(VariableDeclSyntax.self) {
            for binding in varDecl.bindings where patternContains(name, in: binding.pattern) {
                return true
            }
        }
        // Guard bindings escape into the enclosing scope
        if let guardStmt = stmt.item.as(GuardStmtSyntax.self) {
            for cond in guardStmt.conditions where conditionBinds(name, in: cond) { return true }
        }
        return false
    }

    private func conditionBinds(_ name: String, in cond: ConditionElementSyntax) -> Bool {
        if let binding = cond.condition.as(OptionalBindingConditionSyntax.self) {
            return patternContains(name, in: binding.pattern)
        }
        if let matching = cond.condition.as(MatchingPatternConditionSyntax.self) {
            return patternContains(name, in: matching.pattern)
        }
        return false
    }

    private func patternContains(_ name: String, in pattern: PatternSyntax) -> Bool {
        if let ident = pattern.as(IdentifierPatternSyntax.self) {
            return ident.identifier.text == name
        }
        if let tuple = pattern.as(TuplePatternSyntax.self) {
            return tuple.elements.contains { patternContains(name, in: $0.pattern) }
        }
        if let binding = pattern.as(ValueBindingPatternSyntax.self) {
            return patternContains(name, in: binding.pattern)
        }
        if let expr = pattern.as(ExpressionPatternSyntax.self) {
            return expressionBinds(name, in: expr.expression)
        }
        return false
    }

    private func expressionBinds(_ name: String, in expr: ExprSyntax) -> Bool {
        if let call = expr.as(FunctionCallExprSyntax.self) {
            for arg in call.arguments {
                if let patExpr = arg.expression.as(PatternExprSyntax.self) {
                    if patternContains(name, in: patExpr.pattern) { return true }
                }
                if expressionBinds(name, in: arg.expression) { return true }
            }
        }
        if let patExpr = expr.as(PatternExprSyntax.self) {
            return patternContains(name, in: patExpr.pattern)
        }
        return false
    }

    private func closureBinds(_ name: String, in closure: ClosureExprSyntax) -> Bool {
        if let signature = closure.signature, let paramClause = signature.parameterClause {
            switch paramClause {
                case let .simpleInput(params):
                    params.contains { $0.name.text == name }
                case let .parameterClause(clause):
                    clause.parameters.contains { param in
                        if let secondName = param.secondName {
                            secondName.text == name
                        } else {
                            param.firstName.text != "_" && param.firstName.text == name
                        }
                    }
            }
        } else {
            false
        }
    }

    // MARK: - Parameter Name Extraction

    private func internalName(of param: FunctionParameterSyntax) -> String? {
        if let secondName = param.secondName {
            return secondName.text == "_" ? nil : secondName.text
        }
        return param.firstName.text == "_" ? nil : param.firstName.text
    }

    private func internalClosureName(of param: ClosureParameterSyntax) -> String? {
        if let secondName = param.secondName {
            return secondName.text == "_" ? nil : secondName.text
        }
        return param.firstName.text == "_" ? nil : param.firstName.text
    }

    // MARK: - Parameter Modification

    private func markUnused(
        _ param: FunctionParameterSyntax,
        isOperator: Bool
    ) -> FunctionParameterSyntax {
        var result = param

        if let secondName = param.secondName {
            if param.firstName.text == "_" {
                // `_ name:` → `_:`
                result.firstName = param.firstName.with(
                    \.trailingTrivia, secondName.trailingTrivia)
                result.secondName = nil
            } else {
                // `label name:` → `label _:`
                result.secondName = .wildcardToken(
                    leadingTrivia: secondName.leadingTrivia,
                    trailingTrivia: secondName.trailingTrivia)
            }
        } else if param.firstName.text != "_" {
            if isOperator {
                // Operator/subscript: `name:` → `_:`
                result.firstName = .wildcardToken(
                    leadingTrivia: param.firstName.leadingTrivia,
                    trailingTrivia: param.firstName.trailingTrivia)
            } else {
                // Regular function: `name:` → `name _:`
                result.firstName = param.firstName.with(\.trailingTrivia, [])
                result.secondName = .wildcardToken(
                    leadingTrivia: .space,
                    trailingTrivia: param.firstName.trailingTrivia)
            }
        }

        return result
    }

    private func markClosureUnused(
        _ param: ClosureParameterSyntax
    ) -> ClosureParameterSyntax {
        var result = param

        if let secondName = param.secondName {
            if param.firstName.text == "_" {
                // `_ name:` → `_:`
                result.firstName = param.firstName.with(
                    \.trailingTrivia, secondName.trailingTrivia)
                result.secondName = nil
            } else {
                // `label name:` → `label _:`
                result.secondName = .wildcardToken(
                    leadingTrivia: secondName.leadingTrivia,
                    trailingTrivia: secondName.trailingTrivia)
            }
        } else {
            // `name:` → `_:`
            result.firstName = .wildcardToken(
                leadingTrivia: param.firstName.leadingTrivia,
                trailingTrivia: param.firstName.trailingTrivia)
        }

        return result
    }

    // MARK: - Subscript Helpers

    private func isSubscriptParamUsed(
        _ name: String, in sub: SubscriptDeclSyntax
    ) -> Bool {
        guard let accessorBlock = sub.accessorBlock else { return false }

        switch accessorBlock.accessors {
            case let .getter(stmts):
                return isNameUsed(name, in: stmts)
            case let .accessors(accessors):
                for accessor in accessors {
                    if let body = accessor.body, isNameUsed(name, in: body) { return true }
                }
                return false
        }
    }
}

extension Finding.Message {
    fileprivate static func unusedArgument(_ name: String) -> Finding.Message {
        "parameter '\(name)' is unused"
    }

    fileprivate static func unusedClosureArgument(_ name: String) -> Finding.Message {
        "closure parameter '\(name)' is unused"
    }

    fileprivate static func unusedForLoopVariable(_ name: String) -> Finding.Message {
        "for-loop variable '\(name)' is unused"
    }
}
