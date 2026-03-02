import SwiftSyntax

struct ConvenienceTypeRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = ConvenienceTypeConfiguration()
}

extension ConvenienceTypeRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension ConvenienceTypeRule {}

extension ConvenienceTypeRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
      [ProtocolDeclSyntax.self]
    }

    override func visitPost(_ node: StructDeclSyntax) {
      if hasViolation(
        inheritance: node.inheritanceClause,
        attributes: node.attributes,
        members: node.memberBlock,
      ) {
        violations.append(node.structKeyword.positionAfterSkippingLeadingTrivia)
      }
    }

    override func visitPost(_ node: ClassDeclSyntax) {
      if hasViolation(
        inheritance: node.inheritanceClause,
        attributes: node.attributes,
        members: node.memberBlock,
      ) {
        violations.append(node.classKeyword.positionAfterSkippingLeadingTrivia)
      }
    }

    private func hasViolation(
      inheritance: InheritanceClauseSyntax?,
      attributes: AttributeListSyntax?,
      members: MemberBlockSyntax,
    ) -> Bool {
      guard inheritance.isNilOrEmpty,
        attributes?.containsObjcMembers == false,
        attributes?.containsObjc == false,
        !members.members.isEmpty
      else {
        return false
      }

      return ConvenienceTypeCheckVisitor(configuration: configuration, file: file)
        .walk(tree: members, handler: \.canBeConvenienceType)
    }
  }

  fileprivate final class ConvenienceTypeCheckVisitor: ViolationCollectingVisitor<OptionsType>
  {
    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
      .all
    }

    private(set) var canBeConvenienceType = true

    override func visitPost(_ node: VariableDeclSyntax) {
      if node.isInstanceVariable {
        canBeConvenienceType = false
      } else if node.attributes.containsObjc {
        canBeConvenienceType = false
      }
    }

    override func visitPost(_ node: FunctionDeclSyntax) {
      if node.modifiers.containsStaticOrClass {
        if node.attributes.containsObjc {
          canBeConvenienceType = false
        }
      } else {
        canBeConvenienceType = false
      }
    }

    override func visitPost(_ node: InitializerDeclSyntax) {
      if !node.attributes.hasUnavailableAttribute {
        canBeConvenienceType = false
      }
    }

    override func visitPost(_ node: SubscriptDeclSyntax) {
      if !node.modifiers.containsStaticOrClass {
        canBeConvenienceType = false
      }
    }
  }
}

extension InheritanceClauseSyntax? {
  fileprivate var isNilOrEmpty: Bool {
    self?.inheritedTypes.isEmpty ?? true
  }
}

extension AttributeListSyntax {
  fileprivate var containsObjcMembers: Bool {
    contains(attributeNamed: "objcMembers")
  }

  fileprivate var containsObjc: Bool {
    contains(attributeNamed: "objc")
  }

  fileprivate var hasUnavailableAttribute: Bool {
    contains { elem in
      guard let attr = elem.as(AttributeSyntax.self),
        attr.attributeNameText == "available",
        let arguments = attr.arguments?.as(AvailabilityArgumentListSyntax.self)
      else {
        return false
      }
      return arguments.contains {
        $0.argument.as(TokenSyntax.self)?.tokenKind.isUnavailableKeyword == true
      }
    }
  }
}
