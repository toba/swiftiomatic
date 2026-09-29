import Foundation
import SwiftSyntax

/// Shared detection logic for test-related rules ( `RequireTestFnPrefixOrAttribute` ,
/// `RequireSuiteAccessControl` , `NoForceTry` ). The testing framework detected from imports.
enum TestFramework { case xcTest, swiftTesting }

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

    // Skip types whose name carries Base as its own word. A substring test also rejected
    // BaseballTests.
    if name.containsCapitalizedWord("Base") { return false }

    // Skip types documented as a base class or as something to subclass. A substring test also
    // rejected every suite whose documentation mentions a database.
    if leadingTrivia.mentionsBaseClass { return false }

    // For XCTest: must be a class with exactly XCTestCase conformance
    if framework == .xcTest {
        guard let inheritance = inheritanceClause else { return false }
        let types = Array(inheritance.inheritedTypes)
        guard types.count == 1, types[0].type.trimmedDescriptionEquals("XCTestCase")
        else { return false }
        return true
    }

    // For Swift Testing: type name must end with a test suffix
    return testSuiteSuffixes.contains(where: { name.hasSuffix($0) })
}

private extension Trivia {
    /// Whether a comment in the trivia holds `base` or `subclass` as its own word, in any case.
    ///
    /// The scan reads each piece in place. Only a piece that can hold a word is checked: a
    /// comment or unexpected text. A whitespace piece cannot hold one, and a piece boundary is
    /// never a letter, so the result is the same as a scan of the full trivia text.
    ///
    /// A piece is lowercased only when its bytes hold one of the words in ASCII, in any case. Most
    /// comments hold neither word, so the common path allocates nothing.
    var mentionsBaseClass: Bool {
        contains { piece in
            let text: String
            switch piece {
                case let .lineComment(t), let .blockComment(t), let .docLineComment(t),
                     let .docBlockComment(t), let .unexpectedText(t):
                    text = t
                default: return false
            }
            guard text.utf8.containsASCIICaseInsensitive("base")
                || text.utf8.containsASCIICaseInsensitive("subclass")
            else { return false }
            let lower = text.lowercased()
            return lower.containsWord("base") || lower.containsWord("subclass")
        }
    }
}

private extension String.UTF8View {
    /// Whether the bytes hold `word` , with ASCII letters compared in any case.
    ///
    /// `word` is lowercase ASCII.
    func containsASCIICaseInsensitive(_ word: StaticString) -> Bool {
        word.withUTF8Buffer { needle in
            guard let first = unsafe needle.first else { return true }
            var start = startIndex
            while let found = self[start...].firstIndex(where: { $0 | 0x20 == first }) {
                var candidate = found
                var matched = true
                for unsafe byte in unsafe needle {
                    guard candidate != endIndex, self[candidate] | 0x20 == byte else {
                        matched = false
                        break
                    }
                    formIndex(after: &candidate)
                }
                if matched { return true }
                start = index(after: found)
            }
            return false
        }
    }
}

private extension String {
    /// Whether `word` appears bounded by non-alphanumeric characters.
    ///
    /// Both operands are lowercased by the caller.
    func containsWord(_ word: String) -> Bool {
        var searchStart = startIndex

        while let found = range(of: word, range: searchStart..<endIndex) {
            let beforeIsLetter = found.lowerBound > startIndex
                && self[index(before: found.lowerBound)].isLetterOrDigit
            let afterIsLetter = found.upperBound < endIndex
                && self[found.upperBound].isLetterOrDigit
            if !beforeIsLetter, !afterIsLetter { return true }
            searchStart = index(after: found.lowerBound)
        }
        return false
    }

    /// Whether `word` appears as its own capitalized word inside a camel-case identifier.
    ///
    /// A word ends where the next capital starts or where the identifier ends, so `Base` matches in
    /// `BaseTests` and not in `BaseballTests`.
    func containsCapitalizedWord(_ word: String) -> Bool {
        var searchStart = startIndex

        while let found = range(of: word, range: searchStart..<endIndex) {
            let afterStartsNewWord = found.upperBound == endIndex
                || !self[found.upperBound].isLowercase
            if afterStartsNewWord { return true }
            searchStart = index(after: found.lowerBound)
        }
        return false
    }
}

private extension Character {
    var isLetterOrDigit: Bool { isLetter || isNumber }
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
/// Used by rules like `NoForceTry` , `NoForceUnwrap` , and `NoGuardInTests` that behave differently
/// inside test functions (e.g. auto-fixing `try!` → `try` ). Compose as a stored property and
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

    /// Call from `visit(_ node: ImportDeclSyntax)` .
    mutating func visitImport(_ node: ImportDeclSyntax) {
        if node.path.first?.name.text == "Testing" { importsTesting = true }
    }

    /// Call from `visit(_ node: SourceFileSyntax)` .
    mutating func visitSourceFile(_ node: SourceFileSyntax, context: Context) {
        setImportsAnyTestLibrary(context: context, sourceFile: node)
    }

    /// Call at the start of `visit(_ node: ClassDeclSyntax)` . Returns the previous value of
    /// `insideXCTestCase` — restore it in a `defer` block.
    mutating func pushClass(_ node: ClassDeclSyntax, context: Context) -> Bool {
        let was = insideXCTestCase

        if context.importsAnyTestLibrary == .importsTestLibrary,
           let inheritance = node.inheritanceClause,
           inheritance.contains(named: "XCTestCase") { insideXCTestCase = true }
        return was
    }

    /// Restore `insideXCTestCase` to the value returned by `pushClass(_:context:)` .
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
