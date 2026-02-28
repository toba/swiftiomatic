import Foundation
import SwiftSyntax

extension ClassDeclSyntax {
  func isXCTestCase(_ testParentClasses: Set<String>) -> Bool {
    guard let inheritanceList = inheritanceClause?.inheritedTypes else {
      return false
    }
    let inheritedTypes = inheritanceList.compactMap {
      $0.type.as(IdentifierTypeSyntax.self)?.name.text
    }
    return testParentClasses.intersection(inheritedTypes).isNotEmpty
  }
}

extension DeclModifierListSyntax {
  var containsStaticOrClass: Bool {
    contains(keyword: .static) || contains(keyword: .class)
  }

  func containsPrivateOrFileprivate(setOnly: Bool = false) -> Bool {
    if !contains(keyword: .private), !contains(keyword: .fileprivate) {
      return false
    }
    let hasSet = contains { $0.detail?.detail.text == "set" }
    return setOnly ? hasSet : !hasSet
  }

  var accessLevelModifier: DeclModifierSyntax? {
    first { $0.asAccessLevelModifier != nil }
  }

  func accessLevelModifier(setter: Bool = false) -> DeclModifierSyntax? {
    first {
      if $0.asAccessLevelModifier == nil {
        return false
      }
      let hasSetDetail = $0.detail?.detail.tokenKind == .identifier("set")
      return setter ? hasSetDetail : !hasSetDetail
    }
  }

  func contains(keyword: Keyword) -> Bool {
    contains { $0.name.tokenKind == .keyword(keyword) }
  }
}

extension DeclModifierSyntax {
  var asAccessLevelModifier: TokenKind? {
    switch name.tokenKind {
    case .keyword(.open), .keyword(.public), .keyword(.package), .keyword(.internal),
      .keyword(.fileprivate), .keyword(.private):
      return name.tokenKind
    default:
      return nil
    }
  }

  var isStaticOrClass: Bool {
    name.tokenKind == .keyword(.static) || name.tokenKind == .keyword(.class)
  }
}

extension AttributeSyntax {
  var attributeNameText: String {
    attributeName.as(IdentifierTypeSyntax.self)?.name.text ?? attributeName.description
  }
}

extension AttributeListSyntax {
  func contains(attributeNamed attributeName: String) -> Bool {
    contains { $0.as(AttributeSyntax.self)?.attributeNameText == attributeName } == true
  }
}

extension VariableDeclSyntax {
  var isIBOutlet: Bool {
    attributes.contains(attributeNamed: "IBOutlet")
  }

  var weakOrUnownedModifier: DeclModifierSyntax? {
    modifiers.first { decl in
      decl.name.tokenKind == .keyword(.weak) || decl.name.tokenKind == .keyword(.unowned)
    }
  }

  var isInstanceVariable: Bool {
    !modifiers.containsStaticOrClass
  }
}

extension EnumDeclSyntax {
  /// True if this enum supports raw values
  var supportsRawValues: Bool {
    guard let inheritedTypeCollection = inheritanceClause?.inheritedTypes else {
      return false
    }

    let rawValueTypes: Set<String> = [
      "Int", "Int8", "Int16", "Int32", "Int64",
      "UInt", "UInt8", "UInt16", "UInt32", "UInt64",
      "Double", "Float", "Float80", "Decimal", "NSNumber",
      "NSDecimalNumber", "NSInteger", "String", "CGFloat",
    ]

    return inheritedTypeCollection.contains { element in
      guard let identifier = element.type.as(IdentifierTypeSyntax.self)?.name.text else {
        return false
      }

      return rawValueTypes.contains(identifier)
    }
  }

  /// True if this enum is a `CodingKey`. For that, it has to be named `CodingKeys`
  /// and must conform to the `CodingKey` protocol.
  var definesCodingKeys: Bool {
    guard let inheritedTypeCollection = inheritanceClause?.inheritedTypes,
      name.text == "CodingKeys"
    else {
      return false
    }

    return inheritedTypeCollection.contains { element in
      element.type.as(IdentifierTypeSyntax.self)?.name.text == "CodingKey"
    }
  }
}

extension FunctionDeclSyntax {
  var isIBAction: Bool {
    attributes.contains(attributeNamed: "IBAction")
  }

  /// Returns the signature including arguments, e.g "setEditing(_:animated:)"
  var resolvedName: String {
    var name = name.text
    name += "("

    let params = signature.parameterClause.parameters.compactMap { param in
      param.firstName.text.appending(":")
    }

    name += params.joined()
    name += ")"
    return name
  }

  /// How many times this function calls the `super` implementation in its body.
  /// Returns 0 if the function has no body.
  func numberOfCallsToSuper() -> Int {
    guard let body else {
      return 0
    }

    return SuperCallVisitor(expectedFunctionName: name.text)
      .walk(tree: body, handler: \.superCallsCount)
  }
}

extension AccessorBlockSyntax {
  var getAccessor: AccessorDeclSyntax? {
    accessorsList.first { $0.accessorSpecifier.tokenKind == .keyword(.get) }
  }

  var setAccessor: AccessorDeclSyntax? {
    accessorsList.first { $0.accessorSpecifier.tokenKind == .keyword(.set) }
  }

  var specifiesGetAccessor: Bool {
    getAccessor != nil
  }

  var specifiesSetAccessor: Bool {
    setAccessor != nil
  }

  var accessorsList: AccessorDeclListSyntax {
    if case .accessors(let list) = accessors {
      return list
    }
    return AccessorDeclListSyntax([])
  }
}

extension InheritanceClauseSyntax? {
  func containsInheritedType(inheritedTypes: Set<String>) -> Bool {
    self?.inheritedTypes.contains { elem in
      guard let simpleType = elem.type.as(IdentifierTypeSyntax.self) else {
        return false
      }

      return inheritedTypes.contains(simpleType.name.text)
    } ?? false
  }
}

private final class SuperCallVisitor: SyntaxVisitor {
  private let expectedFunctionName: String
  private(set) var superCallsCount = 0

  init(expectedFunctionName: String) {
    self.expectedFunctionName = expectedFunctionName
    super.init(viewMode: .sourceAccurate)
  }

  override func visitPost(_ node: FunctionCallExprSyntax) {
    guard let expr = node.calledExpression.as(MemberAccessExprSyntax.self),
      expr.base?.as(SuperExprSyntax.self) != nil,
      expr.declName.baseName.text == expectedFunctionName
    else {
      return
    }

    superCallsCount += 1
  }
}
