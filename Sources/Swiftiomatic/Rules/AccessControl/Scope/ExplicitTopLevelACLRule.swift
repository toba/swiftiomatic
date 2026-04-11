import SwiftSyntax

struct ExplicitTopLevelACLRule {
  static let id = "explicit_top_level_acl"
  static let name = "Explicit Top Level ACL"
  static let summary =
    "Top-level declarations should specify Access Control Level keywords explicitly"
  static let isOptIn = true
  static var nonTriggeringExamples: [Example] {
    [
      Example("internal enum A {}"),
      Example("public final class B {}"),
      Example(
        """
        private struct S1 {
            struct S2 {}
        }
        """,
      ),
      Example("internal enum A { enum B {} }"),
      Example("internal final actor Foo {}"),
      Example("internal typealias Foo = Bar"),
      Example("internal func a() {}"),
      Example("extension A: Equatable {}"),
      Example("extension A {}"),
      Example("f { func f() {} }", isExcludedFromDocumentation: true),
      Example("do { func f() {} }", isExcludedFromDocumentation: true),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example("↓enum A {}"),
      Example("final ↓class B {}"),
      Example("↓protocol P {}"),
      Example("↓func a() {}"),
      Example("internal let a = 0\n↓func b() {}"),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension ExplicitTopLevelACLRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

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
