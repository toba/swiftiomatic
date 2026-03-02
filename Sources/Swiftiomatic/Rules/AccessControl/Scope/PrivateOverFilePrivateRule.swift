import SwiftSyntax

struct PrivateOverFilePrivateRule {
  var options = PrivateOverFilePrivateOptions()

  static let configuration = PrivateOverFilePrivateConfiguration()
}

extension PrivateOverFilePrivateRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension PrivateOverFilePrivateRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
      .all
    }

    override func visitPost(_ node: ActorDeclSyntax) {
      checkModifier(on: node)
    }

    override func visitPost(_ node: ClassDeclSyntax) {
      checkModifier(on: node)
    }

    override func visitPost(_ node: EnumDeclSyntax) {
      checkModifier(on: node)
    }

    override func visitPost(_ node: ExtensionDeclSyntax) {
      if configuration.validateExtensions {
        checkModifier(on: node)
      }
    }

    override func visitPost(_ node: FunctionDeclSyntax) {
      checkModifier(on: node)
    }

    override func visitPost(_ node: ProtocolDeclSyntax) {
      checkModifier(on: node)
    }

    override func visitPost(_ node: StructDeclSyntax) {
      checkModifier(on: node)
    }

    override func visitPost(_ node: TypeAliasDeclSyntax) {
      checkModifier(on: node)
    }

    override func visitPost(_ node: InitializerDeclSyntax) {
      checkModifier(on: node)
    }

    override func visitPost(_ node: VariableDeclSyntax) {
      checkModifier(on: node)
    }

    private func checkModifier(on node: some WithModifiersSyntax) {
      if let modifier = node.modifiers
        .first(where: { $0.name.tokenKind == .keyword(.fileprivate) })
      {
        violations.append(
          at: modifier.positionAfterSkippingLeadingTrivia,
          correction: .init(
            start: modifier.positionAfterSkippingLeadingTrivia,
            end: modifier.endPositionBeforeTrailingTrivia,
            replacement: "private",
          ),
        )
      }
    }
  }
}
