import Testing
import Foundation
import GeneratorKit

/// Covers the build-time check that every declared rewrite hook reaches a dispatcher.
@Suite
struct RewriteDispatchAuditTests {
    /// The real rule tree must stay fully dispatched. A new hook on a node kind nothing runs is the
    /// silent no-op this check exists to catch.
    @Test func realSourceTreeHasNoGaps() async throws {
        let paths = GeneratePaths.filePath
        let collector = RewriteHookCollector()
        try await collector.collect(from: paths.rulesFolder)
        let gaps = try RewriteDispatchAudit.gaps(
            in: collector,
            dispatchers: RewriteDispatchAudit.handWrittenDispatchers(for: paths)
        )
        #expect(gaps.isEmpty, "\(gaps.joined(separator: "\n"))")
    }

    /// A rule with no `rewriteOrder` has no position in the generated pipeline, so the generator
    /// drops it. Only the hand-written dispatchers may take an unordered rule.
    @Test func reportsHookWithoutRewriteOrder() async throws {
        let tree = try TempTree()
        try tree.writeRule(
            "SortLabels",
            """
            final class SortLabels: StaticFormatRule {
                static func transform(
                    _ node: LabeledExprSyntax, original: LabeledExprSyntax,
                    parent: Syntax?, context: Context
                ) -> LabeledExprSyntax { node }
            }
            """)
        let gaps = try await tree.gaps()

        #expect(gaps.count == 1)
        #expect(gaps.first?.contains("SortLabels") == true)
        #expect(gaps.first?.contains("rewriteOrder") == true)
    }

    /// A `SourceFileSyntax` transform runs from `rewriteSourceFile` over the settled tree. The
    /// generated pipeline emits no call for it, so a rule the dispatcher never names does nothing.
    @Test func reportsFileTransformTheDispatcherNeverCalls() async throws {
        let tree = try TempTree()
        try tree.writeRule(
            "RewriteHeader",
            """
            final class RewriteHeader: StaticFormatRule {
                static let rewriteOrder = 10

                static func transform(
                    _ node: SourceFileSyntax, original: SourceFileSyntax,
                    parent: Syntax?, context: Context
                ) -> SourceFileSyntax { node }
            }
            """)
        try tree.writeSourceFileDispatcher(calling: [])
        let gaps = try await tree.gaps()

        #expect(gaps.count == 1)
        #expect(gaps.first?.contains("RewriteHeader") == true)
        #expect(gaps.first?.contains("SourceFileSyntax") == true)
    }

    /// The same rule passes once the dispatcher calls it.
    @Test func acceptsFileTransformTheDispatcherCalls() async throws {
        let tree = try TempTree()
        try tree.writeRule(
            "RewriteHeader",
            """
            final class RewriteHeader: StaticFormatRule {
                static let rewriteOrder = 10

                static func transform(
                    _ node: SourceFileSyntax, original: SourceFileSyntax,
                    parent: Syntax?, context: Context
                ) -> SourceFileSyntax { node }
            }
            """)
        try tree.writeSourceFileDispatcher(calling: ["RewriteHeader"])

        #expect(try await tree.gaps().isEmpty)
    }

    /// `rewriteToken` fixes the token rule order itself, so a token rule needs no `rewriteOrder` .
    /// It still has to appear in that function.
    @Test func acceptsUnorderedTokenRuleTheDispatcherCalls() async throws {
        let tree = try TempTree()
        try tree.writeRule(
            "TrimBackticks",
            """
            final class TrimBackticks: StaticFormatRule {
                static func transform(
                    _ node: TokenSyntax, original: TokenSyntax,
                    parent: Syntax?, context: Context
                ) -> TokenSyntax { node }
            }
            """)
        try tree.writeTokenDispatcher(calling: ["TrimBackticks"])

        #expect(try await tree.gaps().isEmpty)
    }

    /// A token is a leaf, so `rewriteToken` runs no scope hook. A `willEnter` on `TokenSyntax`
    /// never fires.
    @Test func reportsTokenScopeHookNothingRuns() async throws {
        let tree = try TempTree()
        try tree.writeRule(
            "TrimBackticks",
            """
            final class TrimBackticks: StaticFormatRule {
                static func willEnter(_ node: TokenSyntax, context: Context) {}

                static func transform(
                    _ node: TokenSyntax, original: TokenSyntax,
                    parent: Syntax?, context: Context
                ) -> TokenSyntax { node }
            }
            """)
        try tree.writeTokenDispatcher(calling: ["TrimBackticks"])
        let gaps = try await tree.gaps()

        #expect(gaps.count == 1)
        #expect(gaps.first?.contains("willEnter") == true)
    }
}

// MARK: - Fixture

/// A throwaway rule tree plus the two hand-written dispatcher files the audit reads.
private final class TempTree {
    let root: URL
    let rules: URL
    let sourceFileDispatcher: URL
    let tokenDispatcher: URL

    init() throws {
        root = FileManager.default.temporaryDirectory
            .appending(path: "RewriteDispatchAudit-\(UUID().uuidString)")
        rules = root.appending(path: "Rules")
        sourceFileDispatcher = root.appending(path: "SourceFile.swift")
        tokenDispatcher = root.appending(path: "LayoutWriter.swift")
        try FileManager.default.createDirectory(at: rules, withIntermediateDirectories: true)
        try writeSourceFileDispatcher(calling: [])
        try writeTokenDispatcher(calling: [])
    }

    deinit { try? FileManager.default.removeItem(at: root) }

    func writeRule(_ name: String, _ source: String) throws {
        try "import SwiftSyntax\n\n\(source)\n"
            .write(to: rules.appending(path: "\(name).swift"), atomically: true, encoding: .utf8)
    }

    func writeSourceFileDispatcher(calling rules: [String]) throws {
        try dispatcher(named: "rewriteSourceFile", node: "SourceFileSyntax", calling: rules)
            .write(to: sourceFileDispatcher, atomically: true, encoding: .utf8)
    }

    func writeTokenDispatcher(calling rules: [String]) throws {
        try dispatcher(named: "rewriteToken", node: "TokenSyntax", calling: rules)
            .write(to: tokenDispatcher, atomically: true, encoding: .utf8)
    }

    func gaps() async throws -> [String] {
        let collector = RewriteHookCollector()
        try await collector.collect(from: rules)
        return try RewriteDispatchAudit.gaps(
            in: collector,
            dispatchers: [
                .init(node: "SourceFileSyntax", hooks: [.transform], file: sourceFileDispatcher),
                .init(
                    node: "TokenSyntax", hooks: [.transform, .willEnter, .didExit],
                    file: tokenDispatcher),
            ])
    }

    private func dispatcher(named name: String, node: String, calling rules: [String]) -> String {
        let calls = rules.map {
            "    result = \($0).transform(\n"
                + "        result, original: node, parent: nil, context: context)\n"
        }.joined()
        return """
            import SwiftSyntax

            func \(name)(_ node: \(node), parent _: Syntax?, context: Context) -> \(node) {
                var result = node
            \(calls)    return result
            }

            """
    }
}
