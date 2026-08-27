import Testing
import SwiftParser
import SwiftSyntax
import SwiftOperators
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

/// Holds the inline-mode pipeline to output that still parses when a line comment sits between the
/// last condition and an opening brace on its own line
///
/// A line comment runs to the end of its line, so an inline that pulls the brace up buries the body
/// in comment text and the file stops parsing. A rule that clears the trivia instead drops the
/// comment outright. `SingleLineBodiesInlineTests` and `CollapseSimpleIfElseTests` cover the
/// `LayoutSingleLineBodies` and `CollapseSimpleIfElse` guards in isolation. These tests run the
/// whole `RewriteCoordinator`, because the pretty printer moves the same trivia a second time and a
/// rule-only test never sees that pass.
@Suite
struct CommentBeforeBracePipelineTests {
    @Test func ifBodyStaysOutsideTrailingCommentOnLastCondition() throws {
        let output = try inlineFormatted(
            """
            func lookup(_ key: String) -> [Int]? {
                var fifo = Array(prefetches)
                while !fifo.isEmpty {
                    let (prefetchKey, prefetch) = fifo.removeFirst()
                    if prefetchKey == key,
                       let rows = prefetch.rows // nil for "through" associations
                    {
                        return rows
                    }
                    fifo.append(contentsOf: prefetch.prefetches)
                }
                return nil
            }
            """)

        expectParses(output)
        #expect(output.contains("nil for"))
    }

    @Test func guardBodyStaysOutsideTrailingCommentOnLastCondition() throws {
        let output = try inlineFormatted(
            """
            func lookup(_ a: Bool, _ b: Int?) -> Int {
                guard a,
                      let value = b // absent for a detached node
                else {
                    return 0
                }
                return value
            }
            """)

        expectParses(output)
        #expect(output.contains("absent for a detached node"))
    }

    @Test func whileBodyStaysOutsideTrailingCommentOnLastCondition() throws {
        let output = try inlineFormatted(
            """
            func drain(_ a: Bool, _ b: Bool) {
                while a,
                      b // the queue refills on every pass
                {
                    step()
                }
            }
            """)

        expectParses(output)
        #expect(output.contains("the queue refills on every pass"))
    }

    @Test func closureBodyStaysOutsideTrailingCommentBeforeBrace() throws {
        let output = try inlineFormatted(
            """
            func attach() {
                register(
                    handler:  // the caller retains the closure
                    {
                        fire()
                    })
            }
            """)

        expectParses(output)
        #expect(output.contains("the caller retains the closure"))
    }

    @Test func collapseKeepsTrailingCommentOnLastCondition() throws {
        let output = try collapseFormatted(
            """
            func f(_ a: Bool, _ c: Int?) -> Int {
                if a,
                   let v = c // three
                {
                    return v
                } else {
                    return 0
                }
            }
            """)

        expectParses(output)
        #expect(output.contains("three"))
    }

    /// Runs the whole rewrite pipeline with `layoutSingleLineBodies` in inline mode
    private func inlineFormatted(_ source: String) throws -> String {
        var configuration = Configuration.forTesting
        configuration[LayoutSingleLineBodies.self] = {
            var value = LayoutSingleLineBodiesConfiguration()
            value.mode = .inline
            return value
        }()
        return try formatted(source, configuration: configuration)
    }

    /// Runs the whole rewrite pipeline with `collapseSimpleIfElse` as the only rewrite rule
    private func collapseFormatted(_ source: String) throws -> String {
        try formatted(source, configuration: .forTesting(enabledRule: CollapseSimpleIfElse.key))
    }

    private func formatted(_ source: String, configuration: Configuration) throws -> String {
        let coordinator = RewriteCoordinator(configuration: configuration)
        let tree = Parser.parse(source: source)
        let sourceFile = try OperatorTable.standardOperators.foldAll(tree).as(
            SourceFileSyntax.self)!
        var output = ""
        try coordinator.format(
            syntax: sourceFile,
            source: source,
            operatorTable: .standardOperators,
            assumingFileURL: nil,
            selection: .infinite,
            to: &output)
        return output
    }

    /// A missing or unexpected node marks the tree, so `hasError` reports source the parser could
    /// not read back
    private func expectParses(
        _ output: String,
        sourceLocation: Testing.SourceLocation = #_sourceLocation
    ) {
        #expect(!Parser.parse(source: output).hasError, "\(output)", sourceLocation: sourceLocation)
    }
}
