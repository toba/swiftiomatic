import SwiftiomaticSyntax

struct GenericExtensionsRule {
  static let id = "generic_extensions"
  static let name = "Generic Extensions"
  static let summary =
    "Use angle bracket syntax for generic type extensions instead of where clauses with `==`"
  static let isOptIn = true
  static var nonTriggeringExamples: [Example] {
    [
      Example("extension Array<Foo> {}"),
      Example("extension Optional<Foo> {}"),
      Example("extension Dictionary<String, Int> {}"),
      Example("extension Array where Element: Equatable {}"),
      Example("extension CustomType where Element == Foo {}"),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example("extension ↓Array where Element == Foo {}"),
      Example("extension ↓Optional where Wrapped == Foo {}"),
      Example("extension ↓Set where Element == Foo {}"),
      Example("extension ↓Collection where Element == Foo {}"),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

private let knownGenericTypes: [String: [String]] = [
  "Array": ["Element"],
  "Set": ["Element"],
  "Optional": ["Wrapped"],
  "Dictionary": ["Key", "Value"],
  "Sequence": ["Element"],
  "Collection": ["Element"],
]

extension GenericExtensionsRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension GenericExtensionsRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: ExtensionDeclSyntax) {
      // Must have a where clause
      guard let whereClause = node.genericWhereClause else { return }

      // Get the extended type name
      guard let typeName = node.extendedType.as(IdentifierTypeSyntax.self)?.name.text else {
        return
      }

      // Must already not use angle brackets
      guard node.extendedType.as(IdentifierTypeSyntax.self)?.genericArgumentClause == nil
      else {
        return
      }

      // Must be a known generic type
      guard let expectedParams = knownGenericTypes[typeName] else { return }

      // Check if all where clause requirements are same-type constraints (==)
      // that match the expected generic parameters
      let requirements = whereClause.requirements
      var matchedParams = Set<String>()

      for requirement in requirements {
        guard let sameType = requirement.requirement.as(SameTypeRequirementSyntax.self)
        else {
          continue
        }

        // The left side should be a simple identifier matching a known parameter
        let leftName: String
        if let memberAccess = sameType.leftType.as(MemberTypeSyntax.self),
          memberAccess.baseType.as(IdentifierTypeSyntax.self)?.name.text == "Self"
        {
          leftName = memberAccess.name.text
        } else if let ident = sameType.leftType.as(IdentifierTypeSyntax.self) {
          leftName = ident.name.text
        } else {
          return
        }

        guard expectedParams.contains(leftName) else { return }
        matchedParams.insert(leftName)
      }

      // All expected params must be provided via == constraints
      guard matchedParams.count == expectedParams.count else { return }

      violations.append(
        SyntaxViolation(
          position: node.extendedType.positionAfterSkippingLeadingTrivia,
          reason:
            "Use 'extension \(typeName)<...>' instead of where clause with same-type constraints",
        ),
      )
    }
  }
}
