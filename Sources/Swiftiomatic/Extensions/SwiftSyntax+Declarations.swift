import Foundation
import SwiftSyntax

extension ClassDeclSyntax {
  /// Whether this class directly inherits from one of the given test parent classes
  ///
  /// - Parameters:
  ///   - testParentClasses: Set of class names considered XCTest base classes (e.g. `"XCTestCase"`).
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
  /// Whether the modifier list includes `static` or `class`
  var containsStaticOrClass: Bool {
    contains(keyword: .static) || contains(keyword: .class)
  }

  /// Whether the list contains `private` or `fileprivate`
  ///
  /// When `setOnly` is `true`, only matches modifiers that apply to the setter
  /// (e.g. `private(set)`). When `false`, matches bare `private`/`fileprivate`
  /// without a `(set)` detail.
  ///
  /// - Parameters:
  ///   - setOnly: If `true`, require `(set)` detail; if `false`, require its absence.
  func containsPrivateOrFileprivate(setOnly: Bool = false) -> Bool {
    if !contains(keyword: .private), !contains(keyword: .fileprivate) {
      return false
    }
    let hasSet = contains { $0.detail?.detail.text == "set" }
    return setOnly ? hasSet : !hasSet
  }

  /// The access control level from bare (non-setter) modifiers, or `nil` if none is present
  var accessibility: AccessControlLevel? {
    filter { $0.detail == nil }.compactMap { AccessControlLevel(description: $0.name.text) }
      .first
  }

  /// The first access-level modifier (`public`, `internal`, `private`, etc.) in the list
  var accessLevelModifier: DeclModifierSyntax? {
    first { $0.asAccessLevelModifier != nil }
  }

  /// The access-level modifier for either the getter or setter
  ///
  /// - Parameters:
  ///   - setter: When `true`, return the modifier with a `(set)` detail;
  ///     when `false`, return the one without.
  func accessLevelModifier(setter: Bool = false) -> DeclModifierSyntax? {
    first {
      if $0.asAccessLevelModifier == nil {
        return false
      }
      let hasSetDetail = $0.detail?.detail.tokenKind == .identifier("set")
      return setter ? hasSetDetail : !hasSetDetail
    }
  }

  /// Whether the modifier list contains a modifier with the given keyword
  ///
  /// - Parameters:
  ///   - keyword: The ``Keyword`` to search for (e.g. `.override`, `.static`).
  func contains(keyword: Keyword) -> Bool {
    contains { $0.name.tokenKind == .keyword(keyword) }
  }
}

extension DeclModifierSyntax {
  /// The token kind if this modifier is an access level keyword, or `nil` otherwise
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
  /// Whether the list contains an attribute with the given name
  ///
  /// - Parameters:
  ///   - attributeName: The attribute name to match (e.g. `"IBOutlet"`, `"discardableResult"`).
  func contains(attributeNamed attributeName: String) -> Bool {
    contains { $0.as(AttributeSyntax.self)?.attributeNameText == attributeName } == true
  }
}

extension VariableDeclSyntax {
  /// Whether this variable is decorated with `@IBOutlet`
  var isIBOutlet: Bool {
    attributes.contains(attributeNamed: "IBOutlet")
  }

  /// The `weak` or `unowned` modifier if present, or `nil`
  var weakOrUnownedModifier: DeclModifierSyntax? {
    modifiers.first { decl in
      decl.name.tokenKind == .keyword(.weak) || decl.name.tokenKind == .keyword(.unowned)
    }
  }

  /// Whether this variable is an instance member (not `static` or `class`)
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
  /// Whether this function is decorated with `@IBAction`
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

  /// Context for an overridden method that matches one of the given method names
  ///
  /// Returns the resolved name, body, and super-call count when this function is a
  /// non-static `override` whose ``resolvedName`` appears in `methodNames`.
  /// Shared guard logic used by `OverriddenSuperCallRule` and `ProhibitedSuperRule`.
  ///
  /// - Parameters:
  ///   - methodNames: Resolved method names to match against (e.g. `["viewDidLoad()"]`).
  /// - Returns: A tuple of the matched name, function body, and number of `super` calls,
  ///   or `nil` when the function does not match.
  func superCallContext(
    matchingMethodNames methodNames: [String],
  ) -> (name: String, body: CodeBlockSyntax, callCount: Int)? {
    guard let body,
      modifiers.contains(keyword: .override),
      !modifiers.containsStaticOrClass
    else {
      return nil
    }
    let name = resolvedName
    guard methodNames.contains(name) else {
      return nil
    }
    return (name, body, numberOfCallsToSuper())
  }
}

extension AccessorBlockSyntax {
  /// The `get` accessor declaration, if present
  var getAccessor: AccessorDeclSyntax? {
    accessorsList.first { $0.accessorSpecifier.tokenKind == .keyword(.get) }
  }

  /// The `set` accessor declaration, if present
  var setAccessor: AccessorDeclSyntax? {
    accessorsList.first { $0.accessorSpecifier.tokenKind == .keyword(.set) }
  }

  var specifiesGetAccessor: Bool {
    getAccessor != nil
  }

  var specifiesSetAccessor: Bool {
    setAccessor != nil
  }

  /// The accessor declarations as a list, or an empty list for getter-only shorthand
  var accessorsList: AccessorDeclListSyntax {
    if case .accessors(let list) = accessors {
      return list
    }
    return AccessorDeclListSyntax([])
  }
}

extension InheritanceClauseSyntax? {
  /// Whether the inheritance clause includes at least one type whose name is in the given set
  ///
  /// - Parameters:
  ///   - inheritedTypes: Type names to check against (e.g. `["Codable", "Equatable"]`).
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
