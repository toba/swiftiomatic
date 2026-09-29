import Benchmark
import Foundation
import SwiftParser
import SwiftSyntax
@testable import SwiftiomaticKit
import SwiftOperators

/// Timing for the per-file setup, the pretty printer, and finding emission, each on its own
///
/// The full-path benchmarks fold these costs into one figure. Each one here isolates a hot path
/// that the allocation survey in issue `e1110eb4` names, so a change to it reads off its own
/// number.
func registerHotPathBenchmarks() {
    // `Context.init` with `source:`, as `LintCoordinator` and `RewriteCoordinator` call it. This
    // covers the second parse, the `SourceLocationConverter`, the `RuleMask` directive scan and the
    // enabled-rule sets.
    Benchmark(
        "ContextInitGateFile",
        configuration: .init(thresholds: Tolerance.steady)
    ) { benchmark in
        let source = Fixture.perfGateSource()
        let sourceFile = Parser.parse(source: source)
        benchmark.startMeasurement()
        let context = Context(
            configuration: Configuration(),
            operatorTable: .standardOperators,
            findingConsumer: { _ in },
            fileURL: Fixture.scratchFileURL,
            selection: .infinite,
            sourceFileSyntax: sourceFile,
            source: source
        )
        blackHole(context)
    }

    // The pretty printer alone: token stream creation, layout, and output assembly. The rewrite
    // stages run outside the measured region.
    Benchmark(
        "LayoutGateFile",
        configuration: .init(thresholds: Tolerance.steady)
    ) { benchmark in
        let source = Fixture.perfGateSource()
        let sourceFile = Parser.parse(source: source)
        let context = Fixture.context(for: sourceFile)
        benchmark.startMeasurement()
        let printer = LayoutCoordinator(
            context: context,
            source: source,
            node: Syntax(sourceFile),
            printTokenStream: false,
            whitespaceOnly: false
        )
        blackHole(printer.prettyPrint())
    }

    // A lint where most statements produce a finding, so the message, note and warning-control
    // work per finding outweighs the walk.
    Benchmark(
        "LintFindingsHeavyFile",
        configuration: .init(thresholds: Tolerance.steady)
    ) { benchmark in
        let source = findingsHeavySource
        benchmark.startMeasurement()
        var count = 0
        let coordinator = LintCoordinator(
            configuration: Configuration(),
            findingConsumer: { _ in count += 1 }
        )
        try? coordinator.lint(source: source, assumingFileURL: Fixture.scratchFileURL)
        blackHole(count)
    }
}

/// A snippet dense with common violations, repeated to reach the size of a typical file
///
/// It is synthetic on purpose. A real repository file lints close to clean, which leaves the cost
/// per finding out of the figure.
private let findingsHeavySource = String(
    repeating: """
        import Foundation;
        class widgetcontroller : NSObject {
            var Items : Array<String> = Array<String>()
            var count : Int = 0;
            func Load(url : String) -> String {
                let data = try! Data(contentsOf: URL(string: url)!)
                let text = String(data: data, encoding: .utf8)!
                if (text.count == 0) { return "" }
                for i in 0..<Items.count { print(Items[i]) }
                let x = Items.filter({ $0.count > 0 }).count > 0
                DispatchQueue.main.async { self.count = x ? 1 : 0 }
                return text as! String
            }
        }

        """,
    count: 16
)
