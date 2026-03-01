import SwiftSyntax

struct BlankLineAfterImportsRule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "blank_line_after_imports",
    name: "Blank Line After Imports",
    description: "There should be a blank line after import statements",
    scope: .format,
    nonTriggeringExamples: [
      Example(
        """
        import Foundation

        class Foo {}
        """),
      Example(
        """
        import Foundation
        import UIKit

        class Foo {}
        """),
    ],
    triggeringExamples: [
      Example(
        """
        import Foundation
        ↓class Foo {}
        """)
    ],
    corrections: [
      Example("import Foundation\n↓class Foo {}"): Example("import Foundation\n\nclass Foo {}")
    ],
  )
}

extension BlankLineAfterImportsRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: configuration, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: configuration, file: file)
  }
}

extension BlankLineAfterImportsRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: SourceFileSyntax) {
      let statements = node.statements
      var lastImportIndex: SyntaxChildrenIndex?

      for (index, item) in zip(statements.indices, statements) {
        if item.item.is(ImportDeclSyntax.self) {
          lastImportIndex = index
        }
      }

      guard let lastImportIndex else { return }

      // Check if there's a non-import statement after the last import
      let nextIndex = statements.index(after: lastImportIndex)
      guard nextIndex < statements.endIndex else { return }
      let nextItem = statements[nextIndex]

      // Skip if the next item is also an import
      if nextItem.item.is(ImportDeclSyntax.self) { return }

      // Need at least 2 newlines (one for end of import line, one for blank line)
      if nextItem.leadingTrivia.newlineCount < 2 {
        violations.append(nextItem.positionAfterSkippingLeadingTrivia)
      }
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: SourceFileSyntax) -> SourceFileSyntax {
      let statements = node.statements
      var lastImportIndex: SyntaxChildrenIndex?

      for (index, item) in zip(statements.indices, statements) {
        if item.item.is(ImportDeclSyntax.self) {
          lastImportIndex = index
        }
      }

      guard let lastImportIndex else { return super.visit(node) }

      let nextIndex = statements.index(after: lastImportIndex)
      guard nextIndex < statements.endIndex else { return super.visit(node) }
      let nextItem = statements[nextIndex]

      if nextItem.item.is(ImportDeclSyntax.self) { return super.visit(node) }

      if nextItem.leadingTrivia.newlineCount < 2 {
        numberOfCorrections += 1
        let newTrivia = Trivia.newlines(1) + nextItem.leadingTrivia
        let newItem = nextItem.with(\.leadingTrivia, newTrivia)
        var newStatements = Array(statements)
        let arrayIndex = statements.distance(from: statements.startIndex, to: nextIndex)
        newStatements[arrayIndex] = newItem
        let newList = CodeBlockItemListSyntax(newStatements)
        return super.visit(node.with(\.statements, newList))
      }
      return super.visit(node)
    }
  }
}
