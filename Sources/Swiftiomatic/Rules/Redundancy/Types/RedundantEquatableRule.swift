import SwiftSyntax

struct RedundantEquatableRule {
    static let id = "redundant_equatable"
    static let name = "Redundant Equatable"
    static let summary = "Structs conforming to Equatable can rely on synthesized `==` instead of implementing it manually"
    static let scope: Scope = .suggest
    static var nonTriggeringExamples: [Example] {
        [
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
            ]
    }
    static var triggeringExamples: [Example] {
        [
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
            ]
    }
  var options = SeverityConfiguration<Self>(.warning)

}

extension RedundantEquatableRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension RedundantEquatableRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
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
