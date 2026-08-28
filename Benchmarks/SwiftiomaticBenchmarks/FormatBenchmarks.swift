import Benchmark
import SwiftParser
import SwiftSyntax
@testable import SwiftiomaticKit

/// Timing for full single-file format, the operation Xcode runs against the active file
///
/// The compact pipeline is `CompactSyntaxRewriter` plus the ordered structural passes. It replaced
/// the per-rule sequential walk and brought the rewrite phase well under 200 ms even on the largest
/// file in the repository.
func registerFormatBenchmarks() {
    Benchmark(
        "FormatFullPipeline",
        configuration: .init(thresholds: Tolerance.steady)
    ) { benchmark in
        let source = representativeSource
        benchmark.startMeasurement()
        var output = ""
        let coordinator = RewriteCoordinator(configuration: Configuration())
        try? coordinator.format(
            source: source,
            assumingFileURL: Fixture.scratchFileURL,
            selection: .infinite,
            to: &output
        )
        blackHole(output)
    }

    Benchmark(
        "FormatTwoStageCompactGateFile",
        configuration: .init(thresholds: Tolerance.steady)
    ) { benchmark in
        let sourceFile = Parser.parse(source: Fixture.perfGateSource())
        let context = Fixture.context(for: sourceFile)
        benchmark.startMeasurement()
        var current = RewritePipeline(context: context).rewrite(Syntax(sourceFile))
        current = SortImports(context: context).rewrite(current)
        current = InsertBlankLineAfterImports(context: context).rewrite(current)
        current = UseFilePrivateForFileLocal(context: context).rewrite(current)
        current = HoistExtensionAccess(context: context).rewrite(current)
        current = InsertBlankLineBetweenScopes(context: context).rewrite(current)
        current = SortDeclarations(context: context).rewrite(current)
        current = SortSwitchCases(context: context).rewrite(current)
        current = SortTypeAliases(context: context).rewrite(current)
        current = FileHeader(context: context).rewrite(current)
        blackHole(current)
    }
}

/// A short snippet repeated to reach the size of a typical active file in Xcode
///
/// This one is synthetic on purpose. It carries mixed declarations and bodies so many rules fire,
/// which a single real file does not guarantee.
private let representativeSource = String(
    repeating: """
        import Foundation
        import SwiftSyntax

        /// A representative declaration with mixed concerns to exercise many rules.
        public final class WidgetController: NSObject, WidgetProviding {
            private let store: WidgetStore
            private var cache: [String: Widget] = [:]

            public init(store: WidgetStore) {
                self.store = store
                super.init()
            }

            public func loadWidgets(matching query: String, completion: @escaping (Result<[Widget], Error>) -> Void) {
                guard !query.isEmpty else {
                    completion(.success([]))
                    return
                }
                store.fetch(query: query) { result in
                    switch result {
                    case .success(let widgets):
                        let filtered = widgets.filter { $0.isEnabled && $0.name.contains(query) }
                        completion(.success(filtered))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }

            public func widget(named name: String) -> Widget? {
                if let cached = cache[name] { return cached }
                return nil
            }
        }

        """,
    count: 8
)
