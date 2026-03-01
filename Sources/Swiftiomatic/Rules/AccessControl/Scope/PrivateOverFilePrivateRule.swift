import SwiftSyntax

struct PrivateOverFilePrivateRule {
  var configuration = PrivateOverFilePrivateConfiguration()

  static let description = RuleDescription(
    identifier: "private_over_fileprivate",
    name: "Private over Fileprivate",
    description: "Prefer `private` over `fileprivate` declarations",
    nonTriggeringExamples: [
      Example("extension String {}"),
      Example("private extension String {}"),
      Example("public protocol P {}"),
      Example("open extension \n String {}"),
      Example("internal extension String {}"),
      Example("package typealias P = Int"),
      Example(
        """
        extension String {
          fileprivate func Something(){}
        }
        """,
      ),
      Example(
        """
        class MyClass {
          fileprivate let myInt = 4
        }
        """,
      ),
      Example(
        """
        actor MyActor {
          fileprivate let myInt = 4
        }
        """,
      ),
      Example(
        """
        class MyClass {
          fileprivate(set) var myInt = 4
        }
        """,
      ),
      Example(
        """
        struct Outer {
          struct Inter {
            fileprivate struct Inner {}
          }
        }
        """,
      ),
    ],
    triggeringExamples: [
      Example("↓fileprivate enum MyEnum {}"),
      Example(
        """
        ↓fileprivate class MyClass {
          fileprivate(set) var myInt = 4
        }
        """,
      ),
      Example(
        """
        ↓fileprivate actor MyActor {
          fileprivate let myInt = 4
        }
        """,
      ),
      Example(
        """
            ↓fileprivate func f() {}
            ↓fileprivate var x = 0
        """,
      ),
    ],
    corrections: [
      Example("↓fileprivate enum MyEnum {}"):
        Example("private enum MyEnum {}"),
      Example("↓fileprivate enum MyEnum { fileprivate class A {} }"):
        Example("private enum MyEnum { fileprivate class A {} }"),
      Example("↓fileprivate class MyClass { fileprivate(set) var myInt = 4 }"):
        Example("private class MyClass { fileprivate(set) var myInt = 4 }"),
      Example("↓fileprivate actor MyActor { fileprivate(set) var myInt = 4 }"):
        Example("private actor MyActor { fileprivate(set) var myInt = 4 }"),
    ],
  )
}

extension PrivateOverFilePrivateRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: configuration, file: file)
  }
}

extension PrivateOverFilePrivateRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
      .all
    }

    override func visitPost(_ node: ActorDeclSyntax) {
      checkModifier(on: node)
    }

    override func visitPost(_ node: ClassDeclSyntax) {
      checkModifier(on: node)
    }

    override func visitPost(_ node: EnumDeclSyntax) {
      checkModifier(on: node)
    }

    override func visitPost(_ node: ExtensionDeclSyntax) {
      if configuration.validateExtensions {
        checkModifier(on: node)
      }
    }

    override func visitPost(_ node: FunctionDeclSyntax) {
      checkModifier(on: node)
    }

    override func visitPost(_ node: ProtocolDeclSyntax) {
      checkModifier(on: node)
    }

    override func visitPost(_ node: StructDeclSyntax) {
      checkModifier(on: node)
    }

    override func visitPost(_ node: TypeAliasDeclSyntax) {
      checkModifier(on: node)
    }

    override func visitPost(_ node: InitializerDeclSyntax) {
      checkModifier(on: node)
    }

    override func visitPost(_ node: VariableDeclSyntax) {
      checkModifier(on: node)
    }

    private func checkModifier(on node: some WithModifiersSyntax) {
      if let modifier = node.modifiers
        .first(where: { $0.name.tokenKind == .keyword(.fileprivate) })
      {
        violations.append(
          at: modifier.positionAfterSkippingLeadingTrivia,
          correction: .init(
            start: modifier.positionAfterSkippingLeadingTrivia,
            end: modifier.endPositionBeforeTrailingTrivia,
            replacement: "private",
          ),
        )
      }
    }
  }
}
