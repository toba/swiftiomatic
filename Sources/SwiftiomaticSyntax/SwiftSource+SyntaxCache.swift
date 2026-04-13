package import Foundation
import SwiftDiagnostics
package import SwiftIDEUtils
import SwiftOperators
import SwiftParser
import SwiftParserDiagnostics
package import SwiftSyntax
import Synchronization

private typealias FileCacheKey = UUID

package let incrementalParseResultCache = SyntaxCache { file -> IncrementalParseResult in
  Parser.parseIncrementally(source: file.contents, parseTransition: nil)
}

package let syntaxTreeCache = SyntaxCache { file -> SourceFileSyntax in
  incrementalParseResultCache.get(file).tree
}

package let foldedSyntaxTreeCache = SyntaxCache { file -> SourceFileSyntax? in
  OperatorTable.standardOperators
    .foldAll(file.syntaxTree) { _ in /* Don't handle errors. */ }
    .as(SourceFileSyntax.self)
}

package let locationConverterCache = SyntaxCache { file -> SourceLocationConverter in
  SourceLocationConverter(fileName: file.path ?? "<nopath>", tree: file.syntaxTree)
}

package let commandsCache = SyntaxCache { file -> [Command] in
  guard file.contents.contains("sm:") else {
    return []
  }
  return CommandVisitor(locationConverter: file.locationConverter)
    .walk(file: file, handler: \.commands)
}

package let syntaxClassificationsCache = SyntaxCache { $0.syntaxTree.classifications }

package let commentLinesCache = SyntaxCache { CommentLinesVisitor.commentLines(in: $0) }
package let emptyLinesCache = SyntaxCache { EmptyLinesVisitor.emptyLines(in: $0) }

/// Re-enable once all parser diagnostics in tests have been addressed.
/// https://github.com/realm/SwiftLint/issues/3348
@TaskLocal public var parserDiagnosticsDisabledForTests = false

/// Thread-safe, lazily-populated cache keyed by ``SwiftSource`` identity
///
/// Each cache wraps a factory closure that produces a value on first access.
/// Subsequent accesses for the same file return the cached value without
/// re-invoking the factory. All mutations are serialized through a ``Mutex``.
package final class SyntaxCache<T: Sendable>: Sendable {
  private struct CacheStorage: Sendable {
    var values = [FileCacheKey: T]()
  }

  private let storage = Mutex(CacheStorage())
  private let factory: @Sendable (SwiftSource) -> T

  /// - Parameters:
  ///   - factory: Closure invoked to produce a value the first time a given
  ///     ``SwiftSource`` is looked up.
  package init(_ factory: @escaping @Sendable (SwiftSource) -> T) {
    self.factory = factory
  }

  /// Return the cached value for `file`, computing it via the factory if absent
  ///
  /// - Parameters:
  ///   - file: The source file whose cached value is requested.
  package func get(_ file: SwiftSource) -> T {
    let key = file.cacheKey
    if let cached = storage.withLock({ $0.values[key] }) {
      return cached
    }
    let value = factory(file)
    storage.withLock { $0.values[key] = value }
    return value
  }

  /// Remove the cached value for `file`, forcing recomputation on next access
  ///
  /// - Parameters:
  ///   - file: The source file whose cached entry should be discarded.
  package func invalidate(_ file: SwiftSource) {
    storage.withLock { _ = $0.values.removeValue(forKey: file.cacheKey) }
  }

  /// Remove all cached values, releasing associated memory
  package func clear() {
    storage.withLock { $0.values.removeAll(keepingCapacity: false) }
  }

  /// Directly store a value, bypassing the factory
  ///
  /// - Parameters:
  ///   - key: The cache key (derived from a ``SwiftSource`` identity).
  ///   - value: The value to cache.
  package func set(key: UUID, value: T) {
    storage.withLock { $0.values[key] = value }
  }

  /// Remove a previously stored value by key
  ///
  /// - Parameters:
  ///   - key: The cache key to remove.
  package func unset(key: UUID) {
    storage.withLock { _ = $0.values.removeValue(forKey: key) }
  }

  /// Returns true if a value has been cached for this key (without triggering the factory).
  package func has(key: UUID) -> Bool {
    storage.withLock { $0.values[key] != nil }
  }
}

extension SwiftSource {
  package var cacheKey: UUID { id }

  /// Error-severity diagnostics emitted by the Swift parser for this file
  package var parserDiagnostics: [String] {
    if parserDiagnosticsDisabledForTests {
      return []
    }

    return ParseDiagnosticsGenerator.diagnostics(for: syntaxTree)
      .filter { $0.diagMessage.severity == .error }
      .map(\.message)
  }

  /// Parsed ``SourceFileSyntax`` tree, cached per file identity
  package var syntaxTree: SourceFileSyntax {
    syntaxTreeCache.get(self)
  }

  /// Syntax tree with operators folded using the standard operator table, or `nil` on failure
  package var foldedSyntaxTree: SourceFileSyntax? {
    foldedSyntaxTreeCache.get(self)
  }

  /// Converter between syntax-tree positions and file line/column locations
  package var locationConverter: SourceLocationConverter {
    locationConverterCache.get(self)
  }

  /// Valid enable/disable ``Command`` annotations found in this file
  package var commands: [Command] {
    commandsCache.get(self).filter(\.isValid)
  }

  /// ``Command`` annotations that failed validation (e.g. unknown rule identifiers)
  package var invalidCommands: [Command] {
    commandsCache.get(self).filter { !$0.isValid }
  }

  package var syntaxClassifications: SyntaxClassifications {
    syntaxClassificationsCache.get(self)
  }

  package var commentLines: Set<Int> {
    commentLinesCache.get(self)
  }

  package var emptyLines: Set<Int> {
    emptyLinesCache.get(self)
  }

  /// The most recent incremental parse result, used to construct
  /// `IncrementalParseTransition` for subsequent re-parses.
  package var incrementalParseResult: IncrementalParseResult {
    incrementalParseResultCache.get(self)
  }

  /// Re-parse the file incrementally after applying edits.
  ///
  /// This reuses unchanged subtrees from the previous parse, which is
  /// significantly faster than a full re-parse for small edits (e.g., IDE
  /// lint-on-type).
  ///
  /// After calling this method, the file's `syntaxTree`, `locationConverter`,
  /// and all dependent caches reflect the new source.
  ///
  /// - Parameters:
  ///   - newSource: The full source text after edits have been applied.
  ///   - edits: The concurrent edits that were applied to transform the
  ///     previous source into `newSource`.
  package func reparseIncrementally(
    newSource: String,
    edits: ConcurrentEdits,
  ) {
    let previousResult = incrementalParseResultCache.get(self)
    let transition = IncrementalParseTransition(
      previousIncrementalParseResult: previousResult,
      edits: edits,
    )
    let newResult = Parser.parseIncrementally(
      source: newSource,
      parseTransition: transition,
    )

    // Update source contents
    file.contents = newSource

    // Store the new incremental result and derived tree
    incrementalParseResultCache.set(key: cacheKey, value: newResult)
    syntaxTreeCache.set(key: cacheKey, value: newResult.tree)

    // Invalidate dependent caches (they'll be lazily recomputed)
    foldedSyntaxTreeCache.invalidate(self)
    locationConverterCache.invalidate(self)
    commandsCache.invalidate(self)
    syntaxClassificationsCache.invalidate(self)
    commentLinesCache.invalidate(self)
    emptyLinesCache.invalidate(self)
  }

  /// Invalidates syntax-level caches for this file
  ///
  /// Called by ``invalidateCache()`` in SwiftiomaticKit which also covers SourceKit caches.
  package func invalidateSyntaxCaches() {
    file.clearCaches()
    incrementalParseResultCache.invalidate(self)
    syntaxTreeCache.invalidate(self)
    foldedSyntaxTreeCache.invalidate(self)
    locationConverterCache.invalidate(self)
    commandsCache.invalidate(self)
    syntaxClassificationsCache.invalidate(self)
    commentLinesCache.invalidate(self)
    emptyLinesCache.invalidate(self)
  }

  /// Remove every cached syntax value across all per-file caches
  package static func clearSyntaxCaches() {
    incrementalParseResultCache.clear()
    syntaxTreeCache.clear()
    foldedSyntaxTreeCache.clear()
    locationConverterCache.clear()
    commandsCache.clear()
    syntaxClassificationsCache.clear()
    commentLinesCache.clear()
    emptyLinesCache.clear()
  }
}
