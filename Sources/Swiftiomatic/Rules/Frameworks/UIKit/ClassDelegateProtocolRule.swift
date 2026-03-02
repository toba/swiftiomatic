import SwiftSyntax

struct ClassDelegateProtocolRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = ClassDelegateProtocolConfiguration()
}

extension ClassDelegateProtocolRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension ClassDelegateProtocolRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
      .allExcept(ProtocolDeclSyntax.self)
    }

    override func visitPost(_ node: ProtocolDeclSyntax) {
      if node.name.text.hasSuffix("Delegate"),
        !node.hasObjCAttribute(),
        !node.isClassRestricted(),
        !node.inheritsFromObjectOrDelegate()
      {
        violations.append(node.protocolKeyword.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}

extension ProtocolDeclSyntax {
  fileprivate func hasObjCAttribute() -> Bool {
    attributes.contains(attributeNamed: "objc")
  }

  fileprivate func isClassRestricted() -> Bool {
    inheritanceClause?.inheritedTypes.contains { $0.type.is(ClassRestrictionTypeSyntax.self) }
      == true
  }

  fileprivate func inheritsFromObjectOrDelegate() -> Bool {
    if inheritanceClause?.inheritedTypes
      .contains(where: { $0.type.isObjectOrDelegate() }) == true
    {
      return true
    }

    guard let requirementList = genericWhereClause?.requirements else {
      return false
    }

    return requirementList.contains { requirement in
      guard
        let conformanceRequirement = requirement.requirement
          .as(ConformanceRequirementSyntax.self),
        let simpleLeftType = conformanceRequirement.leftType.as(IdentifierTypeSyntax.self),
        simpleLeftType.typeName == "Self"
      else {
        return false
      }

      return conformanceRequirement.rightType.isObjectOrDelegate()
    }
  }
}

extension TypeSyntax {
  fileprivate func isObjectOrDelegate() -> Bool {
    if let typeName = `as`(IdentifierTypeSyntax.self)?.typeName {
      let objectTypes = ["AnyObject", "NSObjectProtocol", "Actor"]
      return objectTypes.contains(typeName) || typeName.hasSuffix("Delegate")
    }
    if let combined = `as`(CompositionTypeSyntax.self) {
      return combined.elements.contains { $0.type.isObjectOrDelegate() }
    }
    return false
  }
}
