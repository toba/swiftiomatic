import SwiftSyntax

/// Use inline generic constraints (`<T: Foo>`) instead of where clauses
/// (`<T> where T: Foo`) for simple protocol conformance constraints.
///
/// When a generic parameter has a simple conformance constraint in the `where` clause,
/// it can be moved inline into the generic parameter list for conciseness.
///
/// Same-type constraints (`T == Foo`), associated type constraints (`T.Element: Foo`),
/// and parameters that already have an inline constraint are not modified.
///
/// Lint: A `where` clause with a simple conformance constraint that could be inlined raises a warning.
///
/// Rewrite: The conformance constraint is moved from the `where` clause to the generic parameter.
final class SimplifyGenericConstraints: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .generics }

    static func transform(
        _ visited: FunctionDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        var result = simplifyConstraints(
            visited,
            genericParamsKeyPath: \.genericParameterClause,
            whereClauseKeyPath: \.genericWhereClause,
            context: context
        )
        // When the where clause is fully removed and there's no body (protocol methods),
        // strip the trailing space that preceded the where keyword
        if visited.genericWhereClause != nil && result.genericWhereClause == nil
            && result.body == nil
        {
            result.signature.trailingTrivia = []
        }
        return DeclSyntax(result)
    }

    static func transform(
        _ visited: StructDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(simplifyConstraints(
            visited,
            genericParamsKeyPath: \.genericParameterClause,
            whereClauseKeyPath: \.genericWhereClause,
            context: context
        ))
    }

    static func transform(
        _ visited: ClassDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(simplifyConstraints(
            visited,
            genericParamsKeyPath: \.genericParameterClause,
            whereClauseKeyPath: \.genericWhereClause,
            context: context
        ))
    }

    static func transform(
        _ visited: EnumDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(simplifyConstraints(
            visited,
            genericParamsKeyPath: \.genericParameterClause,
            whereClauseKeyPath: \.genericWhereClause,
            context: context
        ))
    }

    static func transform(
        _ visited: ActorDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(simplifyConstraints(
            visited,
            genericParamsKeyPath: \.genericParameterClause,
            whereClauseKeyPath: \.genericWhereClause,
            context: context
        ))
    }

    private static func simplifyConstraints<D>(
        _ decl: D,
        genericParamsKeyPath: WritableKeyPath<D, GenericParameterClauseSyntax?>,
        whereClauseKeyPath: WritableKeyPath<D, GenericWhereClauseSyntax?>,
        context: Context
    ) -> D {
        guard var genericParams = decl[keyPath: genericParamsKeyPath],
            let whereClause = decl[keyPath: whereClauseKeyPath]
        else {
            return decl
        }

        // Collect generic param names and check which have existing constraints
        let paramNames = Set(genericParams.parameters.map { $0.name.text })
        let paramsWithInheritance = Set(
            genericParams.parameters
                .filter { $0.inheritedType != nil }
                .map { $0.name.text }
        )

        // Identify constraints to inline
        var consumedIndices: Set<Int> = []
        var inlineMap: [String: TypeSyntax] = [:]

        for (index, requirement) in whereClause.requirements.enumerated() {
            guard let conformance = requirement.requirement.as(ConformanceRequirementSyntax.self),
                let leftIdent = conformance.leftType.as(IdentifierTypeSyntax.self),
                paramNames.contains(leftIdent.name.text)
            else {
                continue
            }

            // Skip if param already has an inline constraint or we already have one queued
            guard !paramsWithInheritance.contains(leftIdent.name.text),
                inlineMap[leftIdent.name.text] == nil
            else {
                continue
            }

            inlineMap[leftIdent.name.text] = conformance.rightType
            consumedIndices.insert(index)

            Self.diagnose(
                .simplifyGenericConstraint(param: leftIdent.name.text),
                on: conformance,
                context: context
            )
        }

        guard !inlineMap.isEmpty else { return decl }

        // Modify generic parameters: add inline constraints
        var newParams = Array(genericParams.parameters)
        for i in newParams.indices {
            guard let constraintType = inlineMap[newParams[i].name.text] else { continue }
            newParams[i].colon = .colonToken(trailingTrivia: .space)
            newParams[i].inheritedType = constraintType
                .with(\.leadingTrivia, [])
                .with(\.trailingTrivia, [])
        }
        genericParams.parameters = GenericParameterListSyntax(newParams)

        var result = decl
        result[keyPath: genericParamsKeyPath] = genericParams

        // Handle remaining where clause
        let remainingRequirements = whereClause.requirements.enumerated()
            .filter { !consumedIndices.contains($0.offset) }
            .map(\.element)

        if remainingRequirements.isEmpty {
            result[keyPath: whereClauseKeyPath] = nil
        } else {
            var newReqs = [GenericRequirementSyntax]()
            for (i, req) in remainingRequirements.enumerated() {
                var modified = req
                if i == 0 {
                    // Strip leading trivia — the where keyword provides the space
                    modified.leadingTrivia = []
                }
                if i == remainingRequirements.count - 1 {
                    modified.trailingComma = nil
                    // Preserve the trailing trivia from the original where clause (e.g. space before `{`)
                    modified.trailingTrivia = whereClause.trailingTrivia
                }
                newReqs.append(modified)
            }
            result[keyPath: whereClauseKeyPath] = whereClause.with(
                \.requirements, GenericRequirementListSyntax(newReqs))
        }

        return result
    }
}

extension Finding.Message {
    fileprivate static func simplifyGenericConstraint(param: String) -> Finding.Message {
        "constraint on '\(param)' can be simplified to an inline constraint"
    }
}
