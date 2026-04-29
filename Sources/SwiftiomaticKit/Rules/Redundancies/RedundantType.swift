import SwiftSyntax

/// Remove redundant type annotations when the type is obvious from the initializer.
///
/// A type annotation is redundant when it exactly matches what the compiler would infer,
/// such as `let x: Foo = Foo(...)` or `let x: Bool = true`.
///
/// This rule fires for:
/// - Constructor calls matching the annotation: `let x: Foo = Foo(...)` → `let x = Foo(...)`
/// - Generic constructors: `let x: Foo<Int> = Foo<Int>(...)` → `let x = Foo<Int>(...)`
/// - Array/Dictionary constructors: `var x: [String] = [String]()` → `var x = [String]()`
/// - Boolean literals: `let x: Bool = true` → `let x = true`
/// - String literals: `let x: String = "hello"` → `let x = "hello"`
/// - if/switch expressions where all branches match: `let x: Foo = if c { Foo() } else { Foo() }`
///
/// It does NOT fire for:
/// - Numeric literals (which could be Int, Double, Float, etc.)
/// - Collection literals (which could be Array, Set, etc.)
/// - `Void` types (removing the annotation is unhelpful)
///
/// Lint: If a redundant type annotation is found, a lint warning is raised.
///
/// Rewrite: The redundant type annotation is removed.
final class RedundantType: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
  override class var group: ConfigurationGroup? { .redundancies }

  static func transform(
    _ node: VariableDeclSyntax,
    parent: Syntax?,
    context: Context
  ) -> DeclSyntax {
    var bindings = node.bindings
    var didChange = false

    for (index, binding) in bindings.enumerated() {
      guard let typeAnnotation = binding.typeAnnotation,
        let initializer = binding.initializer
      else {
        continue
      }

      let typeName = typeAnnotation.type.trimmedDescription

      // Skip Void types — removing the annotation is unhelpful.
      guard !isVoidType(typeName) else { continue }

      guard isRedundant(typeName: typeName, initializer: initializer.value) else {
        continue
      }

      Self.diagnose(.removeRedundantType(typeName: typeName), on: typeAnnotation, context: context)

      var newBinding = binding
      newBinding.typeAnnotation = nil

      // Transfer any comments from the type annotation's trailing trivia to
      // the `=` token's leading trivia. Without this, `var x: T /* c */ = val`
      // would lose the comment when the annotation is removed.
      var newInitializer = initializer
      let typeTrailingTrivia = typeAnnotation.type.trailingTrivia
      if typeTrailingTrivia.hasAnyComments {
        // Preserve the comment: `var x /* c */ = val`
        newInitializer.equal.leadingTrivia = typeTrailingTrivia
      } else if initializer.equal.leadingTrivia.isEmpty {
        newInitializer.equal.leadingTrivia = .space
      }
      newBinding.initializer = newInitializer

      bindings = bindings.with(
        \.[bindings.index(bindings.startIndex, offsetBy: index)], newBinding)
      didChange = true
    }

    guard didChange else { return DeclSyntax(node) }

    var result = node
    result.bindings = bindings
    return DeclSyntax(result)
  }

  /// Returns `true` if the type annotation is redundant given the initializer expression.
  private static func isRedundant(typeName: String, initializer: ExprSyntax) -> Bool {
    // `let x: Foo = Foo(...)` or `let x: Foo = Foo.init(...)`
    if let funcCall = initializer.as(FunctionCallExprSyntax.self) {
      if let calledName = simpleTypeName(from: funcCall.calledExpression) {
        return calledName == typeName
      }
    }

    // `let x: Bool = true/false`
    if initializer.is(BooleanLiteralExprSyntax.self) {
      return typeName == "Bool"
    }

    // `let x: String = "..."`
    if initializer.is(StringLiteralExprSyntax.self) {
      return typeName == "String"
    }

    // `let x: Foo = if condition { Foo(...) } else { Foo(...) }`
    if let ifExpr = initializer.as(IfExprSyntax.self) {
      return allBranchesMatch(typeName: typeName, ifExpr: ifExpr)
    }

    // `let x: Foo = switch value { case ...: Foo(...) ... }`
    if let switchExpr = initializer.as(SwitchExprSyntax.self) {
      return allCasesMatch(typeName: typeName, switchExpr: switchExpr)
    }

    return false
  }

  // MARK: - if/switch expression branch matching

  /// Returns `true` if all branches of an if expression produce values matching the type name.
  private static func allBranchesMatch(typeName: String, ifExpr: IfExprSyntax) -> Bool {
    // Check the `then` body
    guard allStatementsMatch(typeName: typeName, body: ifExpr.body) else { return false }

    // Check the `else` clause
    switch ifExpr.elseBody {
    case .ifExpr(let nestedIf):
      return allBranchesMatch(typeName: typeName, ifExpr: nestedIf)
    case .codeBlock(let codeBlock):
      return allStatementsMatch(typeName: typeName, body: codeBlock)
    case nil:
      return false  // if-expression without else isn't a complete expression
    }
  }

  /// Returns `true` if all cases of a switch expression produce values matching the type name.
  private static func allCasesMatch(typeName: String, switchExpr: SwitchExprSyntax) -> Bool {
    guard !switchExpr.cases.isEmpty else { return false }

    for caseItem in switchExpr.cases {
      switch caseItem {
      case .switchCase(let switchCase):
        guard allStatementsMatch(typeName: typeName, statements: switchCase.statements) else {
          return false
        }
      case .ifConfigDecl:
        // #if blocks are too complex to analyze
        return false
      }
    }
    return true
  }

  /// Returns `true` if the last expression in a code block matches the type name.
  private static func allStatementsMatch(typeName: String, body: CodeBlockSyntax) -> Bool {
    allStatementsMatch(typeName: typeName, statements: body.statements)
  }

  /// Returns `true` if the last expression in a statement list matches the type name.
  private static func allStatementsMatch(typeName: String, statements: CodeBlockItemListSyntax) -> Bool {
    guard let lastItem = statements.last else { return false }

    // Extract the expression from the code block item. In statement position, if/switch
    // may not be directly accessible via .as(ExprSyntax.self), so check specific types too.
    for child in lastItem.children(viewMode: .sourceAccurate) {
      if let ifExpr = child.as(IfExprSyntax.self) {
        return allBranchesMatch(typeName: typeName, ifExpr: ifExpr)
      }
      if let switchExpr = child.as(SwitchExprSyntax.self) {
        return allCasesMatch(typeName: typeName, switchExpr: switchExpr)
      }
      if let expr = child.as(ExprSyntax.self) {
        return isRedundant(typeName: typeName, initializer: expr)
      }
    }
    return false
  }

  // MARK: - Type name extraction

  /// Extracts the simple type name from a called expression, if it's a direct type reference.
  ///
  /// Returns `nil` for complex expressions like method calls, closures, etc.
  private static func simpleTypeName(from expr: ExprSyntax) -> String? {
    // `Foo(...)` — DeclReferenceExpr with no argument names
    if let declRef = expr.as(DeclReferenceExprSyntax.self),
      declRef.argumentNames == nil
    {
      return declRef.baseName.text
    }

    // `Foo.init(...)` — MemberAccessExpr where declName is `init`
    if let memberAccess = expr.as(MemberAccessExprSyntax.self),
      memberAccess.declName.baseName.tokenKind == .keyword(.`init`),
      let base = memberAccess.base
    {
      return base.trimmedDescription
    }

    // `Module.Foo(...)` — MemberAccessExpr where declName is the type
    if let memberAccess = expr.as(MemberAccessExprSyntax.self),
      memberAccess.declName.baseName.tokenKind != .keyword(.`init`)
    {
      return memberAccess.trimmedDescription
    }

    // `Foo<Bar>(...)` — GenericSpecializationExpr
    if let generic = expr.as(GenericSpecializationExprSyntax.self) {
      return generic.trimmedDescription
    }

    // `[String](...)` — ArrayExpr used as constructor
    if let array = expr.as(ArrayExprSyntax.self) {
      return array.trimmedDescription
    }

    // `[String: Int](...)` — DictionaryExpr used as constructor
    if let dictionaryExpr = expr.as(DictionaryExprSyntax.self) {
      return dictionaryExpr.trimmedDescription
    }

    return nil
  }

  // MARK: - Void detection

  /// Returns `true` if the type name contains Void. Removing the annotation for Void-related
  /// types is unhelpful and potentially confusing.
  private static func isVoidType(_ typeName: String) -> Bool {
    typeName.contains("Void") || typeName.contains("()")
  }
}

extension Finding.Message {
  fileprivate static func removeRedundantType(typeName: String) -> Finding.Message {
    "remove redundant type annotation '\(typeName)'; it is obvious from the initializer"
  }
}
