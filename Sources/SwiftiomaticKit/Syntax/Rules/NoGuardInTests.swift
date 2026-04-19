import SwiftSyntax

/// Convert `guard` statements in test functions to `try #require(...)`/`#expect(...)` (Swift
/// Testing) or `try XCTUnwrap(...)`/`XCTAssert(...)` (XCTest).
///
/// Guard statements in tests obscure the test intent behind control flow. Replacing them with
/// direct assertions or unwraps makes the test linear and the failure message immediate.
///
/// This rule applies to:
/// - Functions annotated with `@Test` (Swift Testing)
/// - Functions named `test*()` with no parameters inside `XCTestCase` subclasses
///
/// Guards inside closures or nested functions are left alone because the enclosing test function's
/// `throws` does not propagate into those scopes.
///
/// Lint: A warning is raised for each `guard` that can be converted.
///
/// Format: The `guard` is replaced with assertion/unwrap statements and `throws` is added to
/// the signature if needed.
final class NoGuardInTests: RewriteSyntaxRule {

  override class var defaultHandling: RuleHandling { .off }

  private var testContext = TestContextTracker()
  private var insideTestFunction = false
  private var addedTryStatement = false

  // MARK: - Scope tracking

  override func visit(_ node: ImportDeclSyntax) -> DeclSyntax {
    testContext.visitImport(node)
    return DeclSyntax(node)
  }

  override func visit(_ node: SourceFileSyntax) -> SourceFileSyntax {
    testContext.visitSourceFile(node, context: context)
    return super.visit(node)
  }

  override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
    let was = testContext.pushClass(node, context: context)
    defer { testContext.popClass(was: was) }
    return super.visit(node)
  }

  // Don't recurse into closures — guard inside closures can't be fixed by making the outer
  // function throw.
  override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
    ExprSyntax(node)
  }

  // MARK: - Function-level: detect test, add throws

  override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
    guard testContext.isTestFunction(node), node.body != nil else {
      return DeclSyntax(node)
    }

    let wasInsideTest = insideTestFunction
    let wasAddedTry = addedTryStatement
    insideTestFunction = true
    addedTryStatement = false
    defer {
      insideTestFunction = wasInsideTest
      addedTryStatement = wasAddedTry
    }

    let visited = super.visit(node)
    guard var result = visited.as(FunctionDeclSyntax.self) else { return visited }

    guard addedTryStatement else {
      return DeclSyntax(result)
    }

    if result.signature.effectSpecifiers?.throwsClause == nil {
      result = result.addingThrowsClause()
    }

    return DeclSyntax(result)
  }

  // MARK: - Guard replacement

  override func visit(_ node: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
    guard insideTestFunction else { return super.visit(node) }

    let visited = super.visit(node)
    let items = Array(visited)
    var newItems = [CodeBlockItemSyntax]()
    var changed = false

    // Collect variable names declared before each guard for shadowing detection
    var declaredNames = Set<String>()

    for item in items {
      // Track variable declarations for shadowing
      collectDeclaredNames(from: item, into: &declaredNames)

      guard let guardStmt = item.item.as(GuardStmtSyntax.self) else {
        newItems.append(item)
        continue
      }

      guard let replacement = convertGuard(
        guardStmt, item: item, declaredNames: declaredNames)
      else {
        newItems.append(item)
        continue
      }

      newItems.append(contentsOf: replacement)
      changed = true
    }

    guard changed else { return visited }
    return CodeBlockItemListSyntax(newItems)
  }

  // MARK: - Guard analysis and conversion

  private func convertGuard(
    _ guard: GuardStmtSyntax,
    item: CodeBlockItemSyntax,
    declaredNames: Set<String>
  ) -> [CodeBlockItemSyntax]? {
    // Check else body is a valid pattern (just return, or XCTFail()/Issue.record() + return)
    guard isValidElseBlock(`guard`.body) else { return nil }

    let conditions = Array(`guard`.conditions)

    // Skip if any condition has await, pattern matching, or variable shadowing
    for condition in conditions {
      switch condition.condition {
      case .optionalBinding(let binding):
        let name = binding.pattern.trimmedDescription
        // Skip if the binding name shadows an existing declaration
        if declaredNames.contains(name) { return nil }
        // Skip if the binding value contains await
        if binding.initializer?.value.containsAwait == true { return nil }
        // Shorthand `guard let foo` has no initializer — skip if the name is already declared
        // (this is the shadowing case for shorthand syntax)
        if binding.initializer == nil && declaredNames.contains(name) { return nil }
      case .matchingPattern:
        return nil
      case .expression(let expr):
        if expr.containsAwait { return nil }
      case .availability:
        return nil
      #if compiler(>=6.0)
      @unknown default:
        return nil
      #endif
      }
    }

    // Extract assertion message from XCTFail/Issue.record in else body
    let assertionMessage = extractAssertionMessage(from: `guard`.body)
    let useSwiftTesting = testContext.importsTesting
    let fullLeadingTrivia = item.leadingTrivia
    // Extract just the indentation (spaces/tabs) from the leading trivia
    let indentTrivia = extractIndentation(from: fullLeadingTrivia)

    // Diagnose on the guard keyword
    diagnose(.convertGuard, on: `guard`.guardKeyword)

    var replacements = [CodeBlockItemSyntax]()

    for (index, condition) in conditions.enumerated() {
      let isFirst = index == 0
      let trivia = isFirst ? fullLeadingTrivia : .newline + indentTrivia

      switch condition.condition {
      case .optionalBinding(let binding):
        let stmt = buildUnwrapStatement(
          from: binding, useSwiftTesting: useSwiftTesting,
          assertionMessage: assertionMessage)
        var codeBlockItem = CodeBlockItemSyntax(item: .decl(DeclSyntax(stmt)))
        codeBlockItem.leadingTrivia = trivia
        replacements.append(codeBlockItem)
        addedTryStatement = true

      case .expression(let expr):
        let assertExpr = buildAssertExpr(
          for: expr, useSwiftTesting: useSwiftTesting,
          assertionMessage: assertionMessage)
        var codeBlockItem = CodeBlockItemSyntax(item: .expr(assertExpr))
        codeBlockItem.leadingTrivia = trivia
        replacements.append(codeBlockItem)

      default:
        break
      }
    }

    return replacements
  }

  // MARK: - Else block validation

  /// Returns `true` if the guard's else block is one of:
  /// - `{ return }`
  /// - `{ XCTFail(...); return }`
  /// - `{ Issue.record(...); return }`
  private func isValidElseBlock(_ body: CodeBlockSyntax) -> Bool {
    let stmts = body.statements.map(\.item)
    let nonTrivial = stmts.filter { stmt in
      // Skip items that are just whitespace/semicolons
      stmt.trimmedDescription.isEmpty == false
    }

    // Just `return`
    if nonTrivial.count == 1, nonTrivial[0].is(ReturnStmtSyntax.self) {
      return true
    }

    // Must end with return
    guard nonTrivial.last?.is(ReturnStmtSyntax.self) == true else { return false }

    if nonTrivial.count == 2 {
      // XCTFail(...); return  OR  Issue.record(...); return
      if let callExpr = extractFunctionCall(from: nonTrivial[0]) {
        let name = callExpr.calledExpression.trimmedDescription
        return name == "XCTFail" || name == "Issue.record"
      }
    }

    return false
  }

  /// Extracts the assertion message string tokens from XCTFail("...") or Issue.record("...").
  private func extractAssertionMessage(from body: CodeBlockSyntax) -> LabeledExprListSyntax? {
    for stmt in body.statements {
      if let callExpr = extractFunctionCall(from: stmt.item) {
        let name = callExpr.calledExpression.trimmedDescription
        if (name == "XCTFail" || name == "Issue.record"),
          !callExpr.arguments.isEmpty
        {
          // Check the argument is a string literal (or string-like expression)
          return callExpr.arguments
        }
      }
    }
    return nil
  }

  private func extractFunctionCall(from item: CodeBlockItemSyntax.Item) -> FunctionCallExprSyntax? {
    if let callExpr = item.as(FunctionCallExprSyntax.self) {
      return callExpr
    }
    if let exprStmt = item.as(ExpressionStmtSyntax.self) {
      return exprStmt.expression.as(FunctionCallExprSyntax.self)
    }
    return nil
  }

  // MARK: - Statement builders

  private func buildUnwrapStatement(
    from binding: OptionalBindingConditionSyntax,
    useSwiftTesting: Bool,
    assertionMessage: LabeledExprListSyntax?
  ) -> VariableDeclSyntax {
    let keyword = binding.bindingSpecifier
    let patternText = binding.pattern.trimmedDescription

    // Determine the expression to unwrap
    let unwrapExpr: ExprSyntax
    if let initializer = binding.initializer {
      unwrapExpr = initializer.value.trimmed
    } else {
      // Shorthand: `guard let foo` → unwrap `foo` itself
      unwrapExpr = ExprSyntax(
        DeclReferenceExprSyntax(baseName: .identifier(patternText)))
    }

    // Build: try XCTUnwrap(expr) or try #require(expr)
    let callExpr: ExprSyntax
    if useSwiftTesting {
      callExpr = buildMacroCall(
        name: "require", expression: unwrapExpr, assertionMessage: assertionMessage)
    } else {
      callExpr = buildFunctionCall(
        name: "XCTUnwrap", expression: unwrapExpr, assertionMessage: assertionMessage)
    }

    let tryExpr = TryExprSyntax(
      tryKeyword: .keyword(.try, trailingTrivia: .space),
      expression: callExpr)

    let initializerClause = InitializerClauseSyntax(
      equal: .binaryOperator("=", leadingTrivia: .space, trailingTrivia: .space),
      value: ExprSyntax(tryExpr))

    // Build type annotation if present, trimming stale trivia from the guard condition
    let typeAnnotation: TypeAnnotationSyntax? = binding.typeAnnotation.map {
      $0.with(\.colon, $0.colon.with(\.leadingTrivia, []).with(\.trailingTrivia, .space))
        .with(\.type, $0.type.trimmed)
    }

    let pattern = PatternSyntax(
      IdentifierPatternSyntax(identifier: .identifier(patternText)))

    let patternBinding = PatternBindingSyntax(
      pattern: pattern,
      typeAnnotation: typeAnnotation,
      initializer: initializerClause)

    return VariableDeclSyntax(
      bindingSpecifier: keyword.with(\.leadingTrivia, []).with(\.trailingTrivia, .space),
      bindings: PatternBindingListSyntax([patternBinding]))
  }

  private func buildAssertExpr(
    for expr: ExprSyntax,
    useSwiftTesting: Bool,
    assertionMessage: LabeledExprListSyntax?
  ) -> ExprSyntax {
    let args = buildArgList(expression: expr.trimmed, assertionMessage: assertionMessage)

    if useSwiftTesting {
      return ExprSyntax(
        MacroExpansionExprSyntax(
          pound: .poundToken(),
          macroName: .identifier("expect"),
          leftParen: .leftParenToken(),
          arguments: args,
          rightParen: .rightParenToken()))
    } else {
      return ExprSyntax(
        FunctionCallExprSyntax(
          calledExpression: ExprSyntax(
            DeclReferenceExprSyntax(baseName: .identifier("XCTAssert"))),
          leftParen: .leftParenToken(),
          arguments: args,
          rightParen: .rightParenToken()))
    }
  }

  private func buildArgList(
    expression: ExprSyntax,
    assertionMessage: LabeledExprListSyntax?
  ) -> LabeledExprListSyntax {
    var args = [LabeledExprSyntax]()

    if let message = assertionMessage {
      // Expression arg with trailing comma
      args.append(
        LabeledExprSyntax(
          expression: expression,
          trailingComma: .commaToken()))
      for (i, arg) in message.enumerated() {
        var msgArg = arg.trimmed
        msgArg.leadingTrivia = .space
        // Remove trailing comma from last message arg
        if i == message.count - 1 {
          msgArg.trailingComma = nil
        }
        args.append(msgArg)
      }
    } else {
      args.append(LabeledExprSyntax(expression: expression))
    }

    return LabeledExprListSyntax(args)
  }

  private func buildMacroCall(
    name: String,
    expression: ExprSyntax,
    assertionMessage: LabeledExprListSyntax?
  ) -> ExprSyntax {
    ExprSyntax(
      MacroExpansionExprSyntax(
        pound: .poundToken(),
        macroName: .identifier(name),
        leftParen: .leftParenToken(),
        arguments: buildArgList(expression: expression, assertionMessage: assertionMessage),
        rightParen: .rightParenToken()))
  }

  private func buildFunctionCall(
    name: String,
    expression: ExprSyntax,
    assertionMessage: LabeledExprListSyntax?
  ) -> ExprSyntax {
    ExprSyntax(
      FunctionCallExprSyntax(
        calledExpression: ExprSyntax(
          DeclReferenceExprSyntax(baseName: .identifier(name))),
        leftParen: .leftParenToken(),
        arguments: buildArgList(expression: expression, assertionMessage: assertionMessage),
        rightParen: .rightParenToken()))
  }

  // MARK: - Helpers

  /// Extracts just the indentation whitespace (spaces/tabs) from leading trivia,
  /// discarding newlines, comments, etc.
  private func extractIndentation(from trivia: Trivia) -> Trivia {
    var pieces = [TriviaPiece]()
    // Walk backwards from the end to find trailing spaces/tabs (the indentation)
    for piece in trivia.pieces.reversed() {
      switch piece {
      case .spaces, .tabs:
        pieces.insert(piece, at: 0)
      default:
        // Stop at the first non-whitespace piece going backwards
        if !pieces.isEmpty { return Trivia(pieces: pieces) }
        break
      }
    }
    return Trivia(pieces: pieces)
  }

  /// Collect variable names declared in a code block item (for shadowing detection).
  private func collectDeclaredNames(
    from item: CodeBlockItemSyntax, into names: inout Set<String>
  ) {
    if let varDecl = item.item.as(VariableDeclSyntax.self) {
      for binding in varDecl.bindings {
        if let identPattern = binding.pattern.as(IdentifierPatternSyntax.self) {
          names.insert(identPattern.identifier.text)
        }
      }
    }
    // Also check function parameters from the enclosing function
    // (handled by the parent function traversal context)
  }
}

// MARK: - Helpers

extension ExprSyntax {
  fileprivate var containsAwait: Bool {
    tokens(viewMode: .sourceAccurate).contains { $0.tokenKind == .keyword(.await) }
  }
}

extension Finding.Message {
  fileprivate static let convertGuard: Finding.Message =
    "replace 'guard' in test with direct assertion or unwrap"
}
