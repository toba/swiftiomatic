import SwiftSyntax

/// Rule to require all classes to have a deinit method
///
/// An example of when this is useful is if the project does allocation tracking
/// of objects and the deinit should print a message or remove its instance from a
/// list of allocations. Even having an empty deinit method is useful to provide
/// a place to put a breakpoint when chasing down leaks.
struct RequiredDeinitRule {
    static let id = "required_deinit"
    static let name = "Required Deinit"
    static let summary = "Classes should have an explicit deinit method"
    static let isOptIn = true
    static var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                class Apple {
                    deinit { }
                }
                """,
              ),
              Example("enum Banana { }"),
              Example("protocol Cherry { }"),
              Example("struct Damson { }"),
              Example(
                """
                class Outer {
                    deinit { print("Deinit Outer") }
                    class Inner {
                        deinit { print("Deinit Inner") }
                    }
                }
                """,
              ),
            ]
    }
    static var triggeringExamples: [Example] {
        [
              Example("↓class Apple { }"),
              Example("↓class Banana: NSObject, Equatable { }"),
              Example(
                """
                ↓class Cherry {
                    // deinit { }
                }
                """,
              ),
              Example(
                """
                ↓class Damson {
                    func deinitialize() { }
                }
                """,
              ),
              Example(
                """
                class Outer {
                    func hello() -> String { return "outer" }
                    deinit { }
                    ↓class Inner {
                        func hello() -> String { return "inner" }
                    }
                }
                """,
              ),
              Example(
                """
                ↓class Outer {
                    func hello() -> String { return "outer" }
                    class Inner {
                        func hello() -> String { return "inner" }
                        deinit { }
                    }
                }
                """,
              ),
            ]
    }
  var options = SeverityConfiguration<Self>(.warning)

}

extension RequiredDeinitRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension RequiredDeinitRule {}

extension RequiredDeinitRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: ClassDeclSyntax) {
      let visitor = DeinitVisitor(configuration: configuration, file: file)
      if !visitor.walk(tree: node.memberBlock, handler: \.hasDeinit) {
        violations.append(node.classKeyword.positionAfterSkippingLeadingTrivia)
      }
    }
  }

  fileprivate final class DeinitVisitor: ViolationCollectingVisitor<OptionsType> {
    private(set) var hasDeinit = false

    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
      .all
    }

    override func visitPost(_: DeinitializerDeclSyntax) {
      hasDeinit = true
    }
  }
}
