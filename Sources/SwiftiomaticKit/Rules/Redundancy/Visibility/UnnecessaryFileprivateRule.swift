import SwiftSyntax

struct UnnecessaryFileprivateRule {
  static let id = "unnecessary_fileprivate"
  static let name = "Unnecessary Fileprivate"
  static let summary =
    "`fileprivate` can be replaced with `private` when only accessed within the same declaration scope"
  static let scope: Scope = .suggest
  static let deprecatedAliases: Set<String> = ["redundant_fileprivate"]
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
        class Foo {
          fileprivate func helper() {}
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

  var options = SeverityOption<Self>(.warning)
}

extension UnnecessaryFileprivateRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension UnnecessaryFileprivateRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: DeclModifierSyntax) {
      guard node.name.tokenKind == .keyword(.fileprivate), node.detail == nil else { return }

      // If this is a top-level (file-scope) declaration, fileprivate == private
      guard let parentDecl = node.parent?.parent else { return }

      // Check if the declaration is at file scope
      // Tree: SourceFileSyntax > CodeBlockItemListSyntax > CodeBlockItemSyntax > Decl
      if parentDecl.parent?.is(CodeBlockItemSyntax.self) == true,
        parentDecl.parent?.parent?.parent?.is(SourceFileSyntax.self) == true
      {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}
