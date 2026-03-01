import Foundation
import SwiftSyntax

struct SortImportsRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "sort_imports",
    name: "Sort Imports",
    description: "Import statements should be sorted alphabetically",
    scope: .format,
    nonTriggeringExamples: [
      Example(
        """
        import Bar
        import Foo
        """,
      ),
      Example(
        """
        import Bar
        @testable import Foo
        """,
      ),
    ],
    triggeringExamples: [
      Example(
        """
        ↓import Foo
        import Bar
        """,
      )
    ],
    corrections: [
      Example("↓import Foo\nimport Bar"): Example("import Bar\nimport Foo")
    ],
  )
}

extension SortImportsRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension SortImportsRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: SourceFileSyntax) {
      let imports = collectImportGroups(from: node)
      for group in imports where group.count > 1 {
        let names = group.map(\.moduleName)
        let sorted = names.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        if names != sorted {
          violations.append(group[0].position)
        }
      }
    }

    private func collectImportGroups(from node: SourceFileSyntax) -> [[ImportInfo]] {
      var groups: [[ImportInfo]] = []
      var currentGroup: [ImportInfo] = []

      for statement in node.statements {
        if let importDecl = statement.item.as(ImportDeclSyntax.self) {
          let moduleName = importDecl.moduleName
          currentGroup.append(
            ImportInfo(
              moduleName: moduleName,
              position: importDecl.importKeyword.positionAfterSkippingLeadingTrivia,
            ))
        } else if !currentGroup.isEmpty {
          groups.append(currentGroup)
          currentGroup = []
        }
      }

      if !currentGroup.isEmpty {
        groups.append(currentGroup)
      }

      return groups
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: SourceFileSyntax) -> SourceFileSyntax {
      var statements = Array(node.statements)
      var modified = false

      // Find contiguous import groups and sort them
      var i = 0
      while i < statements.count {
        let groupStart = i
        while i < statements.count, statements[i].item.is(ImportDeclSyntax.self) {
          i += 1
        }
        let groupEnd = i

        if groupEnd - groupStart > 1 {
          var group = Array(statements[groupStart..<groupEnd])
          let sorted = group.sorted { lhs, rhs in
            let lhsName = lhs.item.as(ImportDeclSyntax.self)?.moduleName ?? ""
            let rhsName = rhs.item.as(ImportDeclSyntax.self)?.moduleName ?? ""
            return lhsName.localizedCaseInsensitiveCompare(rhsName) == .orderedAscending
          }

          // Preserve leading trivia from original positions
          for j in 0..<group.count {
            let originalTrivia = group[j].leadingTrivia
            var sortedItem = sorted[j]
            sortedItem = sortedItem.with(\.leadingTrivia, originalTrivia)
            group[j] = sortedItem
          }

          let originalNames = statements[groupStart..<groupEnd].map {
            $0.item.as(ImportDeclSyntax.self)?.moduleName ?? ""
          }
          let sortedNames = group.map {
            $0.item.as(ImportDeclSyntax.self)?.moduleName ?? ""
          }

          if originalNames != sortedNames {
            for (offset, item) in group.enumerated() {
              statements[groupStart + offset] = item
            }
            modified = true
            numberOfCorrections += 1
          }
        }

        if i == groupStart { i += 1 }
      }

      guard modified else { return super.visit(node) }
      return super.visit(
        node.with(\.statements, CodeBlockItemListSyntax(statements)),
      )
    }
  }

  private struct ImportInfo {
    let moduleName: String
    let position: AbsolutePosition
  }
}

extension ImportDeclSyntax {
  fileprivate var moduleName: String {
    path.map(\.name.text).joined(separator: ".")
  }
}
