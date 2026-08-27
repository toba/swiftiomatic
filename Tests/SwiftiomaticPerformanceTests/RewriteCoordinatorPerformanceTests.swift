//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import XCTest
import SwiftParser
import SwiftSyntax
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

/// Locks in baseline timing for full single-file format (parse + rewrite pipeline + pretty-print),
/// the operation invoked when Xcode's "Format with swift-format" runs against the active file.
///
/// The compact pipeline (`CompactSyntaxRewriter` + 13 ordered structural passes from epic
/// `iv7-r5g`/`ddi-wtv`) replaced the legacy per-rule sequential walk and brought the rewrite phase
/// well under 200 ms even on the largest file in the repo.
final class RewriteCoordinatorPerformanceTests: PerformanceTestCase {
    /// Representative ~50-line snippet, repeated to exercise scaling behavior. Mirrors a typical
    /// active-file format in Xcode (a few hundred lines of mixed declarations and bodies).
    private static let representativeSource: String = .init(
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

    func testFullFormatPipelinePerformance() throws {
        let source = Self.representativeSource
        measureIfNotInCI {
            var output = ""
            let coordinator = RewriteCoordinator(configuration: Configuration())
            try? coordinator.format(
                source: source,
                assumingFileURL: URL(fileURLWithPath: "/tmp/perf.swift"),
                selection: .infinite,
                to: &output
            )
        }
    }

    /// The compact pipeline (`CompactSyntaxRewriter` + 13 ordered structural passes) on
    /// `LayoutCoordinator.swift` — the largest source file in the repo and the perf gate from epic
    /// `iv7-r5g`.
    ///
    /// The two-stage path must finish well under 200 ms wall-clock when running release-built.
    /// Rewrite-only timing is reported via `measure`; visual inspection of the `XCTest` performance
    /// baseline confirms the budget.
    func testTwoStageCompactPipelineOnLayoutCoordinator() throws {
        let layoutCoordinator = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()  // SwiftiomaticPerformanceTests
            .deletingLastPathComponent()  // Tests
            .deletingLastPathComponent()  // repo root
            .appendingPathComponent("Sources/SwiftiomaticKit/Layout/LayoutCoordinator.swift")

        let source = try String(contentsOf: layoutCoordinator, encoding: .utf8)
        let sourceFile = Parser.parse(source: source)

        measureIfNotInCI {
            let context = makeTestContext(
                sourceFileSyntax: sourceFile, selection: .infinite, findingConsumer: { _ in })
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
            _ = current
        }
    }
}
