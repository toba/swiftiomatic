import Foundation
import SwiftParser
import SwiftSyntax
import SwiftOperators
@testable import SwiftiomaticKit

/// The source files and contexts every benchmark in this target measures against
///
/// The fixtures are real repository sources rather than synthetic input. A synthetic file drifts
/// from what `sm` meets in practice, and the figures then track nothing.
enum Fixture {
    /// The repository root, derived from this file's own path.
    static let repositoryRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()  // SwiftiomaticBenchmarks
        .deletingLastPathComponent()  // Benchmarks
        .deletingLastPathComponent()  // repo root

    /// The largest source file in the repository, used as the gate for the lint and rewrite walks.
    static func perfGateSource() -> String {
        source(at: "Sources/SwiftiomaticKit/Layout/LayoutCoordinator.swift")
    }

    /// A real source file at the repository's median line count.
    ///
    /// The store benchmarks read this rather than the gate file. Store cost is close to fixed while
    /// lint cost scales with the file, so the gate file makes any fixed cost look free.
    static func medianSizedSource() -> String {
        source(at: "Sources/SwiftiomaticKit/Syntax/Parsing.swift")
    }

    static func source(at relativePath: String) -> String {
        let url = repositoryRoot.appendingPathComponent(relativePath)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            fatalError("benchmark fixture missing at \(url.path)")
        }
        return text
    }

    /// Builds the `Context` a rule walk needs.
    ///
    /// This mirrors `makeTestContext` in `SwiftiomaticTestSupport`. That target is not a package
    /// product, so a benchmark cannot import it.
    static func context(for sourceFile: SourceFileSyntax) -> Context {
        .init(
            configuration: Configuration(),
            operatorTable: .standardOperators,
            findingConsumer: { _ in },
            fileURL: URL(fileURLWithPath: "/tmp/benchmark.swift"),
            selection: .infinite,
            sourceFileSyntax: sourceFile
        )
    }

    /// Stand-in path for a file that is never written
    static let scratchFileURL = URL(fileURLWithPath: "/tmp/benchmark.swift")
}
