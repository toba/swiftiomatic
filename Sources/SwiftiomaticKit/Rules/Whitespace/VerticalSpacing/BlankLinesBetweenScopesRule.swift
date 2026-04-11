import SwiftSyntax

struct BlankLinesBetweenScopesRule {
  static let id = "blank_lines_between_scopes"
  static let name = "Blank Lines Between Scopes"
  static let summary =
    "There should be a blank line before type declarations and multi-line functions"
  static let scope: Scope = .format
  static var nonTriggeringExamples: [Example] {
    [
      Example(
        """
        class Foo {}

        class Bar {}
        """,
      ),
      Example(
        """
        func foo() {
          // foo
        }

        func bar() {
          // bar
        }
        """,
      ),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example(
        """
        class Foo {}
        ↓class Bar {}
        """,
      )
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension BlankLinesBetweenScopesRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
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
