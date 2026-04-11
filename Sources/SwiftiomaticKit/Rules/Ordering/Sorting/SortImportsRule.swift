import Foundation
import SwiftSyntax

struct SortImportsRule {
  static let id = "sort_imports"
  static let name = "Sort Imports"
  static let summary = "Import statements should be sorted"
  static let scope: Scope = .format
  static let isCorrectable = true
  static var nonTriggeringExamples: [Example] {
    [
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
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example(
        """
        ↓import Foo
        import Bar
        """,
      )
    ]
  }

  static var corrections: [Example: Example] {
    [:]
  }

  var options = SortImportsOptions()
}

extension SortImportsRule: SwiftSyntaxRule {
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
      let groups = SortImportsRule.collectImportGroups(from: node, grouping: configuration.grouping)
      let comparator = SortImportsRule.importComparator(for: configuration.sortOrder)
      for group in groups where group.count > 1 {
        let names = group.map(\.moduleName)
        let sorted = names.sorted(by: comparator)
        if names != sorted {
          violations.append(group[0].position)
        }
      }
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: SourceFileSyntax) -> SourceFileSyntax {
      var statements = Array(node.statements)
      var modified = false
      let comparator = SortImportsRule.importComparator(for: configuration.sortOrder)
      let grouping = configuration.grouping

      // Find import ranges, then split into groups respecting the grouping mode
      var i = 0
      while i < statements.count {
        // Skip non-imports
        guard statements[i].item.is(ImportDeclSyntax.self) else {
          i += 1
          continue
        }

        // Collect the full run of consecutive import statements
        let runStart = i
        i += 1
        while i < statements.count, statements[i].item.is(ImportDeclSyntax.self) {
          i += 1
        }

        // Split the run into groups based on grouping mode
        let subgroups = SortImportsRule.splitIntoGroups(
          statements[runStart..<i], grouping: grouping
        )

        for subgroup in subgroups where subgroup.count > 1 {
          let groupStart = subgroup.startIndex
          var group = Array(subgroup)
          let sorted = group.sorted { lhs, rhs in
            let lhsName = lhs.item.as(ImportDeclSyntax.self)?.moduleName ?? ""
            let rhsName = rhs.item.as(ImportDeclSyntax.self)?.moduleName ?? ""
            return comparator(lhsName, rhsName)
          }

          // Preserve leading trivia from original positions
          for j in 0..<group.count {
            let originalTrivia = group[j].leadingTrivia
            var sortedItem = sorted[j]
            sortedItem = sortedItem.with(\.leadingTrivia, originalTrivia)
            group[j] = sortedItem
          }

          let originalNames = subgroup.map {
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
      }

      guard modified else { return super.visit(node) }
      return super.visit(
        node.with(\.statements, CodeBlockItemListSyntax(statements)),
      )
    }
  }

  fileprivate struct ImportInfo {
    let moduleName: String
    let position: AbsolutePosition
  }

  // MARK: - Grouping

  /// Collect import groups from a source file, respecting the grouping mode.
  fileprivate static func collectImportGroups(
    from node: SourceFileSyntax, grouping: ImportGrouping
  ) -> [[ImportInfo]] {
    var allGroups: [[ImportInfo]] = []
    var currentRun: [ImportInfo] = []
    var previousWasImport = false

    for statement in node.statements {
      if let importDecl = statement.item.as(ImportDeclSyntax.self) {
        let info = ImportInfo(
          moduleName: importDecl.moduleName,
          position: importDecl.importKeyword.positionAfterSkippingLeadingTrivia,
        )

        if previousWasImport, grouping == .contiguous,
          hasGroupBreak(in: statement.leadingTrivia)
        {
          // Blank line or comment breaks the group in contiguous mode
          if !currentRun.isEmpty { allGroups.append(currentRun) }
          currentRun = [info]
        } else {
          currentRun.append(info)
        }
        previousWasImport = true
      } else {
        if !currentRun.isEmpty { allGroups.append(currentRun) }
        currentRun = []
        previousWasImport = false
      }
    }

    if !currentRun.isEmpty { allGroups.append(currentRun) }
    return allGroups
  }

  /// Split a contiguous run of import statements into subgroups based on the grouping mode.
  fileprivate static func splitIntoGroups(
    _ run: ArraySlice<CodeBlockItemListSyntax.Element>, grouping: ImportGrouping
  ) -> [ArraySlice<CodeBlockItemListSyntax.Element>] {
    guard grouping == .contiguous, run.count > 1 else {
      return [run]
    }

    var subgroups: [ArraySlice<CodeBlockItemListSyntax.Element>] = []
    var groupStart = run.startIndex

    for idx in run.indices.dropFirst() {
      if hasGroupBreak(in: run[idx].leadingTrivia) {
        subgroups.append(run[groupStart..<idx])
        groupStart = idx
      }
    }
    subgroups.append(run[groupStart..<run.endIndex])
    return subgroups
  }

  /// Check whether leading trivia contains a blank line or a comment, indicating a visual group break.
  fileprivate static func hasGroupBreak(in trivia: Trivia) -> Bool {
    var newlineCount = 0
    for piece in trivia {
      switch piece {
      case .newlines(let n):
        newlineCount += n
      case .carriageReturns(let n):
        newlineCount += n
      case .carriageReturnLineFeeds(let n):
        newlineCount += n
      case .lineComment, .blockComment, .docLineComment, .docBlockComment:
        return true
      default:
        break
      }
    }
    // Two or more newlines means at least one blank line between imports
    return newlineCount >= 2
  }

  /// Build a comparator for import module names based on the configured sort order.
  fileprivate static func importComparator(for order: ImportSortOrder) -> (String, String) -> Bool {
    switch order {
    case .alphabetical:
      { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    case .length:
      { lhs, rhs in
        if lhs.count != rhs.count { return lhs.count < rhs.count }
        return lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
      }
    }
  }
}

extension ImportDeclSyntax {
  fileprivate var moduleName: String {
    path.map(\.name.text).joined(separator: ".")
  }
}
