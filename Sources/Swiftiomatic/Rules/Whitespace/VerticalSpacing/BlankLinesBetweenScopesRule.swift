import SwiftSyntax

struct BlankLinesBetweenScopesRule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "blank_lines_between_scopes",
    name: "Blank Lines Between Scopes",
    description:
      "There should be a blank line before type declarations and multi-line functions",
    scope: .format,
    nonTriggeringExamples: [
      Example(
        """
        class Foo {}

        class Bar {}
        """),
      Example(
        """
        func foo() {
          // foo
        }

        func bar() {
          // bar
        }
        """),
    ],
    triggeringExamples: [
      Example(
        """
        class Foo {}
        ↓class Bar {}
        """)
    ],
  )
}

extension BlankLinesBetweenScopesRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: configuration, file: file)
  }
}

extension BlankLinesBetweenScopesRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: SourceFileSyntax) {
      checkStatements(node.statements)
    }

    override func visitPost(_ node: MemberBlockSyntax) {
      checkMembers(node.members)
    }

    private func checkStatements(_ statements: CodeBlockItemListSyntax) {
      var prevWasScope = false
      for item in statements {
        let isScope = isScopeDecl(item.item)
        if isScope || prevWasScope, prevWasScope {
          checkBlankLineBefore(item)
        }
        prevWasScope = isScope
      }
    }

    private func checkMembers(_ members: MemberBlockItemListSyntax) {
      var prevWasScope = false
      for member in members {
        let isScope = isScopeDecl(DeclSyntax(member.decl))
        if isScope || prevWasScope, prevWasScope {
          checkBlankLineBefore(member)
        }
        prevWasScope = isScope
      }
    }

    private func isScopeDecl(_ item: some SyntaxProtocol) -> Bool {
      if item.is(ClassDeclSyntax.self) || item.is(StructDeclSyntax.self)
        || item.is(EnumDeclSyntax.self) || item.is(ExtensionDeclSyntax.self)
        || item.is(ProtocolDeclSyntax.self) || item.is(ActorDeclSyntax.self)
      {
        return true
      }
      // Multi-line functions
      if let funcDecl = item.as(FunctionDeclSyntax.self),
        funcDecl.body != nil
      {
        return true
      }
      return false
    }

    private func checkBlankLineBefore(_ node: some SyntaxProtocol) {
      if node.leadingTrivia.newlineCount < 2 {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}
