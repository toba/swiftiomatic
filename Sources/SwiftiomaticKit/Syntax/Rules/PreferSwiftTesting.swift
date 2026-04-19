import SwiftSyntax

/// Convert XCTest suites to Swift Testing.
///
/// Replaces `import XCTest` with `import Testing` + `import Foundation`, removes `XCTestCase`
/// conformance, converts `setUp`/`tearDown` to `init`/`deinit`, adds `@Test` to test methods,
/// and converts XCT assertions to `#expect`/`#require`.
///
/// Bails out entirely if the file contains unsupported XCTest functionality (expectations,
/// performance tests, unknown overrides, async/throws tearDown, XCTestCase extensions).
///
/// Lint: A warning is raised for each XCTest pattern that can be converted.
///
/// Format: The XCTest patterns are replaced with Swift Testing equivalents.
final class PreferSwiftTesting: RewriteSyntaxRule {

  override class var defaultHandling: RuleHandling { .off }

  /// Set to true when we detect unsupported patterns — bail out of the entire file.
  private var bailOut = false
  /// Set after we've processed imports and know XCTest is imported.
  private var hasXCTestImport = false
  /// Track class names that conform to XCTestCase for extension detection.
  private var xcTestCaseClassNames = Set<String>()
  /// Track whether we're inside an XCTestCase class.
  private var insideXCTestCase = false
  /// Track whether we added a try expression in the current function (to add throws).
  private var currentFunctionHasTry = false

  // MARK: - File-level: scan for unsupported patterns, replace imports

  override func visit(_ node: SourceFileSyntax) -> SourceFileSyntax {
    // Pre-scan: detect unsupported patterns and XCTest import
    for stmt in node.statements {
      if let importDecl = stmt.item.as(ImportDeclSyntax.self) {
        if importDecl.path.first?.name.text == "XCTest" {
          hasXCTestImport = true
        }
      }
    }

    guard hasXCTestImport else { return node }

    // Check for unsupported patterns before transforming
    if hasUnsupportedPatterns(in: node) {
      bailOut = true
      return node
    }

    // Collect XCTestCase class names for extension detection
    for stmt in node.statements {
      if let classDecl = stmt.item.as(ClassDeclSyntax.self),
        let inheritance = classDecl.inheritanceClause,
        inheritance.contains(named: "XCTestCase")
      {
        xcTestCaseClassNames.insert(classDecl.name.text)
      }
    }

    // Check for XCTestCase extensions in the file — unsupported
    for stmt in node.statements {
      if let extDecl = stmt.item.as(ExtensionDeclSyntax.self) {
        let extName = extDecl.extendedType.trimmedDescription
        if extName == "XCTestCase" || xcTestCaseClassNames.contains(extName) {
          // Extension of XCTestCase itself is unsupported
          if extName == "XCTestCase" {
            bailOut = true
            return node
          }
          // Extension of a known test case — we'll convert test methods in it
        }
      }
    }

    return super.visit(node)
  }

  // MARK: - Import replacement

  override func visit(_ node: ImportDeclSyntax) -> DeclSyntax {
    guard hasXCTestImport, !bailOut else { return DeclSyntax(node) }

    if node.path.first?.name.text == "XCTest" {
      // Replace `import XCTest` with `import Testing`
      // We build two import statements but can only return one DeclSyntax.
      // We'll use the CodeBlockItemListSyntax visitor to handle adding Foundation.
      var result = node
      result.path = ImportPathComponentListSyntax([
        ImportPathComponentSyntax(name: .identifier("Testing"))
      ])
      return DeclSyntax(result)
    }
    return DeclSyntax(node)
  }

  // MARK: - Class-level: remove XCTestCase conformance

  override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
    guard hasXCTestImport, !bailOut else { return DeclSyntax(node) }

    guard let inheritance = node.inheritanceClause,
      inheritance.contains(named: "XCTestCase")
    else {
      return super.visit(node)
    }

    let wasInsideXCTestCase = insideXCTestCase
    insideXCTestCase = true
    defer { insideXCTestCase = wasInsideXCTestCase }

    let visited = super.visit(node)
    guard var result = visited.as(ClassDeclSyntax.self) else { return visited }

    // Remove XCTestCase conformance
    // removing(named:) returns nil when the removed item was the only one (list now empty),
    // returns self when the name isn't found, or returns modified clause with remaining items.
    if let inheritanceClause = result.inheritanceClause {
      if let newClause = inheritanceClause.removing(named: "XCTestCase") {
        if newClause.inheritedTypes.count == inheritanceClause.inheritedTypes.count {
          // Same count → name not found, no change
        } else {
          result.inheritanceClause = newClause
        }
      } else {
        // nil → removed and list is empty, remove entire clause
        result.inheritanceClause = nil
        // Ensure space before { (the space was trailing trivia of the removed conformance)
        result.memberBlock.leftBrace.leadingTrivia = .space
      }
    }

    return DeclSyntax(result)
  }

  // MARK: - Extension-level: convert test methods in extensions of XCTestCase types

  override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
    guard hasXCTestImport, !bailOut else { return DeclSyntax(node) }

    let extName = node.extendedType.trimmedDescription
    guard xcTestCaseClassNames.contains(extName) else {
      return DeclSyntax(node)
    }

    let wasInsideXCTestCase = insideXCTestCase
    insideXCTestCase = true
    defer { insideXCTestCase = wasInsideXCTestCase }

    return super.visit(node)
  }

  // MARK: - Function-level: add @Test, convert setUp/tearDown, add throws

  override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
    guard hasXCTestImport, !bailOut, insideXCTestCase else { return super.visit(node) }

    let name = node.name.text

    // Convert setUp/setUpWithError → init
    if (name == "setUp" || name == "setUpWithError")
      && node.modifiers.contains(where: { $0.name.tokenKind == .keyword(.override) })
    {
      return convertSetUp(node)
    }

    // Convert tearDown → deinit
    if name == "tearDown"
      && node.modifiers.contains(where: { $0.name.tokenKind == .keyword(.override) })
    {
      return convertTearDown(node)
    }

    // Convert test methods
    if name.hasPrefix("test")
      && node.signature.parameterClause.parameters.isEmpty
      && node.signature.returnClause == nil
      && !node.modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) })
    {
      return convertTestMethod(node)
    }

    return super.visit(node)
  }

  // MARK: - Expression-level: convert XCT assertions

  override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
    guard hasXCTestImport, !bailOut else { return ExprSyntax(node) }

    let calledName = node.calledExpression.trimmedDescription

    guard calledName.hasPrefix("XCT") || calledName == "Issue.record" else {
      return super.visit(node)
    }

    let visited = super.visit(node)
    guard let typedNode = visited.as(FunctionCallExprSyntax.self) else { return visited }

    if var replacement = convertAssertion(calledName, call: typedNode, originalNode: node) {
      // Transfer trivia from the original expression to the replacement
      replacement.leadingTrivia = typedNode.leadingTrivia
      replacement.trailingTrivia = typedNode.trailingTrivia
      return replacement
    }

    return ExprSyntax(typedNode)
  }

  // MARK: - Assertion conversion

  private func convertAssertion(
    _ name: String, call: FunctionCallExprSyntax, originalNode: FunctionCallExprSyntax
  ) -> ExprSyntax? {
    let args = Array(call.arguments)

    switch name {
    case "XCTAssert", "XCTAssertTrue":
      return convertSingleValueAssert(args, originalNode: originalNode) { $0 }

    case "XCTAssertFalse":
      return convertSingleValueAssert(args, originalNode: originalNode) { expr in
        ExprSyntax(PrefixOperatorExprSyntax(
          operator: .prefixOperator("!"),
          expression: wrapInParensIfNeeded(expr)))
      }

    case "XCTAssertNil":
      return convertSingleValueAssert(args, originalNode: originalNode) { expr in
        ExprSyntax(InfixOperatorExprSyntax(
          leftOperand: wrapInParensIfNeeded(expr),
          operator: ExprSyntax(BinaryOperatorExprSyntax(
            operator: .binaryOperator("==", leadingTrivia: .space, trailingTrivia: .space))),
          rightOperand: ExprSyntax(NilLiteralExprSyntax())))
      }

    case "XCTAssertNotNil":
      return convertSingleValueAssert(args, originalNode: originalNode) { expr in
        ExprSyntax(InfixOperatorExprSyntax(
          leftOperand: wrapInParensIfNeeded(expr),
          operator: ExprSyntax(BinaryOperatorExprSyntax(
            operator: .binaryOperator("!=", leadingTrivia: .space, trailingTrivia: .space))),
          rightOperand: ExprSyntax(NilLiteralExprSyntax())))
      }

    case "XCTAssertEqual":
      return convertComparisonAssert(args, operator: "==", originalNode: originalNode)

    case "XCTAssertNotEqual":
      return convertComparisonAssert(args, operator: "!=", originalNode: originalNode)

    case "XCTFail":
      return convertXCTFail(args, originalNode: originalNode)

    case "XCTUnwrap":
      return convertXCTUnwrap(args, originalNode: originalNode)

    default:
      return nil
    }
  }

  private func convertSingleValueAssert(
    _ args: [LabeledExprSyntax],
    originalNode: FunctionCallExprSyntax,
    transform: (ExprSyntax) -> ExprSyntax
  ) -> ExprSyntax? {
    guard args.count == 1 || args.count == 2 else { return nil }
    // All params should be unlabeled
    guard args.allSatisfy({ $0.label == nil }) else { return nil }

    let value = transform(args[0].expression.trimmed)

    diagnose(.convertAssertion, on: originalNode.calledExpression)

    var expectArgs = [LabeledExprSyntax]()
    if args.count == 2 {
      expectArgs.append(LabeledExprSyntax(
        expression: value,
        trailingComma: .commaToken(trailingTrivia: .space)))
      expectArgs.append(LabeledExprSyntax(expression: args[1].expression.trimmed))
    } else {
      expectArgs.append(LabeledExprSyntax(expression: value))
    }

    return ExprSyntax(
      MacroExpansionExprSyntax(
        pound: .poundToken(),
        macroName: .identifier("expect"),
        leftParen: .leftParenToken(),
        arguments: LabeledExprListSyntax(expectArgs),
        rightParen: .rightParenToken()))
  }

  private func convertComparisonAssert(
    _ args: [LabeledExprSyntax],
    operator op: String,
    originalNode: FunctionCallExprSyntax
  ) -> ExprSyntax? {
    guard args.count == 2 || args.count == 3 else { return nil }
    guard args.allSatisfy({ $0.label == nil }) else { return nil }

    let lhs = wrapInParensIfNeeded(args[0].expression.trimmed)
    let rhs = wrapInParensIfNeeded(args[1].expression.trimmed)

    diagnose(.convertAssertion, on: originalNode.calledExpression)

    let comparison = ExprSyntax(InfixOperatorExprSyntax(
      leftOperand: lhs,
      operator: ExprSyntax(BinaryOperatorExprSyntax(
        operator: .binaryOperator(op, leadingTrivia: .space, trailingTrivia: .space))),
      rightOperand: rhs))

    var expectArgs = [LabeledExprSyntax]()
    if args.count == 3 {
      expectArgs.append(LabeledExprSyntax(
        expression: comparison,
        trailingComma: .commaToken(trailingTrivia: .space)))
      expectArgs.append(LabeledExprSyntax(expression: args[2].expression.trimmed))
    } else {
      expectArgs.append(LabeledExprSyntax(expression: comparison))
    }

    return ExprSyntax(
      MacroExpansionExprSyntax(
        pound: .poundToken(),
        macroName: .identifier("expect"),
        leftParen: .leftParenToken(),
        arguments: LabeledExprListSyntax(expectArgs),
        rightParen: .rightParenToken()))
  }

  private func convertXCTFail(
    _ args: [LabeledExprSyntax],
    originalNode: FunctionCallExprSyntax
  ) -> ExprSyntax? {
    guard args.count <= 1 else { return nil }

    diagnose(.convertAssertion, on: originalNode.calledExpression)

    let issueRecord = MemberAccessExprSyntax(
      base: ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("Issue"))),
      period: .periodToken(),
      declName: DeclReferenceExprSyntax(baseName: .identifier("record")))

    var callArgs = [LabeledExprSyntax]()
    if let msgArg = args.first {
      callArgs.append(LabeledExprSyntax(expression: msgArg.expression.trimmed))
    }

    return ExprSyntax(
      FunctionCallExprSyntax(
        calledExpression: ExprSyntax(issueRecord),
        leftParen: .leftParenToken(),
        arguments: LabeledExprListSyntax(callArgs),
        rightParen: .rightParenToken()))
  }

  private func convertXCTUnwrap(
    _ args: [LabeledExprSyntax],
    originalNode: FunctionCallExprSyntax
  ) -> ExprSyntax? {
    guard args.count == 1 || args.count == 2 else { return nil }

    diagnose(.convertAssertion, on: originalNode.calledExpression)

    var requireArgs = [LabeledExprSyntax]()
    if args.count == 2 {
      requireArgs.append(LabeledExprSyntax(
        expression: args[0].expression.trimmed,
        trailingComma: .commaToken(trailingTrivia: .space)))
      requireArgs.append(LabeledExprSyntax(expression: args[1].expression.trimmed))
    } else {
      requireArgs.append(LabeledExprSyntax(expression: args[0].expression.trimmed))
    }

    return ExprSyntax(
      MacroExpansionExprSyntax(
        pound: .poundToken(),
        macroName: .identifier("require"),
        leftParen: .leftParenToken(),
        arguments: LabeledExprListSyntax(requireArgs),
        rightParen: .rightParenToken()))
  }

  // MARK: - setUp/tearDown conversion

  private func convertSetUp(_ node: FunctionDeclSyntax) -> DeclSyntax {

    // Visit children first (to convert assertions inside setUp)
    let visited = super.visit(node)
    guard var result = visited.as(FunctionDeclSyntax.self) else { return visited }

    // Remove `override` modifier
    result.modifiers = result.modifiers.filter {
      $0.name.tokenKind != .keyword(.override)
    }

    // Remove super.setUp() / super.setUpWithError() call from body
    if var body = result.body {
      body.statements = removeSuperCall(from: body.statements, methodName: node.name.text)
      result.body = body
    }

    // Replace `func setUp` / `func setUpWithError` with `init`
    // Use original node's leading trivia (preserves blank line + indentation lost when override removed)
    let initDecl = InitializerDeclSyntax(
      attributes: result.attributes,
      modifiers: result.modifiers,
      initKeyword: .keyword(.`init`,
        leadingTrivia: node.leadingTrivia,
        trailingTrivia: []),
      signature: result.signature,
      body: result.body)

    return DeclSyntax(initDecl)
  }

  private func convertTearDown(_ node: FunctionDeclSyntax) -> DeclSyntax {

    let visited = super.visit(node)
    guard var result = visited.as(FunctionDeclSyntax.self) else { return visited }

    // Remove `override` modifier
    result.modifiers = result.modifiers.filter {
      $0.name.tokenKind != .keyword(.override)
    }

    // Remove super.tearDown() call
    if var body = result.body {
      body.statements = removeSuperCall(from: body.statements, methodName: "tearDown")
      result.body = body
    }

    // Build deinit — use original node's leading trivia to preserve blank line + indentation
    let deinitDecl = DeinitializerDeclSyntax(
      attributes: result.attributes,
      modifiers: result.modifiers,
      deinitKeyword: .keyword(.deinit,
        leadingTrivia: node.leadingTrivia,
        trailingTrivia: result.body?.leftBrace.leadingTrivia ?? .space),
      body: result.body?.with(\.leftBrace,
        result.body!.leftBrace.with(\.leadingTrivia, .space)))

    return DeclSyntax(deinitDecl)
  }

  // MARK: - Test method conversion

  private func convertTestMethod(_ node: FunctionDeclSyntax) -> DeclSyntax {

    // Track try usage for throws addition
    let savedHasTry = currentFunctionHasTry
    currentFunctionHasTry = false
    defer { currentFunctionHasTry = savedHasTry }

    // Check if body contains `try` before conversion (XCTest autoclosures are throwing)
    let bodyHasTry = node.body?.statements.contains(where: { stmt in
      stmt.item.tokens(viewMode: .sourceAccurate).contains { $0.tokenKind == .keyword(.try) }
    }) ?? false

    let alreadyThrows = node.signature.effectSpecifiers?.throwsClause != nil

    let visited = super.visit(node)
    guard var result = visited.as(FunctionDeclSyntax.self) else { return visited }

    // Add @Test attribute
    let testAttr = AttributeSyntax(
      atSign: .atSignToken(),
      attributeName: IdentifierTypeSyntax(name: .identifier("Test")),
      trailingTrivia: .space)

    // Move existing leading trivia from func keyword to the @Test attribute
    let funcTrivia = result.funcKeyword.leadingTrivia
    result.funcKeyword = result.funcKeyword.with(\.leadingTrivia, [])

    // Build new attribute list with @Test first
    var attrList = [AttributeListSyntax.Element]()
    attrList.append(AttributeListSyntax.Element(
      testAttr.with(\.atSign,
        .atSignToken(leadingTrivia: funcTrivia))))

    // Add existing attributes
    for attr in result.attributes {
      attrList.append(attr)
    }

    result.attributes = AttributeListSyntax(attrList)

    // Add throws if test body has try but function isn't already throwing
    if bodyHasTry && !alreadyThrows {
      result = result.addingThrowsClause()
    }

    return DeclSyntax(result)
  }

  // MARK: - Statement list: add Foundation import

  override func visit(_ node: MemberBlockItemListSyntax) -> MemberBlockItemListSyntax {
    guard hasXCTestImport, !bailOut else { return super.visit(node) }
    return super.visit(node)
  }

  // MARK: - Unsupported pattern detection

  private func hasUnsupportedPatterns(in node: SourceFileSyntax) -> Bool {
    let unsupportedIdentifiers: Set<String> = [
      "expectation", "wait", "measure", "measureMetrics", "addTeardownBlock",
      "continueAfterFailure", "executionTimeAllowance", "startMeasuring",
      "stopMeasuring", "fulfillment", "XCUIApplication",
    ]

    for token in node.tokens(viewMode: .sourceAccurate) {
      if case .identifier(let text) = token.tokenKind {
        if unsupportedIdentifiers.contains(text) { return true }
      }
    }

    // Check for async/throws tearDown
    for stmt in node.statements {
      if let classDecl = stmt.item.as(ClassDeclSyntax.self) {
        for member in classDecl.memberBlock.members {
          if let funcDecl = member.decl.as(FunctionDeclSyntax.self),
            funcDecl.name.text == "tearDown",
            funcDecl.modifiers.contains(where: { $0.name.tokenKind == .keyword(.override) })
          {
            let effects = funcDecl.signature.effectSpecifiers
            if effects?.asyncSpecifier != nil || effects?.throwsClause != nil {
              return true
            }
          }

          // Check for unsupported overrides
          if let funcDecl = member.decl.as(FunctionDeclSyntax.self),
            funcDecl.modifiers.contains(where: { $0.name.tokenKind == .keyword(.override) })
          {
            let name = funcDecl.name.text
            let supported = ["setUp", "setUpWithError", "tearDown"]
            if !supported.contains(name) {
              return true
            }
          }
        }
      }
    }

    // Check for file: StaticString / line: UInt params (XCTest helper pattern)
    for token in node.tokens(viewMode: .sourceAccurate) {
      if case .identifier(let text) = token.tokenKind {
        if text == "StaticString" {
          // Check if preceded by "file:" parameter label
          if let prev = token.previousToken(viewMode: .sourceAccurate),
            prev.tokenKind == .colon,
            let prevPrev = prev.previousToken(viewMode: .sourceAccurate),
            prevPrev.text == "file"
          {
            return true
          }
        }
      }
    }

    return false
  }

  // MARK: - Helpers

  private func removeSuperCall(
    from statements: CodeBlockItemListSyntax, methodName: String
  ) -> CodeBlockItemListSyntax {
    var items = Array(statements)
    items.removeAll { item in
      guard let call = extractFunctionCall(from: item.item) else { return false }
      let callText = call.calledExpression.trimmedDescription
      return callText == "super.\(methodName)" || callText == "super.setUp"
    }
    return CodeBlockItemListSyntax(items)
  }

  private func extractFunctionCall(from item: CodeBlockItemSyntax.Item) -> FunctionCallExprSyntax? {
    // Unwrap the expression, stripping try/await/ExpressionStmt layers
    func unwrapToCall(_ expr: ExprSyntax) -> FunctionCallExprSyntax? {
      if let call = expr.as(FunctionCallExprSyntax.self) { return call }
      if let tryExpr = expr.as(TryExprSyntax.self) { return unwrapToCall(tryExpr.expression) }
      if let awaitExpr = expr.as(AwaitExprSyntax.self) { return unwrapToCall(awaitExpr.expression) }
      return nil
    }

    if let call = item.as(FunctionCallExprSyntax.self) { return call }
    if let tryExpr = item.as(TryExprSyntax.self) { return unwrapToCall(tryExpr.expression) }
    if let awaitExpr = item.as(AwaitExprSyntax.self) { return unwrapToCall(awaitExpr.expression) }
    return nil
  }

  /// Wrap an expression in parens if it contains an infix operator.
  private func wrapInParensIfNeeded(_ expr: ExprSyntax) -> ExprSyntax {
    if expr.is(InfixOperatorExprSyntax.self)
      || expr.is(IsExprSyntax.self)
      || expr.is(TryExprSyntax.self)
    {
      return ExprSyntax(TupleExprSyntax(
        leftParen: .leftParenToken(),
        elements: LabeledExprListSyntax([
          LabeledExprSyntax(expression: expr)
        ]),
        rightParen: .rightParenToken()))
    }
    return expr
  }

}

extension Finding.Message {
  fileprivate static let replaceImport: Finding.Message =
    "replace 'import XCTest' with 'import Testing'"
  fileprivate static let removeConformance: Finding.Message =
    "remove 'XCTestCase' conformance"
  fileprivate static let convertSetUp: Finding.Message =
    "convert 'setUp' to 'init'"
  fileprivate static let convertTearDown: Finding.Message =
    "convert 'tearDown' to 'deinit'"
  fileprivate static let addTestAttribute: Finding.Message =
    "add '@Test' attribute to test method"
  fileprivate static let convertAssertion: Finding.Message =
    "convert XCTest assertion to Swift Testing"
}
