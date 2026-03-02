import SwiftSyntax

struct ExplicitACLRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = ExplicitACLConfiguration()
}

extension ExplicitACLRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension ExplicitACLRule {}

private enum CheckACLState {
  case required
  case inherited
}

extension ExplicitACLRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    private var declScope = Stack<CheckACLState>()

    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
      [
        FunctionDeclSyntax.self,
        SubscriptDeclSyntax.self,
        VariableDeclSyntax.self,
        ProtocolDeclSyntax.self,
        InitializerDeclSyntax.self,
      ]
    }

    override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
      collectViolations(decl: node, token: node.actorKeyword)
      declScope.push(.required)
      return node.modifiers.containsPrivateOrFileprivate() ? .skipChildren : .visitChildren
    }

    override func visitPost(_: ActorDeclSyntax) {
      declScope.pop()
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
      collectViolations(decl: node, token: node.classKeyword)
      declScope.push(.required)
      return node.modifiers.containsPrivateOrFileprivate() ? .skipChildren : .visitChildren
    }

    override func visitPost(_: ClassDeclSyntax) {
      declScope.pop()
    }

    override func visit(_: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
      .skipChildren
    }

    override func visit(_: CodeBlockSyntax) -> SyntaxVisitorContinueKind {
      .skipChildren
    }

    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
      declScope.push(node.modifiers.accessLevelModifier != nil ? .inherited : .required)
      return node.modifiers.containsPrivateOrFileprivate() ? .skipChildren : .visitChildren
    }

    override func visitPost(_: ExtensionDeclSyntax) {
      declScope.pop()
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
      collectViolations(decl: node, token: node.enumKeyword)
      declScope.push(.required)
      return node.modifiers.containsPrivateOrFileprivate() ? .skipChildren : .visitChildren
    }

    override func visitPost(_: EnumDeclSyntax) {
      declScope.pop()
    }

    override func visitPost(_ node: FunctionDeclSyntax) {
      collectViolations(decl: node, token: node.funcKeyword)
    }

    override func visitPost(_ node: InitializerDeclSyntax) {
      collectViolations(decl: node, token: node.initKeyword)
    }

    override func visitPost(_ node: ProtocolDeclSyntax) {
      collectViolations(decl: node, token: node.protocolKeyword)
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
      collectViolations(decl: node, token: node.structKeyword)
      declScope.push(.required)
      return node.modifiers.containsPrivateOrFileprivate() ? .skipChildren : .visitChildren
    }

    override func visitPost(_: StructDeclSyntax) {
      declScope.pop()
    }

    override func visitPost(_ node: SubscriptDeclSyntax) {
      collectViolations(decl: node, token: node.subscriptKeyword)
    }

    override func visitPost(_ node: TypeAliasDeclSyntax) {
      collectViolations(decl: node, token: node.typealiasKeyword)
    }

    override func visitPost(_ node: VariableDeclSyntax) {
      collectViolations(decl: node, token: node.bindingSpecifier)
    }

    private func collectViolations(decl: some WithModifiersSyntax, token: TokenSyntax) {
      let aclModifiers = decl.modifiers.filter { $0.asAccessLevelModifier != nil }
      if declScope.peek() != .inherited,
        aclModifiers.isEmpty || aclModifiers.allSatisfy({ $0.detail != nil })
      {
        violations.append(token.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}
