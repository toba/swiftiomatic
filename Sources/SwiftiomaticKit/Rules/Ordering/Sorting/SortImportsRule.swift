import Foundation
import SwiftiomaticSyntax

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
      Example(
        """
        import Bar
        import Foo

        @testable import Baz
        """,
        configuration: ["group_attributed_imports": true],
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
  /// Classification of imports by their leading attribute.
  fileprivate enum ImportKind: Int, Comparable {
    case regular = 0
    case implementationOnly = 1
    case testable = 2

    static func < (lhs: ImportKind, rhs: ImportKind) -> Bool {
      lhs.rawValue < rhs.rawValue
    }
  }

  /// Classify an import declaration by its leading attribute.
  fileprivate static func importKind(of decl: ImportDeclSyntax) -> ImportKind {
    for attr in decl.attributes {
      guard let identAttr = attr.as(AttributeSyntax.self) else { continue }
      let name = identAttr.attributeName.trimmedDescription
      if name == "_implementationOnly" { return .implementationOnly }
      if name == "testable" { return .testable }
    }
    return .regular
  }

  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: SourceFileSyntax) {
      if configuration.groupAttributedImports {
        visitGroupedByAttribute(node)
      } else {
        visitDefault(node)
      }
    }

    private func visitDefault(_ node: SourceFileSyntax) {
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

    private func visitGroupedByAttribute(_ node: SourceFileSyntax) {
      let groups = SortImportsRule.collectImportGroups(from: node, grouping: configuration.grouping)
      let comparator = SortImportsRule.importComparator(for: configuration.sortOrder)

      for group in groups where group.count > 1 {
        // Check that imports are ordered by kind, then alphabetically within each kind
        let kinds = group.map(\.kind)
        let sortedKinds = kinds.sorted()
        if kinds != sortedKinds {
          violations.append(group[0].position)
          continue
        }
        // Within each kind subgroup, check alphabetical order
        let kindSubgroups = Dictionary(grouping: group, by: \.kind)
        for (_, subgroup) in kindSubgroups where subgroup.count > 1 {
          let names = subgroup.map(\.moduleName)
          let sorted = names.sorted(by: comparator)
          if names != sorted {
            violations.append(subgroup[0].position)
          }
        }
      }
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: SourceFileSyntax) -> SourceFileSyntax {
      if configuration.groupAttributedImports {
        return visitGroupedByAttribute(node)
      }
      return visitDefault(node)
    }

    private func visitDefault(_ node: SourceFileSyntax) -> SourceFileSyntax {
      var statements = Array(node.statements)
      var modified = false
      let comparator = SortImportsRule.importComparator(for: configuration.sortOrder)
      let grouping = configuration.grouping

      var i = 0
      while i < statements.count {
        guard statements[i].item.is(ImportDeclSyntax.self) else {
          i += 1
          continue
        }

        let runStart = i
        i += 1
        while i < statements.count, statements[i].item.is(ImportDeclSyntax.self) {
          i += 1
        }

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

    private func visitGroupedByAttribute(_ node: SourceFileSyntax) -> SourceFileSyntax {
      var statements = Array(node.statements)
      var modified = false
      let comparator = SortImportsRule.importComparator(for: configuration.sortOrder)

      var i = 0
      while i < statements.count {
        guard statements[i].item.is(ImportDeclSyntax.self) else {
          i += 1
          continue
        }

        let runStart = i
        i += 1
        while i < statements.count, statements[i].item.is(ImportDeclSyntax.self) {
          i += 1
        }

        let run = Array(statements[runStart..<i])

        // Sort by kind first, then alphabetically within each kind
        let sorted = run.sorted { lhs, rhs in
          let lhsDecl = lhs.item.as(ImportDeclSyntax.self)!
          let rhsDecl = rhs.item.as(ImportDeclSyntax.self)!
          let lhsKind = SortImportsRule.importKind(of: lhsDecl)
          let rhsKind = SortImportsRule.importKind(of: rhsDecl)
          if lhsKind != rhsKind { return lhsKind < rhsKind }
          return comparator(lhsDecl.moduleName, rhsDecl.moduleName)
        }

        // Preserve leading trivia, but insert blank line between kind groups
        var result = [CodeBlockItemSyntax]()
        var prevKind: ImportKind?
        for (j, item) in sorted.enumerated() {
          let kind = SortImportsRule.importKind(of: item.item.as(ImportDeclSyntax.self)!)
          var stmt = item
          if j < run.count {
            // Start with the original position's trivia
            stmt = stmt.with(\.leadingTrivia, run[j].leadingTrivia)
          }
          // Insert blank line at kind boundaries (except for the first item)
          if let prev = prevKind, prev != kind {
            let existingTrivia = stmt.leadingTrivia
            let hasBlankLine = SortImportsRule.hasGroupBreak(in: existingTrivia)
            if !hasBlankLine {
              stmt = stmt.with(\.leadingTrivia, .newlines(1) + existingTrivia)
            }
          }
          prevKind = kind
          result.append(stmt)
        }

        let originalModules = run.map { $0.item.as(ImportDeclSyntax.self)?.moduleName ?? "" }
        let sortedModules = result.map { $0.item.as(ImportDeclSyntax.self)?.moduleName ?? "" }

        if originalModules != sortedModules {
          for (offset, item) in result.enumerated() {
            statements[runStart + offset] = item
          }
          modified = true
          numberOfCorrections += 1
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
    let kind: ImportKind
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
          kind: importKind(of: importDecl),
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
