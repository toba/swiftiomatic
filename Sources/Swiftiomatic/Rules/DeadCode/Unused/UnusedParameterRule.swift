import SwiftSyntax

struct UnusedParameterRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = UnusedParameterConfiguration()
}

extension UnusedParameterRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension UnusedParameterRule {}

// MARK: Visitor

extension UnusedParameterRule {
  fileprivate final class Visitor: DeclaredIdentifiersTrackingVisitor<OptionsType> {
    private var referencedDeclarations = Set<IdentifierDeclaration>()

    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
      [ProtocolDeclSyntax.self]
    }

    // MARK: Violation checking

    override func visitPost(_ node: CodeBlockItemListSyntax) {
      let declarations = scope.peek() ?? []
      for declaration in declarations.reversed()
      where !referencedDeclarations.contains(declaration) {
        guard case .parameter(let name) = declaration,
          let previousToken = name.previousToken(viewMode: .sourceAccurate)
        else {
          continue
        }
        let startPosReplacement =
          if previousToken.tokenKind == .wildcard {
            (previousToken.positionAfterSkippingLeadingTrivia, "_")
          } else if case .identifier = previousToken.tokenKind {
            (name.positionAfterSkippingLeadingTrivia, "_")
          } else {
            (name.positionAfterSkippingLeadingTrivia, name.text + " _")
          }
        violations.append(
          .init(
            position: name.positionAfterSkippingLeadingTrivia,
            reason:
              "Parameter '\(name.text)' is unused; consider removing or replacing it with '_'",
            severity: configuration.severity,
            correction: .init(
              start: startPosReplacement.0,
              end: name.endPositionBeforeTrailingTrivia,
              replacement: startPosReplacement.1,
            ),
          ),
        )
      }
      super.visitPost(node)
    }

    // MARK: Reference collection

    override func visitPost(_ node: DeclReferenceExprSyntax) {
      if node.keyPathInParent != \MemberAccessExprSyntax.declName {
        addReference(node.baseName.text)
      }
    }

    override func visitPost(_ node: OptionalBindingConditionSyntax) {
      if node.initializer == nil,
        let id = node.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
      {
        addReference(id)
      }
    }

    // MARK: Private methods

    private func addReference(_ id: String) {
      for declarations in scope.reversed() {
        if declarations.onlyElement == .lookupBoundary {
          return
        }
        for declaration in declarations.reversed() where declaration.declares(id: id) {
          if referencedDeclarations.insert(declaration).inserted {
            return
          }
        }
      }
    }
  }
}
