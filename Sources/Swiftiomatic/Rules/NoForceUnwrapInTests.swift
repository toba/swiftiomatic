import SwiftSyntax

/// Replace force unwraps (`!`) in test functions with `try XCTUnwrap(...)` (XCTest) or
/// `try #require(...)` (Swift Testing).
///
/// Force unwraps in tests crash the test runner instead of producing a useful failure message.
/// Using XCTUnwrap / #require converts the crash into a clear test failure with location info.
///
/// This rule applies to:
/// - Functions annotated with `@Test` (Swift Testing)
/// - Functions named `test*()` with no parameters inside `XCTestCase` subclasses
///
/// Force unwraps in closures, nested functions, and string interpolation are left alone because
/// `try` cannot propagate out of those scopes.
///
/// Lint: A warning is raised for each force unwrap that can be converted.
///
/// Format: Force unwraps are replaced with optional chaining and wrapped in XCTUnwrap/#require.
@_spi(Rules)
public final class NoForceUnwrapInTests: SyntaxFormatRule {

  public override class var isOptIn: Bool { true }

  private var importsTesting = false
  private var insideXCTestCase = false
  private var insideTestFunction = false
  private var addedTryExpression = false

  // MARK: - Scope tracking

  public override func visit(_ node: ImportDeclSyntax) -> DeclSyntax {
    if node.path.first?.name.text == "Testing" {
      importsTesting = true
    }
    return DeclSyntax(node)
  }

  public override func visit(_ node: SourceFileSyntax) -> SourceFileSyntax {
    setImportsXCTest(context: context, sourceFile: node)
    return super.visit(node)
  }

  public override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
    let wasInside = insideXCTestCase
    if context.importsXCTest == .importsXCTest,
      let inheritance = node.inheritanceClause,
      inheritance.contains(named: "XCTestCase")
    {
      insideXCTestCase = true
    }
    defer { insideXCTestCase = wasInside }
    return super.visit(node)
  }

  // Don't recurse into closures — try can't propagate out.
  public override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
    ExprSyntax(node)
  }

  // Don't recurse into string interpolation — try is not allowed.
  public override func visit(_ node: StringLiteralExprSyntax) -> ExprSyntax {
    ExprSyntax(node)
  }

  // MARK: - Function-level: detect test, add throws

  public override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
    guard isTestFunction(node), node.body != nil else {
      return DeclSyntax(node)
    }

    let wasInsideTest = insideTestFunction
    let wasAddedTry = addedTryExpression
    insideTestFunction = true
    addedTryExpression = false
    defer {
      insideTestFunction = wasInsideTest
      addedTryExpression = wasAddedTry
    }

    let visited = super.visit(node)
    guard var result = visited.as(FunctionDeclSyntax.self) else { return visited }

    guard addedTryExpression else {
      return DeclSyntax(result)
    }

    if result.signature.effectSpecifiers?.throwsClause == nil {
      result = addThrows(to: result)
    }

    return DeclSyntax(result)
  }

  // MARK: - Force unwrap → optional chaining or XCTUnwrap

  public override func visit(_ node: ForceUnwrapExprSyntax) -> ExprSyntax {
    guard insideTestFunction else { return ExprSyntax(node) }

    // Skip if this is a try! expression (handled by noForceTryInTests)
    if let parentTry = node.parent?.as(TryExprSyntax.self),
      parentTry.questionOrExclamationMark?.tokenKind == .exclamationMark
    {
      return ExprSyntax(node)
    }

    // Classify context using the ORIGINAL node (which has valid parent chain)
    let outermost = isOutermostForceUnwrap(node)
    let unwrapContext = outermost ? classifyOutermostContext(of: node) : .inner

    // Now visit children (inner force unwraps get converted first)
    let visited = super.visit(node)
    guard let typedNode = visited.as(ForceUnwrapExprSyntax.self) else { return visited }

    switch unwrapContext {
    case .inner:
      // Inner force unwrap in a chain — just convert to optional chaining
      diagnose(.replaceForceUnwrap, on: node.exclamationMark)
      return ExprSyntax(
        OptionalChainingExprSyntax(
          expression: typedNode.expression,
          questionMark: .postfixQuestionMarkToken(
            leadingTrivia: typedNode.exclamationMark.leadingTrivia,
            trailingTrivia: typedNode.exclamationMark.trailingTrivia)))

    case .noWrap:
      // Outermost but no wrapping needed — convert to optional chaining
      diagnose(.replaceForceUnwrap, on: node.exclamationMark)
      return ExprSyntax(
        OptionalChainingExprSyntax(
          expression: typedNode.expression,
          questionMark: .postfixQuestionMarkToken(
            leadingTrivia: typedNode.exclamationMark.leadingTrivia,
            trailingTrivia: typedNode.exclamationMark.trailingTrivia)))

    case .wrapInUnwrap:
      // Outermost with wrapping — remove ! and wrap in try XCTUnwrap/require
      diagnose(.replaceForceUnwrap, on: node.exclamationMark)
      addedTryExpression = true
      return wrapInUnwrap(
        typedNode.expression,
        trailingTrivia: typedNode.exclamationMark.trailingTrivia)
    }
  }

  // MARK: - Force cast (as!) → as?

  public override func visit(_ node: AsExprSyntax) -> ExprSyntax {
    guard insideTestFunction else { return ExprSyntax(node) }
    guard node.questionOrExclamationMark?.tokenKind == .exclamationMark else {
      return ExprSyntax(node)
    }

    let visited = super.visit(node)
    guard let typedNode = visited.as(AsExprSyntax.self) else { return visited }

    diagnose(.replaceForceCast, on: node.asKeyword)

    var result = typedNode
    result.questionOrExclamationMark = .postfixQuestionMarkToken(
      leadingTrivia: typedNode.questionOrExclamationMark!.leadingTrivia,
      trailingTrivia: typedNode.questionOrExclamationMark!.trailingTrivia)
    return ExprSyntax(result)
  }

  // MARK: - Handle (expr as? Type).member → (expr as? Type)?.member

  public override func visit(_ node: MemberAccessExprSyntax) -> ExprSyntax {
    guard insideTestFunction else { return ExprSyntax(node) }

    // Check original node: does the base contain a force cast inside parens?
    let originalHadForceCast: Bool
    if let base = node.base,
      let tupleExpr = base.as(TupleExprSyntax.self),
      tupleExpr.elements.count == 1,
      let singleElement = tupleExpr.elements.first,
      findForceCast(in: singleElement.expression) != nil
    {
      originalHadForceCast = true
    } else {
      originalHadForceCast = false
    }

    let visited = super.visit(node)
    guard let typedNode = visited.as(MemberAccessExprSyntax.self) else { return visited }

    // If the original had a force cast that we converted to as?, add optional chaining
    if originalHadForceCast, let base = typedNode.base {
      let optionalBase = OptionalChainingExprSyntax(
        expression: base,
        questionMark: .postfixQuestionMarkToken())
      var result = typedNode
      result.base = ExprSyntax(optionalBase)
      return ExprSyntax(result)
    }

    return ExprSyntax(typedNode)
  }

  // MARK: - Outermost detection

  /// Returns true if this ForceUnwrapExprSyntax is the outermost one in its expression chain.
  /// Uses the ORIGINAL node's parent chain (which is intact).
  private func isOutermostForceUnwrap(_ node: ForceUnwrapExprSyntax) -> Bool {
    var current: Syntax = Syntax(node)
    while let parent = current.parent {
      // Another force unwrap above us in the chain means we're inner
      if parent.is(ForceUnwrapExprSyntax.self) {
        return false
      }

      // Continue walking up through expression chain nodes
      if parent.is(MemberAccessExprSyntax.self)
        || parent.is(OptionalChainingExprSyntax.self)
      {
        current = parent
        continue
      }

      // Function call: only continue if we're the calledExpression
      if let funcCall = parent.as(FunctionCallExprSyntax.self),
        funcCall.calledExpression.id == current.id
      {
        current = parent
        continue
      }

      // Subscript: only continue if we're the calledExpression
      if let subscriptCall = parent.as(SubscriptCallExprSyntax.self),
        subscriptCall.calledExpression.id == current.id
      {
        current = parent
        continue
      }

      // Reached a non-chain boundary — we're outermost
      return true
    }
    return true
  }

  // MARK: - Context classification (for outermost force unwraps)

  private enum UnwrapContext {
    case inner       // Not outermost — just convert ! to ?
    case noWrap      // Outermost but no wrapping needed (LHS of =, ==, standalone, etc.)
    case wrapInUnwrap // Outermost with wrapping needed
  }

  /// Classify the context for an outermost force unwrap.
  /// Uses the ORIGINAL node's parent chain.
  private func classifyOutermostContext(of node: ForceUnwrapExprSyntax) -> UnwrapContext {
    // Walk up to find the top of the expression chain
    var top: Syntax = Syntax(node)
    while let parent = top.parent {
      if parent.is(MemberAccessExprSyntax.self)
        || parent.is(OptionalChainingExprSyntax.self)
      {
        top = parent
        continue
      }
      if let funcCall = parent.as(FunctionCallExprSyntax.self),
        funcCall.calledExpression.id == top.id
      {
        top = parent
        continue
      }
      if let subscriptCall = parent.as(SubscriptCallExprSyntax.self),
        subscriptCall.calledExpression.id == top.id
      {
        top = parent
        continue
      }
      break
    }

    // Now check what the parent of the top expression is
    guard let contextParent = top.parent else { return .wrapInUnwrap }

    // Function argument — check which function
    if let labeledExpr = contextParent.as(LabeledExprSyntax.self) {
      return classifyFunctionArgContext(labeledExpr: labeledExpr)
    }

    // Infix operator — check which operator
    if let infixExpr = contextParent.as(InfixOperatorExprSyntax.self) {
      return classifyInfixContext(infixExpr, topExpr: top)
    }

    // Standalone expression (direct child of CodeBlockItemSyntax)
    if contextParent.is(CodeBlockItemSyntax.self) {
      return .noWrap
    }

    // Initializer clause (let x = expr!) — needs wrapping
    if contextParent.is(InitializerClauseSyntax.self) {
      return .wrapInUnwrap
    }

    // Return statement — needs wrapping
    if contextParent.is(ReturnStmtSyntax.self) {
      return .wrapInUnwrap
    }

    // Condition element — needs wrapping
    if contextParent.is(ConditionElementSyntax.self) {
      return .wrapInUnwrap
    }

    // Default: wrap
    return .wrapInUnwrap
  }

  private func classifyFunctionArgContext(
    labeledExpr: LabeledExprSyntax
  ) -> UnwrapContext {
    guard let argList = labeledExpr.parent?.as(LabeledExprListSyntax.self),
      let funcCall = argList.parent?.as(FunctionCallExprSyntax.self)
    else {
      return .wrapInUnwrap
    }

    let funcName = funcCall.calledExpression.trimmedDescription

    // XCTAssertNil — just convert to optional chaining
    if funcName == "XCTAssertNil" {
      return .noWrap
    }

    // XCTAssertEqual with exactly 2 args — just convert to optional chaining
    if funcName == "XCTAssertEqual" && argList.count == 2 {
      return .noWrap
    }

    return .wrapInUnwrap
  }

  private func classifyInfixContext(
    _ infixExpr: InfixOperatorExprSyntax,
    topExpr: Syntax
  ) -> UnwrapContext {
    let op = infixExpr.operator

    // Assignment operator (=) — uses AssignmentExprSyntax, not BinaryOperatorExprSyntax
    if op.is(AssignmentExprSyntax.self) {
      if infixExpr.leftOperand.id == topExpr.id {
        return .noWrap
      }
      return .wrapInUnwrap
    }

    // Binary operators
    if let binOp = op.as(BinaryOperatorExprSyntax.self) {
      // Equality: just convert to optional chaining
      if binOp.operator.text == "==" {
        return .noWrap
      }
    }

    // Other operators (like +): needs wrapping
    return .wrapInUnwrap
  }

  // MARK: - Wrap expression in XCTUnwrap / #require

  private func wrapInUnwrap(_ expr: ExprSyntax, trailingTrivia: Trivia = []) -> ExprSyntax {
    let innerExpr = expr.trimmed
    let callExpr: ExprSyntax
    if importsTesting {
      callExpr = ExprSyntax(
        MacroExpansionExprSyntax(
          pound: .poundToken(),
          macroName: .identifier("require"),
          leftParen: .leftParenToken(),
          arguments: LabeledExprListSyntax([
            LabeledExprSyntax(expression: innerExpr)
          ]),
          rightParen: .rightParenToken(trailingTrivia: trailingTrivia)))
    } else {
      callExpr = ExprSyntax(
        FunctionCallExprSyntax(
          calledExpression: ExprSyntax(
            DeclReferenceExprSyntax(baseName: .identifier("XCTUnwrap"))),
          leftParen: .leftParenToken(),
          arguments: LabeledExprListSyntax([
            LabeledExprSyntax(expression: innerExpr)
          ]),
          rightParen: .rightParenToken(trailingTrivia: trailingTrivia)))
    }

    return ExprSyntax(
      TryExprSyntax(
        tryKeyword: .keyword(.try, trailingTrivia: .space),
        expression: callExpr))
  }

  // MARK: - Helpers

  private func isTestFunction(_ node: FunctionDeclSyntax) -> Bool {
    if importsTesting && node.hasAttribute("Test", inModule: "Testing") {
      return true
    }

    if insideXCTestCase {
      let name = node.name.text
      return name.hasPrefix("test")
        && node.signature.parameterClause.parameters.isEmpty
        && node.signature.returnClause == nil
    }

    return false
  }

  private func addThrows(to node: FunctionDeclSyntax) -> FunctionDeclSyntax {
    var result = node
    let throwsClause = ThrowsClauseSyntax(
      throwsSpecifier: .keyword(.throws, trailingTrivia: [])
    )
    if var effectSpecifiers = result.signature.effectSpecifiers {
      if var body = result.body {
        var tc = throwsClause
        tc.throwsSpecifier.leadingTrivia = body.leftBrace.leadingTrivia
        body.leftBrace.leadingTrivia = .space
        effectSpecifiers.throwsClause = tc
        result.signature.effectSpecifiers = effectSpecifiers
        result.body = body
      }
    } else {
      result.signature.effectSpecifiers = FunctionEffectSpecifiersSyntax(
        throwsClause: throwsClause
      )
      if var body = result.body {
        let bodyTrivia = body.leftBrace.leadingTrivia
        result.signature.effectSpecifiers!.throwsClause!.throwsSpecifier.leadingTrivia = bodyTrivia
        body.leftBrace.leadingTrivia = .space
        result.body = body
      }
    }
    return result
  }

  /// Find a force cast (as!) anywhere in the expression tree.
  private func findForceCast(in expr: ExprSyntax) -> AsExprSyntax? {
    if let asExpr = expr.as(AsExprSyntax.self),
      asExpr.questionOrExclamationMark?.tokenKind == .exclamationMark
    {
      return asExpr
    }
    for child in expr.children(viewMode: .sourceAccurate) {
      if let childExpr = child.as(ExprSyntax.self),
        let found = findForceCast(in: childExpr)
      {
        return found
      }
    }
    return nil
  }
}

extension Finding.Message {
  fileprivate static let replaceForceUnwrap: Finding.Message =
    "replace force unwrap in test with 'XCTUnwrap' or '#require'"
  fileprivate static let replaceForceCast: Finding.Message =
    "replace force cast in test with optional cast"
}
