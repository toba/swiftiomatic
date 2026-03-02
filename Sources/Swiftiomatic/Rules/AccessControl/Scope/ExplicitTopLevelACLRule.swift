import SwiftSyntax

struct ExplicitTopLevelACLRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = ExplicitTopLevelACLConfiguration()
}

extension ExplicitTopLevelACLRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension ExplicitTopLevelACLRule {}

extension ExplicitTopLevelACLRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
      .all
    }

    override func visitPost(_ node: ClassDeclSyntax) {
      collectViolations(decl: node, token: node.classKeyword)
    }

    override func visitPost(_ node: StructDeclSyntax) {
      collectViolations(decl: node, token: node.structKeyword)
    }

    override func visitPost(_ node: EnumDeclSyntax) {
      collectViolations(decl: node, token: node.enumKeyword)
    }

    override func visitPost(_ node: ProtocolDeclSyntax) {
      collectViolations(decl: node, token: node.protocolKeyword)
    }

    override func visitPost(_ node: ActorDeclSyntax) {
      collectViolations(decl: node, token: node.actorKeyword)
    }

    override func visitPost(_ node: TypeAliasDeclSyntax) {
      collectViolations(decl: node, token: node.typealiasKeyword)
    }

    override func visitPost(_ node: FunctionDeclSyntax) {
      collectViolations(decl: node, token: node.funcKeyword)
    }

    override func visitPost(_ node: VariableDeclSyntax) {
      collectViolations(decl: node, token: node.bindingSpecifier)
    }

    override func visit(_: CodeBlockSyntax) -> SyntaxVisitorContinueKind {
      .skipChildren
    }

    override func visit(_: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
      .skipChildren
    }

    private func collectViolations(decl: some WithModifiersSyntax, token: TokenSyntax) {
      if decl.modifiers.accessLevelModifier == nil {
        violations.append(token.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}
