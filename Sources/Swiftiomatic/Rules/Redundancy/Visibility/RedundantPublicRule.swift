import SwiftSyntax

struct RedundantPublicRule: Rule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "redundant_public",
    name: "Redundant Public",
    description: "`public` on members of internal types has no effect",
    scope: .suggest,
    nonTriggeringExamples: [
      Example(
        """
        public class Foo {
          public func bar() {}
        }
        """,
      ),
      Example(
        """
        class Foo {
          func bar() {}
        }
        """,
      ),
    ],
    triggeringExamples: [
      Example(
        """
        class Foo {
          ↓public func bar() {}
        }
        """,
      ),
      Example(
        """
        struct Foo {
          ↓public let bar: String
        }
        """,
      ),
    ],
  )
}

extension RedundantPublicRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<ConfigurationType> {
    Visitor(configuration: configuration, file: file)
  }
}

extension RedundantPublicRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<ConfigurationType> {
    override func visitPost(_ node: DeclModifierSyntax) {
      guard node.name.tokenKind == .keyword(.public), node.detail == nil else { return }

      // Check if the parent type is not public
      guard let typeDecl = node.nearestEnclosingTypeDecl,
        !typeDecl.isPublicOrOpen
      else { return }

      violations.append(node.positionAfterSkippingLeadingTrivia)
    }
  }
}

extension DeclModifierSyntax {
  fileprivate var nearestEnclosingTypeDecl: (any DeclGroupSyntax)? {
    var current: Syntax? = Syntax(self)
    while let parent = current?.parent {
      if parent.asProtocol(DeclGroupSyntax.self) != nil,
        parent.is(ClassDeclSyntax.self) || parent.is(StructDeclSyntax.self)
          || parent.is(EnumDeclSyntax.self) || parent.is(ActorDeclSyntax.self)
      {
        return parent.asProtocol(DeclGroupSyntax.self)
      }
      current = parent
    }
    return nil
  }
}

extension DeclGroupSyntax {
  fileprivate var isPublicOrOpen: Bool {
    modifiers.contains { modifier in
      modifier.name.tokenKind == .keyword(.public) || modifier.name.tokenKind == .keyword(.open)
    }
  }
}
