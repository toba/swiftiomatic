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
/// Format: The conformance constraint is moved from the `where` clause to the generic parameter.
final class SimplifyGenericConstraints: RewriteSyntaxRule {

  override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
    let visited = super.visit(node).cast(FunctionDeclSyntax.self)
    var result = simplifyConstraints(
      visited,
      genericParamsKeyPath: \.genericParameterClause,
      whereClauseKeyPath: \.genericWhereClause
    )
    // When the where clause is fully removed and there's no body (protocol methods),
    // strip the trailing space that preceded the where keyword
    if visited.genericWhereClause != nil && result.genericWhereClause == nil && result.body == nil {
      result.signature.trailingTrivia = []
    }
    return DeclSyntax(result)
  }

  override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
    let visited = super.visit(node).cast(StructDeclSyntax.self)
    return DeclSyntax(simplifyConstraints(
      visited,
      genericParamsKeyPath: \.genericParameterClause,
      whereClauseKeyPath: \.genericWhereClause
    ))
  }

  override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
    let visited = super.visit(node).cast(ClassDeclSyntax.self)
    return DeclSyntax(simplifyConstraints(
      visited,
      genericParamsKeyPath: \.genericParameterClause,
      whereClauseKeyPath: \.genericWhereClause
    ))
  }

  override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
    let visited = super.visit(node).cast(EnumDeclSyntax.self)
    return DeclSyntax(simplifyConstraints(
      visited,
      genericParamsKeyPath: \.genericParameterClause,
      whereClauseKeyPath: \.genericWhereClause
    ))
  }

  override func visit(_ node: ActorDeclSyntax) -> DeclSyntax {
    let visited = super.visit(node).cast(ActorDeclSyntax.self)
    return DeclSyntax(simplifyConstraints(
      visited,
      genericParamsKeyPath: \.genericParameterClause,
      whereClauseKeyPath: \.genericWhereClause
    ))
  }

  private func simplifyConstraints<D>(
    _ decl: D,
    genericParamsKeyPath: WritableKeyPath<D, GenericParameterClauseSyntax?>,
    whereClauseKeyPath: WritableKeyPath<D, GenericWhereClauseSyntax?>
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

      diagnose(.simplifyGenericConstraint(param: leftIdent.name.text), on: conformance)
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
        var r = req
        if i == 0 {
          // Strip leading trivia — the where keyword provides the space
          r.leadingTrivia = []
        }
        if i == remainingRequirements.count - 1 {
          r.trailingComma = nil
          // Preserve the trailing trivia from the original where clause (e.g. space before `{`)
          r.trailingTrivia = whereClause.trailingTrivia
        }
        newReqs.append(r)
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
