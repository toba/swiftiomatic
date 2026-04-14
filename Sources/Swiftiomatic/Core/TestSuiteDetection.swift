import SwiftSyntax

/// Shared detection logic for test-related rules (`ValidateTestCases`, `TestSuiteAccessControl`,
/// `NoForceTryInTests`).

/// The testing framework detected from imports.
enum TestFramework {
  case xcTest, swiftTesting
}

/// Detects which testing framework is imported in the source file.
///
/// Returns `nil` when both or neither framework is imported.
func detectTestFramework(in node: SourceFileSyntax) -> TestFramework? {
  var hasXCTest = false
  var hasTesting = false
  for stmt in node.statements {
    if let importDecl = stmt.item.as(ImportDeclSyntax.self) {
      let name = importDecl.path.first?.name.text
      if name == "XCTest" { hasXCTest = true }
      if name == "Testing" { hasTesting = true }
    }
  }
  if hasXCTest && hasTesting { return nil }
  if hasTesting { return .swiftTesting }
  if hasXCTest { return .xcTest }
  return nil
}

/// Type name suffixes that indicate a test suite.
let testSuiteSuffixes = ["Tests", "TestCase", "Suite"]

/// Disabled-test prefixes (checked case-insensitively).
let disabledTestPrefixes = ["disable_", "disabled_", "skip_", "skipped_", "x_", "_"]

/// Returns `true` if the function name starts with a disabled-test prefix.
func hasDisabledPrefix(_ name: String) -> Bool {
  let lower = name.lowercased()
  return disabledTestPrefixes.contains(where: { lower.hasPrefix($0) })
}

/// Returns `true` if the type declaration looks like a test suite for the given framework.
///
/// Checks name suffix, base-class indicators, and `open` modifier.
func isTestSuite(
  name: String,
  inheritanceClause: InheritanceClauseSyntax?,
  modifiers: DeclModifierListSyntax,
  leadingTrivia: Trivia,
  framework: TestFramework
) -> Bool {
  // Skip open types (base classes)
  if modifiers.contains(where: { $0.name.tokenKind == .keyword(.open) }) { return false }

  // Skip types with "Base" in name
  if name.contains("Base") { return false }

  // Skip types with "base" or "subclass" in doc comments
  let triviaText = leadingTrivia.description.lowercased()
  if triviaText.contains("base") || triviaText.contains("subclass") { return false }

  // For XCTest: must be a class with exactly XCTestCase conformance
  if framework == .xcTest {
    guard let inheritance = inheritanceClause else { return false }
    let types = Array(inheritance.inheritedTypes)
    guard types.count == 1, types[0].type.trimmedDescription == "XCTestCase" else { return false }
    return true
  }

  // For Swift Testing: type name must end with a test suffix
  return testSuiteSuffixes.contains(where: { name.hasSuffix($0) })
}

/// Returns `true` if the member block contains an initializer with parameters.
func hasParameterizedInit(_ memberBlock: MemberBlockSyntax) -> Bool {
  memberBlock.members.contains { member in
    guard let initDecl = member.decl.as(InitializerDeclSyntax.self) else { return false }
    return !initDecl.signature.parameterClause.parameters.isEmpty
  }
}
