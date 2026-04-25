import SwiftSyntax

/// Shared detection logic for test-related rules (`ValidateTestCases`, `TestSuiteAccessControl`,
/// `NoForceTry`).

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
    return if hasXCTest, hasTesting {
        nil
    } else if hasTesting {
        .swiftTesting
    } else if hasXCTest {
        .xcTest
    } else {
        nil
    }
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
        guard types.count == 1, types[0].type.trimmedDescription == "XCTestCase" else {
            return false
        }
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

// MARK: - Test Context Tracker

/// Tracks test-scope state for rules that need to know whether code is inside a test function.
///
/// Used by rules like `NoForceTry`, `NoForceUnwrap`, and `NoGuardInTests` that behave differently
/// inside test functions (e.g. auto-fixing `try!` → `try`). Compose as a stored property and
/// forward visitor calls.
///
/// ```swift
/// private var testContext = TestContextTracker()
///
/// override func visit(_ node: ImportDeclSyntax) -> DeclSyntax {
///   testContext.visitImport(node)
///   return DeclSyntax(node)
/// }
///
/// override func visit(_ node: SourceFileSyntax) -> SourceFileSyntax {
///   testContext.visitSourceFile(node, context: context)
///   return super.visit(node)
/// }
/// ```
struct TestContextTracker {
    private(set) var importsTesting = false
    private(set) var insideXCTestCase = false

    /// Call from `visit(_ node: ImportDeclSyntax)`.
    mutating func visitImport(_ node: ImportDeclSyntax) {
        if node.path.first?.name.text == "Testing" { importsTesting = true }
    }

    /// Call from `visit(_ node: SourceFileSyntax)`.
    mutating func visitSourceFile(_ node: SourceFileSyntax, context: Context) {
        setImportsXCTest(context: context, sourceFile: node)
    }

    /// Call at the start of `visit(_ node: ClassDeclSyntax)`. Returns the previous value of
    /// `insideXCTestCase` — restore it in a `defer` block.
    mutating func pushClass(_ node: ClassDeclSyntax, context: Context) -> Bool {
        let was = insideXCTestCase

        if context.importsXCTest == .importsXCTest,
            let inheritance = node.inheritanceClause,
            inheritance.contains(named: "XCTestCase")
        {
            insideXCTestCase = true
        }
        return was
    }

    /// Restore `insideXCTestCase` to the value returned by `pushClass(_:context:)`.
    mutating func popClass(was: Bool) { insideXCTestCase = was }

    /// Whether the given function declaration is a test function.
    ///
    /// A function is a test function if:
    /// - It has the `@Test` attribute (Swift Testing), or
    /// - It's inside an `XCTestCase` subclass and named `test*()` with no parameters and no return.
    func isTestFunction(_ node: FunctionDeclSyntax) -> Bool {
        if importsTesting, node.hasAttribute("Test", inModule: "Testing") { return true }

        if insideXCTestCase {
            let name = node.name.text
            return name.hasPrefix("test")
                && node.signature.parameterClause.parameters.isEmpty
                && node.signature.returnClause == nil
        }
        return false
    }
}
