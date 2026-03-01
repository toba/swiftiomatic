import SwiftSyntax

struct RedundantStaticSelfRule: Rule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "redundant_static_self",
    name: "Redundant Static Self",
    description: "Explicit `Self` qualification is redundant in static context",
    scope: .format,
    nonTriggeringExamples: [
      Example(
        """
        struct Foo {
          static let bar = "bar"
          func baz() {
            let _ = Self.bar
          }
        }
        """,
      ),
      Example(
        """
        class Foo {
          static func bar() -> Self { Self() }
        }
        """,
      ),
    ],
    triggeringExamples: [
      Example(
        """
        struct Foo {
          static let bar = "bar"
          static func baz() -> String {
            return ↓Self.bar
          }
        }
        """,
      )
    ],
  )
}

extension RedundantStaticSelfRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<ConfigurationType> {
    Visitor(configuration: configuration, file: file)
  }
}

extension RedundantStaticSelfRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<ConfigurationType> {
    override func visitPost(_ node: MemberAccessExprSyntax) {
      // Looking for `Self.something` in a static context
      guard let base = node.base?.as(DeclReferenceExprSyntax.self),
        base.baseName.text == "Self"
      else { return }

      // Check if we're in a static context
      guard isInStaticContext(node) else { return }

      // Don't flag `Self` when used as a return type (Self() construction)
      if node.declName.baseName.text == "init" { return }

      violations.append(base.positionAfterSkippingLeadingTrivia)
    }

    private func isInStaticContext(_ node: some SyntaxProtocol) -> Bool {
      var current: Syntax? = Syntax(node)
      while let parent = current?.parent {
        if let funcDecl = parent.as(FunctionDeclSyntax.self) {
          return funcDecl.modifiers.contains { $0.name.tokenKind == .keyword(.static) }
        }
        if let varDecl = parent.as(VariableDeclSyntax.self) {
          return varDecl.modifiers.contains { $0.name.tokenKind == .keyword(.static) }
        }
        if parent.is(ClassDeclSyntax.self) || parent.is(StructDeclSyntax.self)
          || parent.is(EnumDeclSyntax.self)
        {
          return false
        }
        current = parent
      }
      return false
    }
  }
}
