import SwiftSyntax

/// Replace `try!` with `try` in test methods and add `throws` to the function signature.
///
/// In test code, `try!` crashes the test runner on failure instead of producing a clear test
/// failure. Using `throws` on the test method and plain `try` lets the framework report the
/// error properly.
///
/// This rule applies to:
/// - Functions annotated with `@Test` (Swift Testing)
/// - Functions named `test*()` with no parameters inside `XCTestCase` subclasses
///
/// `try!` inside closures or nested functions is left alone because the enclosing test function's
/// `throws` does not propagate into those scopes.
///
/// Lint: A warning is raised for each `try!` in a test function body.
///
/// Format: `try!` is replaced with `try` and `throws` is added to the signature if needed.
@_spi(Rules)
public final class NoForceTryInTests: SyntaxFormatRule {

  public override class var isOptIn: Bool { true }

  private var importsTesting = false
  private var insideXCTestCase = false
  private var insideTestFunction = false
  private var convertedForceTry = false

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

  public override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
    guard isTestFunction(node), node.body != nil else {
      // Non-test functions: don't recurse (blocks nested function try! conversion)
      return DeclSyntax(node)
    }

    let wasInsideTest = insideTestFunction
    insideTestFunction = true
    convertedForceTry = false
    defer { insideTestFunction = wasInsideTest }

    let visited = super.visit(node)
    guard var result = visited.as(FunctionDeclSyntax.self) else { return visited }

    guard convertedForceTry else {
      return DeclSyntax(result)
    }

    if result.signature.effectSpecifiers?.throwsClause == nil {
      result = addThrows(to: result)
    }

    return DeclSyntax(result)
  }

  public override func visit(_ node: TryExprSyntax) -> ExprSyntax {
    guard insideTestFunction,
      node.questionOrExclamationMark?.tokenKind == .exclamationMark
    else {
      return super.visit(node)
    }

    diagnose(.replaceForceTry, on: node.tryKeyword)
    convertedForceTry = true

    let visited = super.visit(node)
    guard let tryNode = visited.as(TryExprSyntax.self) else { return visited }
    // Transfer the ! token's trailing trivia (usually a space) to the try keyword
    let bangTrailingTrivia = tryNode.questionOrExclamationMark?.trailingTrivia ?? .space
    return ExprSyntax(
      tryNode
        .with(\.questionOrExclamationMark, nil)
        .with(\.tryKeyword, tryNode.tryKeyword.with(\.trailingTrivia, bangTrailingTrivia))
    )
  }

  // Don't recurse into closures — try! inside closures can't be fixed by making
  // the outer function throw.
  public override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
    ExprSyntax(node)
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
      // Has async but no throws — insert throws after async, steal body's leading trivia
      if var body = result.body {
        var tc = throwsClause
        tc.throwsSpecifier.leadingTrivia = body.leftBrace.leadingTrivia
        body.leftBrace.leadingTrivia = .space
        effectSpecifiers.throwsClause = tc
        result.signature.effectSpecifiers = effectSpecifiers
        result.body = body
      }
    } else {
      // No effect specifiers — add them, transfer body's leading trivia to throws
      // and give body a space
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
}

extension Finding.Message {
  fileprivate static let replaceForceTry: Finding.Message =
    "replace 'try!' with 'try' in test function; use 'throws' on the test method instead"
}
