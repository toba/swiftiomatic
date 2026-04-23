import SwiftSyntax

/// Ensure test methods have the correct `test` prefix or `@Test` attribute.
///
/// For XCTest: functions in `XCTestCase` subclasses that look like tests get a `test` prefix.
/// For Swift Testing: functions in test suite types get a `@Test` attribute.
///
/// A "test suite" type is one whose name ends with `Tests`, `TestCase`, or `Suite`.
///
/// Functions are skipped if they:
/// - Have parameters or a return type
/// - Are `override`, `@objc`, `static`, or `private`/`fileprivate`
/// - Start with a disabled prefix (`disable_`, `skip_`, `x_`, `_`, etc.)
/// - Are referenced elsewhere in the file (XCTest only — they're helpers)
/// - Are in a type with a parameterized initializer
/// - Are in an `open` base class or one with "Base"/"base"/"subclass" in name/doc comment
///
/// Lint: A warning is raised for each test method missing the correct prefix or attribute.
///
/// Format: The `test` prefix or `@Test` attribute is added.
final class ValidateTestCases: RewriteSyntaxRule<BasicRuleValue> {

  override class var defaultValue: BasicRuleValue { BasicRuleValue(rewrite: false, lint: .no) }

  private var framework: TestFramework?
  private var identifierCounts = [String: Int]()

  override func visit(_ node: SourceFileSyntax) -> SourceFileSyntax {
    setImportsXCTest(context: context, sourceFile: node)
    framework = detectTestFramework(in: node)

    if framework == .xcTest {
      for token in node.tokens(viewMode: .sourceAccurate) {
        if case .identifier(let name) = token.tokenKind {
          identifierCounts[name, default: 0] += 1
        }
      }
    }

    return super.visit(node)
  }

  override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
    guard let framework else { return DeclSyntax(node) }
    guard isTestSuite(name: node.name.text, inheritanceClause: node.inheritanceClause,
      modifiers: node.modifiers, leadingTrivia: node.leadingTrivia, framework: framework)
    else { return DeclSyntax(node) }
    guard !hasParameterizedInit(node.memberBlock) else { return DeclSyntax(node) }

    let visited = super.visit(node)
    guard var result = visited.as(ClassDeclSyntax.self) else { return visited }
    result.memberBlock = rewriteMembers(result.memberBlock, framework: framework)
    return DeclSyntax(result)
  }

  override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
    guard let framework else { return DeclSyntax(node) }
    guard isTestSuite(name: node.name.text, inheritanceClause: node.inheritanceClause,
      modifiers: node.modifiers, leadingTrivia: node.leadingTrivia, framework: framework)
    else { return DeclSyntax(node) }
    guard !hasParameterizedInit(node.memberBlock) else { return DeclSyntax(node) }

    let visited = super.visit(node)
    guard var result = visited.as(StructDeclSyntax.self) else { return visited }
    result.memberBlock = rewriteMembers(result.memberBlock, framework: framework)
    return DeclSyntax(result)
  }

  override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
    guard let framework else { return DeclSyntax(node) }
    guard isTestSuite(name: node.name.text, inheritanceClause: nil,
      modifiers: node.modifiers, leadingTrivia: node.leadingTrivia, framework: framework)
    else { return DeclSyntax(node) }

    let visited = super.visit(node)
    guard var result = visited.as(EnumDeclSyntax.self) else { return visited }
    result.memberBlock = rewriteMembers(result.memberBlock, framework: framework)
    return DeclSyntax(result)
  }

  // MARK: - Member Rewriting

  private func rewriteMembers(_ memberBlock: MemberBlockSyntax, framework: TestFramework) -> MemberBlockSyntax {
    var newMembers = [MemberBlockItemSyntax]()
    var changed = false

    for member in memberBlock.members {
      guard let funcDecl = member.decl.as(FunctionDeclSyntax.self),
        shouldAddTestAnnotation(funcDecl, framework: framework)
      else {
        newMembers.append(member)
        continue
      }

      var modifiedFunc = funcDecl
      switch framework {
      case .swiftTesting:
        modifiedFunc = addTestAttribute(to: modifiedFunc)
        diagnose(.addTestAttribute, on: funcDecl.funcKeyword)
      case .xcTest:
        modifiedFunc = addTestPrefix(to: modifiedFunc)
        diagnose(.addTestPrefix(name: funcDecl.name.text), on: funcDecl.name)
      }
      changed = true
      newMembers.append(member.with(\.decl, DeclSyntax(modifiedFunc)))
    }

    guard changed else { return memberBlock }
    return memberBlock.with(\.members, MemberBlockItemListSyntax(newMembers))
  }

  private func shouldAddTestAnnotation(_ funcDecl: FunctionDeclSyntax, framework: TestFramework) -> Bool {
    let name = funcDecl.name.text

    if funcDecl.hasAttribute("Test", inModule: "Testing") { return false }

    let modifiers = funcDecl.modifiers
    if modifiers.contains(where: { $0.name.tokenKind == .keyword(.override) }) { return false }
    if modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) }) { return false }
    if funcDecl.attributes.attribute(named: "objc") != nil { return false }
    if modifiers.contains(where: {
      $0.name.tokenKind == .keyword(.private) || $0.name.tokenKind == .keyword(.fileprivate)
    }) { return false }

    guard funcDecl.signature.parameterClause.parameters.isEmpty,
      funcDecl.signature.returnClause == nil
    else { return false }

    if hasDisabledPrefix(name) { return false }

    if framework == .xcTest {
      if name.hasPrefix("test") { return false }
      if (identifierCounts[name] ?? 0) > 1 { return false }
    }

    return true
  }

  // MARK: - Transformations

  private func addTestAttribute(to funcDecl: FunctionDeclSyntax) -> FunctionDeclSyntax {
    var result = funcDecl
    let testAttr = AttributeSyntax(
      atSign: .atSignToken(trailingTrivia: []),
      attributeName: IdentifierTypeSyntax(name: .identifier("Test"))
    )
    var attrs = Array(result.attributes)
    var newElement = AttributeListSyntax.Element(testAttr)
    newElement.trailingTrivia = .space
    newElement.leadingTrivia = result.funcKeyword.leadingTrivia
    result.funcKeyword = result.funcKeyword.with(\.leadingTrivia, [])
    attrs.append(newElement)
    result.attributes = AttributeListSyntax(attrs)
    return result
  }

  private func addTestPrefix(to funcDecl: FunctionDeclSyntax) -> FunctionDeclSyntax {
    let name = funcDecl.name.text
    let newName = "test" + name.prefix(1).uppercased() + name.dropFirst()
    return funcDecl.with(\.name, funcDecl.name.with(\.tokenKind, .identifier(newName)))
  }
}

extension Finding.Message {
  fileprivate static let addTestAttribute: Finding.Message =
    "add '@Test' attribute to test function"
  fileprivate static func addTestPrefix(name: String) -> Finding.Message {
    "add 'test' prefix to test function '\(name)'"
  }
}
