@testable import SwiftiomaticKit
import SwiftParser
import SwiftSyntax
import SwiftiomaticTestSupport
import XCTest

/// Spike `eti-yt2`: validate the architectural premise that combining several node-local
/// rewrites into a single tree walk is dramatically cheaper than running them sequentially
/// as full-tree walks.
///
/// The combined rewriter (`CombinedRewriter`) fuses three rules whose visit methods touch
/// distinct node types: `RedundantBreak` (`SwitchCaseSyntax`), `NoBacktickedSelf`
/// (`OptionalBindingConditionSyntax`), `RedundantNilInit` (`VariableDeclSyntax`).
///
/// We compare:
/// - **Combined**: one walk, one rewriter, three visit overrides.
/// - **Sequential**: three walks, one per rule, mirroring today's `RewritePipeline`.
///
/// The benchmark target source is the same representative ~400-line snippet used by
/// `RewriteCoordinatorPerformanceTests`.
final class CombinedRewriterSpikeTests: XCTestCase {
    private func measureIfNotInCI(_ block: () -> Void) {
        if ProcessInfo.processInfo.environment["SWIFTCI_USE_LOCAL_DEPS"] != nil {
            block()
        } else {
            measure { block() }
        }
    }

    private static let representativeSource: String = String(
        repeating: """
            import Foundation
            import SwiftSyntax

            public final class WidgetController: NSObject, WidgetProviding {
                private let store: WidgetStore
                private var cache: [String: Widget]? = nil
                private var pending: Set<String>? = nil

                public init(store: WidgetStore) {
                    self.store = store
                    super.init()
                }

                public func loadWidgets(matching query: String) {
                    guard let `self` = self else { return }
                    switch query {
                    case "":
                        return
                        break
                    case "all":
                        loadAll()
                        break
                    default:
                        break
                    }
                }
            }

            """,
        count: 8
    )

    func testCombinedRewriterPerformance() {
        let source = Self.representativeSource
        let sourceFile = Parser.parse(source: source)
        measureIfNotInCI {
            let rewriter = CombinedRewriter()
            _ = rewriter.rewrite(Syntax(sourceFile))
        }
    }

    func testSequentialRewritersPerformance() {
        let source = Self.representativeSource
        let sourceFile = Parser.parse(source: source)
        let context = makeTestContext(
            sourceFileSyntax: sourceFile,
            selection: .infinite,
            findingConsumer: { _ in }
        )
        measureIfNotInCI {
            var node = Syntax(sourceFile)
            node = RedundantBreak(context: context).rewrite(node)
            node = NoBacktickedSelf(context: context).rewrite(node)
            node = RedundantNilInit(context: context).rewrite(node)
        }
    }

    /// Bench against the project's worst-case file (`LayoutCoordinator.swift`, ~956 lines)
    /// per the spike's stated baseline in `eti-yt2`.
    private func loadLayoutCoordinator() -> String {
        let candidates = [
            URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("Sources/SwiftiomaticKit/Layout/LayoutCoordinator.swift"),
        ]
        for url in candidates {
            if let contents = try? String(contentsOf: url, encoding: .utf8) { return contents }
        }
        return ""
    }

    func testCombinedRewriterOnLayoutCoordinator() {
        let source = loadLayoutCoordinator()
        guard !source.isEmpty else {
            XCTFail("could not locate LayoutCoordinator.swift baseline")
            return
        }
        let sourceFile = Parser.parse(source: source)
        measureIfNotInCI {
            let rewriter = CombinedRewriter()
            _ = rewriter.rewrite(Syntax(sourceFile))
        }
    }

    func testFullRewritePipelineOnLayoutCoordinator() {
        let source = loadLayoutCoordinator()
        guard !source.isEmpty else {
            XCTFail("could not locate LayoutCoordinator.swift baseline")
            return
        }
        let sourceFile = Parser.parse(source: source)
        measureIfNotInCI {
            let context = makeTestContext(
                sourceFileSyntax: sourceFile,
                selection: .infinite,
                findingConsumer: { _ in }
            )
            let pipeline = RewritePipeline(context: context)
            _ = pipeline.rewrite(Syntax(sourceFile))
        }
    }

    /// Sanity check: the combined rewriter actually applies the three transformations.
    func testCombinedRewriterAppliesAllThree() throws {
        let input = """
            class Foo {
                var cache: [String: Int]? = nil

                func bar() {
                    guard let `self` = self else { return }
                    switch x {
                    case 1: a()
                            break
                    default: break
                    }
                }
            }
            """
        let sourceFile = Parser.parse(source: input)
        let rewriter = CombinedRewriter()
        let rewritten = rewriter.rewrite(Syntax(sourceFile)).description

        XCTAssertFalse(rewritten.contains("= nil"), "RedundantNilInit not applied")
        XCTAssertFalse(rewritten.contains("`self`"), "NoBacktickedSelf not applied")
        // The non-trivial `case 1:` body should have lost its trailing `break`.
        XCTAssertTrue(
            rewritten.contains("case 1: a()"),
            "expected case body to remain")
        XCTAssertFalse(
            rewritten.contains("a()\n                            break"),
            "RedundantBreak not applied to case 1")
    }
}
