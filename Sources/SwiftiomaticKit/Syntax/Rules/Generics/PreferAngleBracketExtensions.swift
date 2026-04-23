import SwiftSyntax

/// Use angle brackets (`extension Array<Foo>`) for generic type extensions instead of
/// type constraints (`extension Array where Element == Foo`).
///
/// Swift 5.7+ supports angle bracket syntax in extension declarations. When a `where`
/// clause constrains all generic parameters of a known type to concrete types,
/// the angle bracket form is more concise.
///
/// Known types: `Array`, `Set`, `Optional`, `Dictionary`, `Collection`, `Sequence`.
///
/// Lint: An extension with a `where` clause that can be replaced by angle brackets raises a warning.
///
/// Format: The `where` clause constraints are moved into angle bracket syntax on the
/// extended type.
final class PreferAngleBracketExtensions: RewriteSyntaxRule<BasicRuleValue> {
    override class var group: ConfigurationGroup? { .generics }

  /// Maps known generic types to their associated type names (in parameter order).
  private static let knownGenericTypes: [String: [String]] = [
    "Array": ["Element"],
    "Set": ["Element"],
    "Collection": ["Element"],
    "Sequence": ["Element"],
    "Optional": ["Wrapped"],
    "Dictionary": ["Key", "Value"],
  ]

  override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
    let visited = super.visit(node).cast(ExtensionDeclSyntax.self)

    // Must have a where clause
    guard let whereClause = visited.genericWhereClause else {
      return DeclSyntax(visited)
    }

    // Extended type must be a simple identifier (no angle brackets already)
    guard let extendedIdent = visited.extendedType.as(IdentifierTypeSyntax.self),
      extendedIdent.genericArgumentClause == nil
    else {
      return DeclSyntax(visited)
    }

    let typeName = extendedIdent.name.text

    // Must be a known generic type
    guard let requiredParams = Self.knownGenericTypes[typeName] else {
      return DeclSyntax(visited)
    }

    // Collect same-type constraints for required params
    var paramTypes: [String: TypeSyntax] = [:]
    var consumedIndices: Set<Int> = []

    for (index, requirement) in whereClause.requirements.enumerated() {
      guard let sameType = requirement.requirement.as(SameTypeRequirementSyntax.self),
        let leftIdent = sameType.leftType.as(IdentifierTypeSyntax.self)
      else {
        continue
      }
      if requiredParams.contains(leftIdent.name.text),
        case .type(let rightType) = sameType.rightType
      {
        paramTypes[leftIdent.name.text] = rightType
        consumedIndices.insert(index)
      }
    }

    // All required params must be constrained
    guard paramTypes.count == requiredParams.count else {
      return DeclSyntax(visited)
    }

    diagnose(.useAngleBracketSyntax(type: typeName), on: whereClause.whereKeyword)

    // Build generic argument clause: <Foo> or <String, Int>
    let genericArgs = requiredParams.enumerated().map { (i, param) -> GenericArgumentSyntax in
      let argType = paramTypes[param]!
      let isLast = i == requiredParams.count - 1
      return GenericArgumentSyntax(
        argument: .type(argType.with(\.leadingTrivia, []).with(\.trailingTrivia, [])),
        trailingComma: isLast
          ? nil : TokenSyntax(.comma, trailingTrivia: .space, presence: .present)
      )
    }

    let genericArgClause = GenericArgumentClauseSyntax(
      leftAngle: .leftAngleToken(),
      arguments: GenericArgumentListSyntax(genericArgs),
      rightAngle: .rightAngleToken()
    )

    // Strip trailing trivia from type name (no space before `<`)
    let newExtendedType = extendedIdent
      .with(\.name, extendedIdent.name.with(\.trailingTrivia, []))
      .with(\.genericArgumentClause, genericArgClause)

    var result = visited.with(\.extendedType, TypeSyntax(newExtendedType))

    // Handle remaining where clause constraints
    let remainingRequirements = whereClause.requirements.enumerated()
      .filter { !consumedIndices.contains($0.offset) }
      .map(\.element)

    if remainingRequirements.isEmpty {
      // Remove the entire where clause; add space before {
      result.genericWhereClause = nil
      result.extendedType.trailingTrivia = .space
    } else {
      // Rebuild where clause with remaining requirements and correct commas
      var newReqs = [GenericRequirementSyntax]()
      for (i, req) in remainingRequirements.enumerated() {
        var r = req
        if i == 0 {
          // Strip leading trivia — the where keyword provides the space
          r.leadingTrivia = []
        }
        if i == remainingRequirements.count - 1 {
          r.trailingComma = nil
        }
        newReqs.append(r)
      }
      result.genericWhereClause = whereClause.with(
        \.requirements, GenericRequirementListSyntax(newReqs))
      result.extendedType.trailingTrivia = .space
    }

    return DeclSyntax(result)
  }
}

extension Finding.Message {
  fileprivate static func useAngleBracketSyntax(type: String) -> Finding.Message {
    "use angle bracket syntax for '\(type)' extension instead of 'where' clause"
  }
}
