import SwiftSyntax

struct EnumNamespacesRule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "enum_namespaces",
    name: "Enum Namespaces",
    description:
      "Types hosting only static members should be enums to prevent instantiation",
    scope: .suggest,
    nonTriggeringExamples: [
      Example(
        """
        enum Constants {
          static let foo = "foo"
        }
        """,
      ),
      Example(
        """
        struct Foo {
          let bar: Int
        }
        """,
      ),
      Example(
        """
        struct Foo {
          static let bar = 1
          init() {}
        }
        """,
      ),
    ],
    triggeringExamples: [
      Example(
        """
        ↓struct Constants {
          static let foo = "foo"
          static let bar = "bar"
        }
        """,
      ),
      Example(
        """
        final ↓class Constants {
          static let foo = "foo"
        }
        """,
      ),
    ],
  )
}

extension EnumNamespacesRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: configuration, file: file)
  }
}

extension EnumNamespacesRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: StructDeclSyntax) {
      checkNamespace(
        keyword: node.structKeyword, members: node.memberBlock.members,
        inheritanceClause: node.inheritanceClause, attributes: node.attributes)
    }

    override func visitPost(_ node: ClassDeclSyntax) {
      // Only check final classes
      guard node.modifiers.contains(where: { $0.name.tokenKind == .keyword(.final) }) else {
        return
      }
      checkNamespace(
        keyword: node.classKeyword, members: node.memberBlock.members,
        inheritanceClause: node.inheritanceClause, attributes: node.attributes)
    }

    private func checkNamespace(
      keyword: TokenSyntax,
      members: MemberBlockItemListSyntax,
      inheritanceClause: InheritanceClauseSyntax?,
      attributes: AttributeListSyntax,
    ) {
      // Skip if has conformances
      if let inheritanceClause, !inheritanceClause.inheritedTypes.isEmpty {
        return
      }

      // Skip if has attributes
      guard attributes.isEmpty else { return }

      // Must have at least one member
      guard !members.isEmpty else { return }

      // All members must be static (no init, no instance members)
      for member in members {
        if let initDecl = member.decl.as(InitializerDeclSyntax.self) {
          _ = initDecl
          return
        }

        if let funcDecl = member.decl.as(FunctionDeclSyntax.self) {
          guard funcDecl.modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) })
          else { return }
        } else if let varDecl = member.decl.as(VariableDeclSyntax.self) {
          guard varDecl.modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) })
          else { return }
        } else if let typeDecl = member.decl.as(TypeAliasDeclSyntax.self) {
          _ = typeDecl  // typealiases are fine
        } else if member.decl.is(EnumDeclSyntax.self)
          || member.decl.is(StructDeclSyntax.self)
          || member.decl.is(ClassDeclSyntax.self)
        {
          // nested types are fine
        } else if let subscriptDecl = member.decl.as(SubscriptDeclSyntax.self) {
          guard subscriptDecl.modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) })
          else { return }
        } else {
          // Unknown member type, skip
          continue
        }
      }

      violations.append(keyword.positionAfterSkippingLeadingTrivia)
    }
  }
}
