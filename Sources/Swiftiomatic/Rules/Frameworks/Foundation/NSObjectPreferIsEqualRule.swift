import SwiftSyntax

struct NSObjectPreferIsEqualRule {
    static let id = "nsobject_prefer_isequal"
    static let name = "NSObject Prefer isEqual"
    static let summary = "NSObject subclasses should implement isEqual instead of =="
  var options = SeverityOption<Self>(.warning)

}

extension NSObjectPreferIsEqualRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension NSObjectPreferIsEqualRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
      [ProtocolDeclSyntax.self]
    }

    override func visitPost(_ node: FunctionDeclSyntax) {
      if node.isSelfEqualFunction, node.isInObjcClass {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}

extension ClassDeclSyntax {
  fileprivate var isObjC: Bool {
    if attributes.isObjc {
      return true
    }

    guard let inheritanceList = inheritanceClause?.inheritedTypes else {
      return false
    }
    return inheritanceList.contains { type in
      type.type.as(IdentifierTypeSyntax.self)?.name.text == "NSObject"
    }
  }
}

extension FunctionDeclSyntax {
  fileprivate var isSelfEqualFunction: Bool {
    guard
      modifiers.contains(keyword: .static),
      name.text == "==",
      returnsBool,
      case let parameterList = signature.parameterClause.parameters,
      parameterList.count == 2,
      let lhs = parameterList.first,
      let rhs = parameterList.last,
      lhs.firstName.text == "lhs",
      rhs.firstName.text == "rhs",
      lhs.type.trimmedDescription == rhs.type.trimmedDescription
    else {
      return false
    }

    return true
  }

  fileprivate var returnsBool: Bool {
    signature.returnClause?.type.as(IdentifierTypeSyntax.self)?.name.text == "Bool"
  }
}

extension SyntaxProtocol {
  fileprivate var isInObjcClass: Bool {
    if let parentClass = parent?.as(ClassDeclSyntax.self) {
      return parentClass.isObjC
    }
    if parent?.as(DeclSyntax.self) != nil {
      return false
    }

    return parent?.isInObjcClass ?? false
  }
}

extension AttributeListSyntax {
  fileprivate var isObjc: Bool {
    contains(attributeNamed: "objc") || contains(attributeNamed: "objcMembers")
  }
}
