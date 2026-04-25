import SwiftSyntax

/// Use opaque generic parameters (`some Protocol`) instead of named generic parameters
/// with constraints (`<T: Protocol>`) where equivalent.
///
/// This rule applies to `func`, `init`, and `subscript` declarations. A generic type parameter
/// is eligible for conversion when it appears exactly once in the parameter list and is not
/// referenced in the return type, function body, attributes, typed throws, or other generic
/// constraints.
///
/// Lint: A lint warning is raised when a generic parameter can be replaced with an opaque parameter.
///
/// Format: The generic parameter is replaced with `some Protocol` in the parameter type.
final class OpaqueGenericParameters: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .generics }

  override class var defaultValue: BasicRuleValue { BasicRuleValue(rewrite: false, lint: .no) }

  // MARK: - Visitors

  override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
    let visited = super.visit(node).cast(FunctionDeclSyntax.self)
    guard let genericClause = visited.genericParameterClause else { return DeclSyntax(visited) }

    let analysis = analyzeGenericParams(
      genericClause: genericClause,
      whereClause: visited.genericWhereClause,
      parameterClause: visited.signature.parameterClause,
      returnClause: visited.signature.returnClause,
      body: visited.body.map { Syntax($0) },
      effectSpecifiers: visited.signature.effectSpecifiers,
      preamble: preambleSyntax(attributes: visited.attributes, modifiers: visited.modifiers)
    )

    let eligible = analysis.filter(\.eligible)
    guard !eligible.isEmpty else { return DeclSyntax(visited) }

    diagnose(.useOpaqueGenericParameters, on: node.funcKeyword)

    var result = visited
    result.signature.parameterClause = applyReplacements(
      eligible, to: visited.signature.parameterClause
    )
    result.genericParameterClause = rebuildGenericClause(
      genericClause, removing: Set(eligible.map(\.paramIndex))
    )
    result.genericWhereClause = rebuildWhereClause(
      visited.genericWhereClause,
      removing: Set(eligible.flatMap(\.whereRequirementIndices))
    )

    // Clean up trivia when where clause removed: ensure single space before body
    if result.genericWhereClause == nil, visited.genericWhereClause != nil {
      if var body = result.body {
        body.leftBrace.leadingTrivia = .space
        result.body = body
      }
      // Trim trailing space from what's now before the body to avoid double space
      if let returnClause = result.signature.returnClause {
        result.signature.returnClause = returnClause.with(
          \.type, returnClause.type.with(\.trailingTrivia, [])
        )
      } else {
        result.signature.parameterClause.rightParen =
          result.signature.parameterClause.rightParen.with(\.trailingTrivia, [])
      }
    }

    return DeclSyntax(result)
  }

  override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
    let visited = super.visit(node).cast(InitializerDeclSyntax.self)
    guard let genericClause = visited.genericParameterClause else { return DeclSyntax(visited) }

    let analysis = analyzeGenericParams(
      genericClause: genericClause,
      whereClause: visited.genericWhereClause,
      parameterClause: visited.signature.parameterClause,
      returnClause: nil,
      body: visited.body.map { Syntax($0) },
      effectSpecifiers: visited.signature.effectSpecifiers,
      preamble: preambleSyntax(attributes: visited.attributes, modifiers: visited.modifiers)
    )

    let eligible = analysis.filter(\.eligible)
    guard !eligible.isEmpty else { return DeclSyntax(visited) }

    diagnose(.useOpaqueGenericParameters, on: node.initKeyword)

    var result = visited
    result.signature.parameterClause = applyReplacements(
      eligible, to: visited.signature.parameterClause
    )
    result.genericParameterClause = rebuildGenericClause(
      genericClause, removing: Set(eligible.map(\.paramIndex))
    )
    result.genericWhereClause = rebuildWhereClause(
      visited.genericWhereClause,
      removing: Set(eligible.flatMap(\.whereRequirementIndices))
    )

    // Clean up trivia when where clause removed: ensure single space before body
    if result.genericWhereClause == nil, visited.genericWhereClause != nil {
      if var body = result.body {
        body.leftBrace.leadingTrivia = .space
        result.body = body
      }
      // Trim trailing space from what's now before the body to avoid double space
      if let returnClause = result.signature.returnClause {
        result.signature.returnClause = returnClause.with(
          \.type, returnClause.type.with(\.trailingTrivia, [])
        )
      } else {
        result.signature.parameterClause.rightParen =
          result.signature.parameterClause.rightParen.with(\.trailingTrivia, [])
      }
    }

    return DeclSyntax(result)
  }

  override func visit(_ node: SubscriptDeclSyntax) -> DeclSyntax {
    let visited = super.visit(node).cast(SubscriptDeclSyntax.self)
    guard let genericClause = visited.genericParameterClause else { return DeclSyntax(visited) }

    let analysis = analyzeGenericParams(
      genericClause: genericClause,
      whereClause: visited.genericWhereClause,
      parameterClause: visited.parameterClause,
      returnClause: visited.returnClause,
      body: visited.accessorBlock.map { Syntax($0) },
      effectSpecifiers: nil,
      preamble: preambleSyntax(attributes: visited.attributes, modifiers: visited.modifiers)
    )

    let eligible = analysis.filter(\.eligible)
    guard !eligible.isEmpty else { return DeclSyntax(visited) }

    diagnose(.useOpaqueGenericParameters, on: node.subscriptKeyword)

    var result = visited
    result.parameterClause = applyReplacements(eligible, to: visited.parameterClause)
    result.genericParameterClause = rebuildGenericClause(
      genericClause, removing: Set(eligible.map(\.paramIndex))
    )
    result.genericWhereClause = rebuildWhereClause(
      visited.genericWhereClause,
      removing: Set(eligible.flatMap(\.whereRequirementIndices))
    )

    return DeclSyntax(result)
  }

  // MARK: - Analysis

  private struct TypeInfo {
    let name: String
    let paramIndex: Int
    var conformances: [TypeSyntax] = []
    var sameTypeTarget: TypeSyntax? = nil
    var whereRequirementIndices: [Int] = []
    var eligible: Bool = true

    func replacementType() -> TypeSyntax? {
      if let target = sameTypeTarget {
        return target.trimmed
      }
      if conformances.isEmpty {
        return someType(IdentifierTypeSyntax(name: .identifier("Any")))
      }
      if conformances.count == 1 {
        return someType(conformances[0].trimmed)
      }
      let elements = conformances.enumerated().map { i, c -> CompositionTypeElementSyntax in
        var element = CompositionTypeElementSyntax(type: c.trimmed)
        if i < conformances.count - 1 {
          element.ampersand = .binaryOperator(
            "&", leadingTrivia: .space, trailingTrivia: .space
          )
        }
        return element
      }
      return someType(CompositionTypeSyntax(elements: CompositionTypeElementListSyntax(elements)))
    }

    private func someType(_ constraint: some TypeSyntaxProtocol) -> TypeSyntax {
      TypeSyntax(SomeOrAnyTypeSyntax(
        someOrAnySpecifier: .keyword(.some, trailingTrivia: .space),
        constraint: TypeSyntax(constraint)
      ))
    }
  }

  private func analyzeGenericParams(
    genericClause: GenericParameterClauseSyntax,
    whereClause: GenericWhereClauseSyntax?,
    parameterClause: FunctionParameterClauseSyntax,
    returnClause: ReturnClauseSyntax?,
    body: Syntax?,
    effectSpecifiers: FunctionEffectSpecifiersSyntax?,
    preamble: [Syntax]
  ) -> [TypeInfo] {
    // Collect generic type info from <...>
    var types = [TypeInfo]()
    for (index, param) in genericClause.parameters.enumerated() {
      var info = TypeInfo(name: param.name.text, paramIndex: index)
      if let inherited = param.inheritedType {
        info.conformances.append(inherited)
      }
      types.append(info)
    }

    let typeNames = Set(types.map(\.name))

    // Collect constraints from where clause
    if let whereClause {
      for (reqIndex, requirement) in whereClause.requirements.enumerated() {
        switch requirement.requirement {
        case .conformanceRequirement(let conf):
          let leftName = conf.leftType.trimmedDescription
          if let i = types.firstIndex(where: { $0.name == leftName }) {
            types[i].conformances.append(conf.rightType)
            types[i].whereRequirementIndices.append(reqIndex)
          }

        case .sameTypeRequirement(let same):
          let leftName = same.leftType.trimmedDescription
          if let i = types.firstIndex(where: { $0.name == leftName }) {
            if case .type(let rightType) = same.rightType {
              // Check if same type to `any Protocol` → replace with `any Protocol`
              if let someOrAny = rightType.as(SomeOrAnyTypeSyntax.self),
                 someOrAny.someOrAnySpecifier.tokenKind == .keyword(.any) {
                types[i].sameTypeTarget = rightType
              } else {
                types[i].sameTypeTarget = rightType
              }
              types[i].whereRequirementIndices.append(reqIndex)
            }
          }
          // T == OtherGenericType: make both ineligible if other is also generic
          if case .type(let rightType) = same.rightType,
             let rightIdent = rightType.as(IdentifierTypeSyntax.self),
             typeNames.contains(rightIdent.name.text) {
            // The left type gets replaced with the right type's name
            // But only if the left is a simple generic name
            if let i = types.firstIndex(where: { $0.name == leftName }),
               types[i].sameTypeTarget != nil {
              // Already handled above
            }
          }

        default:
          break
        }
      }
    }

    // Check eligibility for each type
    for i in types.indices {
      let name = types[i].name

      // Must appear exactly once in parameter types
      let countInParams = countOccurrences(of: name, in: Syntax(parameterClause))
      if countInParams != 1 {
        types[i].eligible = false
        continue
      }

      // Must not appear in return type
      if let returnClause, contains(name: name, in: Syntax(returnClause)) {
        types[i].eligible = false
        continue
      }

      // Must not appear in body
      if let body, contains(name: name, in: body) {
        types[i].eligible = false
        continue
      }

      // Must not appear in effect specifiers (typed throws)
      if let effectSpecifiers, contains(name: name, in: Syntax(effectSpecifiers)) {
        types[i].eligible = false
        continue
      }

      // Must not appear in attributes/modifiers
      for node in preamble {
        if contains(name: name, in: node) {
          types[i].eligible = false
          break
        }
      }
      guard types[i].eligible else { continue }

      // Must not appear in any where clause requirement that isn't a direct
      // conformance/equality for this type. This covers:
      // - T used in another type's constraint (e.g., Success == Result<T, Failure>)
      // - T.AssociatedType constraints (e.g., T.Element: Foo)
      // - Self-referential constraints (e.g., T: RoutingBehaviors<T.Dependencies>)
      if let whereClause {
        for (reqIndex, requirement) in whereClause.requirements.enumerated() {
          // Skip requirements already assigned to this type
          if types[i].whereRequirementIndices.contains(reqIndex) { continue }
          // If any unassigned requirement references this type's name, ineligible
          if contains(name: name, in: Syntax(requirement)) {
            types[i].eligible = false
            break
          }
        }
      }
      guard types[i].eligible else { continue }

      // Self-referential constraint (e.g., T: RoutingBehaviors<T.Dependencies>)
      for conformance in types[i].conformances {
        if contains(name: name, in: Syntax(conformance)) {
          types[i].eligible = false
          break
        }
      }
      guard types[i].eligible else { continue }

      // Check for variadic usage in parameters
      for param in parameterClause.parameters {
        if param.ellipsis != nil, contains(name: name, in: Syntax(param.type)) {
          types[i].eligible = false
          break
        }
      }
      guard types[i].eligible else { continue }

      // Check for closure parameter usage
      for param in parameterClause.parameters {
        if isClosureType(param.type), contains(name: name, in: Syntax(param.type)) {
          types[i].eligible = false
          break
        }
      }
      guard types[i].eligible else { continue }

      // Check for `any` existential usage in parameters
      for param in parameterClause.parameters {
        if containsAnyExistential(name: name, in: param.type) {
          types[i].eligible = false
          break
        }
      }
      guard types[i].eligible else { continue }

      // Must be able to produce a replacement type
      if types[i].replacementType() == nil {
        types[i].eligible = false
      }
    }

    return types
  }

  // MARK: - Helpers

  private func countOccurrences(of name: String, in node: Syntax) -> Int {
    node.tokens(viewMode: .sourceAccurate)
      .filter { $0.tokenKind == .identifier(name) }
      .count
  }

  private func contains(name: String, in node: Syntax) -> Bool {
    node.tokens(viewMode: .sourceAccurate)
      .contains { $0.tokenKind == .identifier(name) }
  }

  private func isClosureType(_ type: TypeSyntax) -> Bool {
    if type.is(FunctionTypeSyntax.self) { return true }
    if let attributed = type.as(AttributedTypeSyntax.self) {
      return isClosureType(attributed.baseType)
    }
    if let tuple = type.as(TupleTypeSyntax.self),
       let only = tuple.elements.firstAndOnly {
      return isClosureType(only.type)
    }
    return false
  }

  private func containsAnyExistential(name: String, in type: TypeSyntax) -> Bool {
    if let someOrAny = type.as(SomeOrAnyTypeSyntax.self),
       someOrAny.someOrAnySpecifier.tokenKind == .keyword(.any),
       contains(name: name, in: Syntax(someOrAny.constraint)) {
      return true
    }
    // Recurse into children
    for child in type.children(viewMode: .sourceAccurate) {
      if let childType = child.as(TypeSyntax.self) {
        if containsAnyExistential(name: name, in: childType) { return true }
      }
    }
    return false
  }

  private func preambleSyntax(
    attributes: AttributeListSyntax,
    modifiers: DeclModifierListSyntax
  ) -> [Syntax] {
    var result = [Syntax]()
    for attr in attributes { result.append(Syntax(attr)) }
    for mod in modifiers { result.append(Syntax(mod)) }
    return result
  }

  // MARK: - Rewriting

  private func applyReplacements(
    _ eligible: [TypeInfo],
    to parameterClause: FunctionParameterClauseSyntax
  ) -> FunctionParameterClauseSyntax {
    var result = parameterClause
    let newParams = result.parameters.map { param -> FunctionParameterSyntax in
      for info in eligible {
        guard let replacement = info.replacementType() else { continue }
        if let newType = replaceGenericInType(param.type, name: info.name, with: replacement) {
          var newParam = param
          newParam.type = newType
          return newParam
        }
      }
      return param
    }
    result.parameters = FunctionParameterListSyntax(newParams)
    return result
  }

  private func replaceGenericInType(
    _ type: TypeSyntax, name: String, with replacement: TypeSyntax
  ) -> TypeSyntax? {
    // Direct: T → replacement
    if let ident = type.as(IdentifierTypeSyntax.self),
       ident.name.text == name,
       ident.genericArgumentClause == nil {
      var result = replacement
      result.leadingTrivia = type.leadingTrivia
      result.trailingTrivia = type.trailingTrivia
      return result
    }

    // Optional: T? → (replacement)?
    if let optional = type.as(OptionalTypeSyntax.self),
       let inner = optional.wrappedType.as(IdentifierTypeSyntax.self),
       inner.name.text == name {
      return TypeSyntax(optional.with(
        \.wrappedType, wrapInParens(replacement, leadingTrivia: type.leadingTrivia)
      ))
    }

    // Metatype: T.Type → (replacement).Type
    if let metatype = type.as(MetatypeTypeSyntax.self),
       let inner = metatype.baseType.as(IdentifierTypeSyntax.self),
       inner.name.text == name {
      return TypeSyntax(metatype.with(
        \.baseType, wrapInParens(replacement, leadingTrivia: type.leadingTrivia)
      ))
    }

    return nil
  }

  private func wrapInParens(_ type: TypeSyntax, leadingTrivia: Trivia) -> TypeSyntax {
    TypeSyntax(TupleTypeSyntax(
      leftParen: .leftParenToken(leadingTrivia: leadingTrivia),
      elements: TupleTypeElementListSyntax([TupleTypeElementSyntax(type: type)]),
      rightParen: .rightParenToken()
    ))
  }

  private func rebuildGenericClause(
    _ clause: GenericParameterClauseSyntax,
    removing indices: Set<Int>
  ) -> GenericParameterClauseSyntax? {
    let remaining = clause.parameters.enumerated()
      .filter { !indices.contains($0.offset) }
      .map(\.element)

    if remaining.isEmpty { return nil }

    // Rebuild with proper commas
    let newParams = remaining.enumerated().map { i, param -> GenericParameterSyntax in
      var modified = param
      if i < remaining.count - 1 {
        modified.trailingComma = .commaToken(trailingTrivia: .space)
      } else {
        modified.trailingComma = nil
      }
      // Strip leading trivia from non-first params to avoid extra whitespace
      if i == 0 {
        modified.leadingTrivia = []
      } else {
        modified.leadingTrivia = []
      }
      return modified
    }

    var result = clause
    result.parameters = GenericParameterListSyntax(newParams)
    return result
  }

  private func rebuildWhereClause(
    _ clause: GenericWhereClauseSyntax?,
    removing indices: Set<Int>
  ) -> GenericWhereClauseSyntax? {
    guard let clause, !indices.isEmpty else { return clause }

    let remaining = clause.requirements.enumerated()
      .filter { !indices.contains($0.offset) }
      .map(\.element)

    if remaining.isEmpty { return nil }

    let newReqs = remaining.enumerated().map { i, req -> GenericRequirementSyntax in
      var modified = req
      if i < remaining.count - 1 {
        modified.trailingComma = .commaToken(trailingTrivia: .space)
      } else {
        modified.trailingComma = nil
      }
      if i == 0 {
        modified.leadingTrivia = []
      }
      return modified
    }

    var result = clause
    result.requirements = GenericRequirementListSyntax(newReqs)
    return result
  }

}

extension Finding.Message {
  fileprivate static let useOpaqueGenericParameters: Finding.Message =
    "use 'some' opaque parameter instead of named generic parameter"
}
