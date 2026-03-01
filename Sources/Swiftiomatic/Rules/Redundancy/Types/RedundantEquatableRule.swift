import SwiftSyntax

struct RedundantEquatableRule: Rule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "redundant_equatable",
    name: "Redundant Equatable",
    description:
      "Structs conforming to Equatable can rely on synthesized `==` instead of implementing it manually",
    scope: .suggest,
    nonTriggeringExamples: [
      Example(
        """
        struct Foo: Equatable {
          let bar: Int
        }
        """,
      ),
      Example(
        """
        struct Foo: Equatable {
          let bar: Int
          static func == (lhs: Foo, rhs: Foo) -> Bool {
            lhs.bar == rhs.bar && someOtherCondition
          }
        }
        """,
      ),
    ],
    triggeringExamples: [
      Example(
        """
        struct Foo: Equatable {
          let bar: Int
          let baz: String
          ↓static func == (lhs: Foo, rhs: Foo) -> Bool {
            lhs.bar == rhs.bar && lhs.baz == rhs.baz
          }
        }
        """,
      )
    ],
  )
}

extension RedundantEquatableRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<ConfigurationType> {
    Visitor(configuration: configuration, file: file)
  }
}

extension RedundantEquatableRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<ConfigurationType> {
    override func visitPost(_ node: StructDeclSyntax) {
      // Must conform to Equatable
      guard let inheritanceClause = node.inheritanceClause,
        inheritanceClause.inheritedTypes.contains(where: {
          $0.type.trimmedDescription == "Equatable"
        })
      else { return }

      // Find manual == implementation
      for member in node.memberBlock.members {
        guard let funcDecl = member.decl.as(FunctionDeclSyntax.self),
          funcDecl.name.text == "==",
          funcDecl.modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) })
        else { continue }

        violations.append(funcDecl.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}
