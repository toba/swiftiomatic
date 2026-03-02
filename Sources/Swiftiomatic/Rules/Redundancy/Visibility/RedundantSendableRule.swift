import SwiftSyntax

struct RedundantSendableRule {
  var options = RedundantSendableOptions()

  static let configuration = RedundantSendableConfiguration()
}

extension RedundantSendableRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension RedundantSendableRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: ActorDeclSyntax) {
      if node.conformsToSendable {
        violations.append(at: node.name.positionAfterSkippingLeadingTrivia)
      }
    }

    override func visitPost(_ node: ClassDeclSyntax) {
      collectViolations(in: node)
    }

    override func visitPost(_ node: EnumDeclSyntax) {
      collectViolations(in: node)
    }

    override func visitPost(_ node: StructDeclSyntax) {
      collectViolations(in: node)
    }

    private func collectViolations(in decl: some DeclGroupSyntax & NamedDeclSyntax) {
      if decl.conformsToSendable, decl.isIsolatedToActor(actors: configuration.globalActors) {
        violations.append(at: decl.name.positionAfterSkippingLeadingTrivia)
      }
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: ActorDeclSyntax) -> DeclSyntax {
      if node.conformsToSendable {
        numberOfCorrections += 1
        return super.visit(node.withoutSendable)
      }
      return super.visit(node)
    }

    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
      super.visit(removeRedundantSendable(from: node))
    }

    override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
      super.visit(removeRedundantSendable(from: node))
    }

    override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
      super.visit(removeRedundantSendable(from: node))
    }

    private func removeRedundantSendable<T: DeclGroupSyntax & NamedDeclSyntax>(from decl: T)
      -> T
    {
      if decl.conformsToSendable, decl.isIsolatedToActor(actors: configuration.globalActors) {
        numberOfCorrections += 1
        return decl.withoutSendable
      }
      return decl
    }
  }
}

extension DeclGroupSyntax where Self: NamedDeclSyntax {
  fileprivate var conformsToSendable: Bool {
    inheritanceClause?.inheritedTypes.contains(where: \.isSendable) == true
  }

  fileprivate func isIsolatedToActor(actors: Set<String>) -> Bool {
    attributes.contains(attributeNamed: "MainActor")
      || actors.contains { attributes.contains(attributeNamed: $0) }
  }

  fileprivate var withoutSendable: Self {
    guard let inheritanceClause else {
      return self
    }
    let inheritedTypes = inheritanceClause.inheritedTypes.filter { !$0.isSendable }
    if let lastType = inheritedTypes.last, let lastIndex = inheritedTypes.index(of: lastType) {
      return with(
        \.inheritanceClause,
        inheritanceClause
          .with(
            \.inheritedTypes,
            inheritedTypes.with(\.[lastIndex], lastType.withoutComma),
          ),
      )
    }
    return with(\.inheritanceClause, nil)
      .with(
        \.name.trailingTrivia,
        inheritanceClause.leadingTrivia + inheritanceClause.trailingTrivia,
      )
  }
}

extension InheritedTypeSyntax {
  fileprivate var isSendable: Bool {
    type.as(IdentifierTypeSyntax.self)?.name.text == "Sendable"
  }

  fileprivate var withoutComma: InheritedTypeSyntax {
    with(\.trailingComma, nil)
      .with(\.trailingTrivia, trailingTrivia)
  }
}
