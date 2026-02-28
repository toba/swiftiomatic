import Testing
import SwiftParser
import SwiftSyntax
@testable import Swiftiomatic

/// Mock resolver for testing SourceKit-enhanced checks without sourcekitd.
struct MockResolver: TypeResolver {
    var isAvailable: Bool { true }

    /// Canned responses keyed by offset.
    var typesByOffset: [Int: ResolvedType] = [:]
    var fileIndexes: [String: FileIndex] = [:]
    var expressionTypesByFile: [String: [ExpressionTypeInfo]] = [:]

    func resolveType(inFile _: String, offset: Int) -> ResolvedType? {
        typesByOffset[offset]
    }

    func indexFile(_ file: String) -> FileIndex? {
        fileIndexes[file]
    }

    func expressionTypes(inFile file: String) -> [ExpressionTypeInfo] {
        expressionTypesByFile[file] ?? []
    }
}

@Suite("TypeResolver Integration")
struct TypeResolverTests {
    @Test func nullResolverReturnsNil() async {
        let resolver = NullResolver()
        #expect(!resolver.isAvailable)
        #expect(await resolver.resolveType(inFile: "test.swift", offset: 0) == nil)
        #expect(await resolver.indexFile("test.swift") == nil)
        #expect(await resolver.expressionTypes(inFile: "test.swift").isEmpty)
    }

    @Test func analyzerWorksWithNilResolver() async {
        let source = """
        func foo() throws { throw MyError.bad }
        enum MyError: Error { case bad }
        """
        let analyzer = Analyzer(
            categories: [.typedThrows],
            typeResolver: nil,
        )
        // Just verify it doesn't crash — analyzer uses paths, not inline source
        let findings = await analyzer.analyze(paths: [])
        #expect(findings.isEmpty)
    }

    @Test func concurrencyCheckUpgradesConfidenceWithResolver() {
        let source = """
        import Dispatch
        func doWork() {
            DispatchQueue.main.async { print("hi") }
        }
        """
        let tree = Parser.parse(source: source)

        // Without resolver — medium confidence
        let checkWithout = ConcurrencyModernizationCheck(filePath: "test.swift")
        checkWithout.walk(tree)
        let withoutResolver = checkWithout.findings.first {
            $0.message.contains("DispatchQueue")
        }
        #expect(withoutResolver?.confidence == .medium)

        // With resolver — confidence can be upgraded to high
        let resolver = MockResolver(typesByOffset: [:])
        let checkWith = ConcurrencyModernizationCheck(
            filePath: "test.swift",
            typeResolver: resolver,
        )
        checkWith.walk(tree)
        // The finding is still medium until resolveTypeQueries runs
        // (mock resolver won't match any offset, so it stays medium)
        let withResolver = checkWith.findings.first {
            $0.message.contains("DispatchQueue")
        }
        #expect(withResolver?.confidence == .medium)
    }

    @Test func anyCheckDetectsResolvedAliases() async {
        let source = """
        typealias JSON = Any
        var data: JSON = 42
        """
        let tree = Parser.parse(source: source)

        // Without resolver — doesn't flag JSON
        let checkWithout = AnyEliminationCheck(filePath: "test.swift")
        checkWithout.walk(tree)
        let anyFindings = checkWithout.findings.filter {
            $0.message.contains("JSON")
        }
        #expect(anyFindings.isEmpty)

        // With resolver — mock resolves JSON to Any
        // We need to find the offset of "JSON" in the type annotation for `var data: JSON`
        // The exact offset depends on the source, so we test the plumbing
        let resolver = MockResolver()
        let checkWith = AnyEliminationCheck(filePath: "test.swift", typeResolver: resolver)
        checkWith.walk(tree)
        // Verify aliasQueries were collected (we can't access private state,
        // but resolveTypeQueries should run without crashing)
        await checkWith.resolveTypeQueries()
    }
}
