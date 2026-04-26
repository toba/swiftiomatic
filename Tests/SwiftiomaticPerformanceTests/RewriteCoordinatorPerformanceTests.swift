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

@testable import SwiftiomaticKit
import SwiftParser
import SwiftSyntax
import SwiftiomaticTestSupport
import XCTest

/// Locks in baseline timing for full single-file format (parse + rewrite pipeline + pretty-print),
/// the operation invoked when Xcode's "Format with swift-format" runs against the active file.
///
/// See `.issues/q/qm5-qyp` — the dominant cost is `RewritePipeline.rewrite()` running each of
/// ~137 format rules sequentially over the entire AST. Use this benchmark to detect regressions
/// or measure improvements (e.g. coalescing rule passes).
final class RewriteCoordinatorPerformanceTests: XCTestCase {
  /// In CI, just exercise the path; locally, capture timing.
  private func measureIfNotInCI(_ block: () -> Void) {
    if ProcessInfo.processInfo.environment["SWIFTCI_USE_LOCAL_DEPS"] != nil {
      block()
    } else {
      measure { block() }
    }
  }

  /// Representative ~50-line snippet, repeated to exercise scaling behavior. Mirrors a typical
  /// active-file format in Xcode (a few hundred lines of mixed declarations and bodies).
  private static let representativeSource: String = String(
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

  func testRewritePipelineOnlyPerformance() throws {
    let source = Self.representativeSource
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
}
