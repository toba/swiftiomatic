import SwiftSyntax

struct PrivateOverFilePrivateRule {
    static let id = "private_over_fileprivate"
    static let name = "Private over Fileprivate"
    static let summary = "Prefer `private` over `fileprivate` declarations"
    static let isCorrectable = true
    static var nonTriggeringExamples: [Example] {
        [
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
            ]
    }
    static var triggeringExamples: [Example] {
        [
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
            ]
    }
    static var corrections: [Example: Example] {
        [
              Example("↓fileprivate enum MyEnum {}"):
                Example("private enum MyEnum {}"),
              Example("↓fileprivate enum MyEnum { fileprivate class A {} }"):
                Example("private enum MyEnum { fileprivate class A {} }"),
              Example("↓fileprivate class MyClass { fileprivate(set) var myInt = 4 }"):
                Example("private class MyClass { fileprivate(set) var myInt = 4 }"),
              Example("↓fileprivate actor MyActor { fileprivate(set) var myInt = 4 }"):
                Example("private actor MyActor { fileprivate(set) var myInt = 4 }"),
            ]
    }
  var options = PrivateOverFilePrivateOptions()

}

extension PrivateOverFilePrivateRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
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
