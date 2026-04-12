import SwiftiomaticSyntax

struct IncompatibleConcurrencyAnnotationRule {
  static let id = "incompatible_concurrency_annotation"
  static let name = "Incompatible Concurrency Annotation"
  static let summary =
    "Declaration should be @preconcurrency to maintain compatibility with Swift 5"
  static let isCorrectable = true
  static let isOptIn = true
  static let rationale: String? = """
    Declarations that use concurrency features such as `@Sendable` closures, `Sendable` generic type
    arguments or `@MainActor` (or other global actors) should be annotated with `@preconcurrency`
    to ensure compatibility with Swift 5.

    This rule detects public declarations that require `@preconcurrency` and can automatically add
    the annotation.
    """
  var options = IncompatibleConcurrencyAnnotationOptions()
}

extension IncompatibleConcurrencyAnnotationRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension IncompatibleConcurrencyAnnotationRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: ClassDeclSyntax) {
      collectViolations(node, introducer: node.classKeyword)
    }

    override func visitPost(_ node: EnumDeclSyntax) {
      collectViolations(node, introducer: node.enumKeyword)
    }

    override func visitPost(_ node: FunctionDeclSyntax) {
      collectViolations(node, introducer: node.funcKeyword)
    }

    override func visitPost(_ node: InitializerDeclSyntax) {
      collectViolations(node, introducer: node.initKeyword)
    }

    override func visitPost(_ node: ProtocolDeclSyntax) {
      collectViolations(node, introducer: node.protocolKeyword)
    }

    override func visitPost(_ node: StructDeclSyntax) {
      collectViolations(node, introducer: node.structKeyword)
    }

    override func visitPost(_ node: SubscriptDeclSyntax) {
      collectViolations(node, introducer: node.subscriptKeyword)
    }

    private func collectViolations(
      _ node: some WithModifiersSyntax & WithAttributesSyntax,
      introducer: TokenSyntax,
    ) {
      if preconcurrencyRequired(for: node, with: configuration.globalActors) {
        violations.append(at: introducer.positionAfterSkippingLeadingTrivia)
      }
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
      super.visit(rewrite(node))
    }

    override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
      super.visit(rewrite(node))
    }

    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
      super.visit(rewrite(node))
    }

    override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
      super.visit(rewrite(node))
    }

    override func visit(_ node: ProtocolDeclSyntax) -> DeclSyntax {
      super.visit(rewrite(node))
    }

    override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
      super.visit(rewrite(node))
    }

    override func visit(_ node: SubscriptDeclSyntax) -> DeclSyntax {
      super.visit(rewrite(node))
    }

    private func rewrite<T: WithModifiersSyntax & WithAttributesSyntax>(_ node: T) -> T {
      if preconcurrencyRequired(for: node, with: configuration.globalActors) {
        numberOfCorrections += 1
        return node.withPreconcurrencyPrepended
      }
      return node
    }
  }
}

private func preconcurrencyRequired(
  for syntax: some WithModifiersSyntax & WithAttributesSyntax,
  with globalActors: Set<String>,
) -> Bool {
  guard syntax.isPublic, !syntax.isPreconcurrency else {
    return false
  }

  // Check attributes for global actors.
  let attributeNames = syntax.attributes.compactMap {
    $0.as(AttributeSyntax.self)?.attributeNameText
  }
  var required = globalActors.intersection(attributeNames).isNotEmpty
  if required { return true }

  // Check generic type constraints for `@Sendable`.
  if let whereClause = syntax.asProtocol((any WithGenericParametersSyntax).self)?
    .genericWhereClause
  {
    required =
      required
      || whereClause.requirements.contains { requirement in
        if case .conformanceRequirement(let conformance) = requirement.requirement {
          return conformance.rightType.isSendable
        }
        return false
      }
    if required { return true }
  }

  // Check parameters for `@Sendable` and global actors.
  let parameterClause =
    syntax.as(FunctionDeclSyntax.self)?.signature.parameterClause
    ?? syntax.as(InitializerDeclSyntax.self)?.signature.parameterClause
    ?? syntax.as(SubscriptDeclSyntax.self)?.parameterClause
  let visitor = SendableTypeVisitor(globalActors: globalActors)
  if let parameterClause {
    required =
      required
      || parameterClause.parameters.contains {
        visitor.walk(
          tree: $0,
          handler: \.found,
        )
      }
    if required { return true }
  }

  // Check return types for `@Sendable` and global actors.
  let returnType =
    syntax.as(FunctionDeclSyntax.self)?.signature.returnClause?.type
    ?? syntax.as(SubscriptDeclSyntax.self)?.returnClause.type
  if let returnType {
    required = required || visitor.walk(tree: returnType, handler: \.found)
  }
  return required
}

extension WithAttributesSyntax where Self: WithModifiersSyntax {
  fileprivate var isPreconcurrency: Bool {
    attributes.contains(attributeNamed: "preconcurrency")
  }

  fileprivate var isPublic: Bool {
    modifiers.contains(keyword: .public) || modifiers.contains(keyword: .open)
  }

  fileprivate var withPreconcurrencyPrepended: Self {
    let leadingWhitespace = Trivia(
      pieces: leadingTrivia.reversed().prefix(while: \.isSpaceOrTab).reversed(),
    )
    let attribute = AttributeListSyntax.Element.attribute("@preconcurrency")
      .with(\.leadingTrivia, leadingTrivia)
      .with(\.trailingTrivia, .newlines(1))
    return attributes.isEmpty
      ? with(\.leadingTrivia, leadingWhitespace).with(\.attributes, [attribute])
      : with(\.attributes, [attribute] + attributes.with(\.leadingTrivia, leadingWhitespace))
  }
}

extension TypeSyntax {
  fileprivate var isSendable: Bool {
    if let identifierType = `as`(IdentifierTypeSyntax.self) {
      return identifierType.name.text == "Sendable"
    }
    if let compositeType = `as`(CompositionTypeSyntax.self) {
      return compositeType.elements.contains(where: \.type.isSendable)
    }
    return false
  }
}

private final class SendableTypeVisitor: SyntaxVisitor {
  private(set) var found = false

  private let globalActors: Set<String>

  init(globalActors: Set<String>) {
    self.globalActors = globalActors
    super.init(viewMode: .sourceAccurate)
  }

  override func visitPost(_ node: AttributedTypeSyntax) {
    if found {
      return
    }
    found =
      found
      || node.attributes.contains {
        if let attribute = $0.as(AttributeSyntax.self) {
          let name = attribute.attributeNameText
          return name == "Sendable" || globalActors.contains(name)
        }
        return false
      }
  }
}
