import SwiftSyntax

struct RedundantFileprivateRule {
    static let id = "redundant_fileprivate"
    static let name = "Redundant Fileprivate"
    static let summary = "`fileprivate` can be replaced with `private` when only accessed within the same declaration scope"
    static let scope: Scope = .suggest
    static var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                class Foo {
                  private var bar: Int
                }
                """,
              ),
              Example(
                """
                fileprivate func helper() {}
                class Foo {
                  func bar() { helper() }
                }
                """,
              ),
            ]
    }
    static var triggeringExamples: [Example] {
        [
              Example(
                """
                ↓fileprivate class Foo {}
                """,
              )
            ]
    }
  var options = SeverityConfiguration<Self>(.warning)

}

extension RedundantFileprivateRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension RedundantFileprivateRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: DeclModifierSyntax) {
      guard node.name.tokenKind == .keyword(.fileprivate), node.detail == nil else { return }

      // If this is a top-level (file-scope) declaration, fileprivate == private
      guard let parentDecl = node.parent?.parent else { return }

      // Check if the declaration is at file scope
      if parentDecl.parent?.is(CodeBlockItemListSyntax.self) == true,
        parentDecl.parent?.parent?.is(SourceFileSyntax.self) == true
      {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}
