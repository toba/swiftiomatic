import SwiftSyntax

/// Detects fire-and-forget `Task {}` patterns where the result is discarded
///
/// Used by both `FireAndForgetTaskCheck` (suggest) and `FireAndForgetTaskRule` (lint).
enum TaskPatternDetector {
  /// Whether the function call is the direct child of a return statement
  ///
  /// - Parameters:
  ///   - node: The function call expression to inspect.
  /// - Returns: `true` if the node's parent is a `ReturnStmtSyntax`.
  static func isReturned(_ node: FunctionCallExprSyntax) -> Bool {
    node.parent?.is(ReturnStmtSyntax.self) == true
  }

  /// Whether the Task result is assigned to a variable or binding
  ///
  /// Walks the parent chain to find initializer clauses, pattern bindings,
  /// or assignment operators.
  ///
  /// - Parameters:
  ///   - node: The function call expression to inspect.
  /// - Returns: `true` if the call result is captured in a binding or assignment.
  static func isAssigned(_ node: FunctionCallExprSyntax) -> Bool {
    var current: Syntax? = Syntax(node)

    while let parent = current?.parent {
      if parent.is(InitializerClauseSyntax.self) || parent.is(PatternBindingSyntax.self) {
        return true
      }

      if let infixOp = parent.as(InfixOperatorExprSyntax.self),
        infixOp.operator.is(AssignmentExprSyntax.self)
      {
        return true
      }

      if parent.is(CodeBlockItemSyntax.self) || parent.is(MemberBlockItemSyntax.self) {
        break
      }

      current = parent
    }

    return false
  }

  /// The kind of scope enclosing a `Task` call
  enum EnclosingScope: CustomStringConvertible {
    case `deinit`
    case viewDidDisappear
    case general

    var description: String {
      switch self {
      case .deinit: "deinit"
      case .viewDidDisappear: "viewDidDisappear"
      case .general: "general scope"
      }
    }
  }

  /// Walks the parent chain to determine the enclosing scope of a node
  ///
  /// - Parameters:
  ///   - node: The syntax node to inspect.
  /// - Returns: The ``EnclosingScope`` that contains the node.
  static func enclosingScope(of node: some SyntaxProtocol) -> EnclosingScope {
    var current: Syntax? = Syntax(node)

    while let parent = current?.parent {
      if parent.is(DeinitializerDeclSyntax.self) { return .deinit }
      if let funcDecl = parent.as(FunctionDeclSyntax.self),
        funcDecl.name.text == "viewDidDisappear"
      {
        return .viewDidDisappear
      }
      if parent.is(ClassDeclSyntax.self) || parent.is(StructDeclSyntax.self)
        || parent.is(EnumDeclSyntax.self) || parent.is(ActorDeclSyntax.self)
      {
        break
      }
      current = parent
    }

    return .general
  }

  /// Whether a closure body contains a `Task {}` or `Task.detached {}` call
  ///
  /// - Parameters:
  ///   - closure: The closure expression to search.
  /// - Returns: `true` if a Task call is found anywhere in the closure subtree.
  static func closureContainsTask(_ closure: ClosureExprSyntax) -> Bool {
    let finder = TaskFinder(viewMode: .sourceAccurate)
    finder.walk(closure)
    return finder.foundTask
  }
}

/// A lightweight visitor that checks whether a syntax subtree contains a `Task {}` call
final class TaskFinder: SyntaxVisitor {
  /// Set to `true` when a `Task` or `Task.detached` call is found
  var foundTask = false

  override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
    let callee = node.calledExpression.trimmedDescription
    if callee == "Task" || callee == "Task.detached" {
      foundTask = true
      return .skipChildren
    }
    return .visitChildren
  }
}
