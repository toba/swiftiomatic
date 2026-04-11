import SwiftSyntax

/// Detects mutations on a named collection inside a for-in body
///
/// Walks the loop body looking for calls like `collection.remove(...)` or
/// `collection.append(...)`. Used by both `PerformanceAntiPatternsCheck`
/// (suggest) and `PerformanceAntiPatternsRule` (lint).
final class MutationDuringIterationFinder: SyntaxVisitor {
  private let mutatingPrefixes: [String]

  /// Set to `true` when a mutating call on the tracked collection is found
  var foundMutation = false

  /// Creates a finder that watches for mutations on a specific collection
  ///
  /// - Parameters:
  ///   - collectionName: The identifier of the collection being iterated.
  ///   - viewMode: The syntax tree view mode for traversal.
  init(collectionName: String, viewMode: SyntaxTreeViewMode) {
    mutatingPrefixes = [
      "\(collectionName).remove",
      "\(collectionName).insert",
      "\(collectionName).append",
      "\(collectionName).removeAll",
    ]
    super.init(viewMode: viewMode)
  }

  override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
    let callee = node.calledExpression.trimmedDescription
    if mutatingPrefixes.contains(where: { callee.hasPrefix($0) }) {
      foundMutation = true
    }
    return .visitChildren
  }
}
