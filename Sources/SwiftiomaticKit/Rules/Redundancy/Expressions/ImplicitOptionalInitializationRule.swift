import SwiftiomaticSyntax

struct ImplicitOptionalInitializationRule {
  static let id = "implicit_optional_initialization"
  static let name = "Implicit Optional Initialization"
  static let summary =
    "Optionals should be consistently initialized, either with `= nil` or without."
  static let isCorrectable = true
  static let deprecatedAliases: Set<String> = ["redundant_optional_initialization"]
  var options = ImplicitOptionalInitializationOptions()
}

extension ImplicitOptionalInitializationRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension ImplicitOptionalInitializationRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    var reason: String {
      switch configuration.style {
      case .always: "Optional should be implicitly initialized without nil"
      case .never: "Optional should be explicitly initialized to nil"
      }
    }

    override func visitPost(_ node: PatternBindingSyntax) {
      guard let violationPosition = node.violationPosition(for: configuration.style)
      else { return }

      violations.append(SyntaxViolation(position: violationPosition, reason: reason))
    }
  }
}

extension ImplicitOptionalInitializationRule {
  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: PatternBindingSyntax) -> PatternBindingSyntax {
      guard node.violationPosition(for: configuration.style) != nil else {
        return super.visit(node)
      }

      numberOfCorrections += 1

      return switch configuration.style {
      case .never:
        node
          .with(
            \.initializer,
            InitializerClauseSyntax(
              equal: .equalToken(
                leadingTrivia: .space,
                trailingTrivia: .space,
              ),
              value: ExprSyntax(NilLiteralExprSyntax(nilKeyword: .keyword(.nil))),
              trailingTrivia: node.typeAnnotation?.trailingTrivia ?? Trivia(),
            ),
          )
          .with(
            \.typeAnnotation,
            node.typeAnnotation?.with(\.trailingTrivia, Trivia()),
          )
      case .always:
        node
          .with(\.initializer, nil)
          .with(
            \.trailingTrivia,
            node.accessorBlock == nil
              ? node.initializer?.trailingTrivia ?? Trivia()
              : node.trailingTrivia,
          )
      }
    }
  }
}

extension PatternBindingSyntax {
  fileprivate func violationPosition(
    for style: ImplicitOptionalInitializationOptions.Style,
  ) -> AbsolutePosition? {
    guard
      let parent = parent?.parent?.as(VariableDeclSyntax.self),
      parent.bindingSpecifier.tokenKind == .keyword(.var),
      !parent.modifiers.contains(keyword: .lazy),
      let typeAnnotation,
      typeAnnotation.isOptionalType
    else { return nil }

    // Skip stored properties in Codable/Decodable types —
    // removing = nil can change synthesized decoder behavior for missing keys
    if parent.isStoredPropertyInCodableType {
      return nil
    }

    // Skip in result builder bodies
    if parent.isInResultBuilderContext {
      return nil
    }

    // ignore properties with accessors unless they have only willSet or didSet
    if let accessorBlock {
      if let accessors = accessorBlock.accessors.as(AccessorDeclListSyntax.self) {
        if accessors.contains(where: {
          $0.accessorSpecifier.tokenKind != .keyword(.willSet)
            && $0.accessorSpecifier.tokenKind != .keyword(.didSet)
        }) {  // we have more than willSet or didSet
          return nil
        }
      } else {  // code block, i.e. getter
        return nil
      }
    }

    if (style == .never && !initializer.isNil) || (style == .always && initializer.isNil) {
      return positionAfterSkippingLeadingTrivia
    }

    return nil
  }
}

extension InitializerClauseSyntax? {
  fileprivate var isNil: Bool {
    self?.value.is(NilLiteralExprSyntax.self) ?? false
  }
}

extension TypeAnnotationSyntax {
  fileprivate var isOptionalType: Bool {
    if type.is(OptionalTypeSyntax.self) { return true }

    if let type = type.as(IdentifierTypeSyntax.self),
      let genericClause = type.genericArgumentClause
    {
      return genericClause.arguments.count == 1 && type.name.text == "Optional"
    }

    return false
  }
}

// MARK: - Context Exclusions

private let codableConformances: Set<String> = ["Codable", "Decodable"]

extension VariableDeclSyntax {
  /// Whether this is a stored property inside a type conforming to Codable or Decodable
  fileprivate var isStoredPropertyInCodableType: Bool {
    guard parent?.is(MemberBlockItemSyntax.self) == true else { return false }
    var current: Syntax? = parent
    while let node = current {
      if let decl = node.as(StructDeclSyntax.self) {
        return decl.inheritanceClause.containsInheritedType(inheritedTypes: codableConformances)
      }
      if let decl = node.as(ClassDeclSyntax.self) {
        return decl.inheritanceClause.containsInheritedType(inheritedTypes: codableConformances)
      }
      if let decl = node.as(EnumDeclSyntax.self) {
        return decl.inheritanceClause.containsInheritedType(inheritedTypes: codableConformances)
      }
      if let decl = node.as(ActorDeclSyntax.self) {
        return decl.inheritanceClause.containsInheritedType(inheritedTypes: codableConformances)
      }
      current = node.parent
    }
    return false
  }

  /// Whether this variable is inside a result builder body (function or property with a Builder attribute)
  fileprivate var isInResultBuilderContext: Bool {
    var current: Syntax? = parent
    while let node = current {
      if let funcDecl = node.as(FunctionDeclSyntax.self) {
        return funcDecl.attributes.containsResultBuilderAttribute
      }
      if let varDecl = node.as(VariableDeclSyntax.self) {
        return varDecl.attributes.containsResultBuilderAttribute
      }
      current = node.parent
    }
    return false
  }
}

extension AttributeListSyntax {
  fileprivate var containsResultBuilderAttribute: Bool {
    contains { element in
      guard let attr = element.as(AttributeSyntax.self) else { return false }
      return attr.attributeNameText.hasSuffix("Builder")
    }
  }
}
