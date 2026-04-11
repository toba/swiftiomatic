import Foundation
import SwiftDiagnostics
import SwiftIDEUtils
import SwiftOperators
import SwiftParser
import SwiftParserDiagnostics
import SwiftSyntax
import Synchronization

private typealias FileCacheKey = UUID

private let responseCache = Cache { file -> [String: SourceKitValue]? in
  do {
    return try Request.editorOpen(file: file.file).sendIfNotDisabled()
  } catch let error as Request.Error {
    Console.printError(error.description)
    return nil
  } catch {
    return nil
  }
}

private let structureDictionaryCache = Cache { file in
  responseCache.get(file).map(Structure.init).map { SourceKitDictionary($0.dictionary) }
}

private let syntaxTreeCache = Cache { file -> SourceFileSyntax in
  Parser.parse(source: file.contents)
}

private let foldedSyntaxTreeCache = Cache { file -> SourceFileSyntax? in
  OperatorTable.standardOperators
    .foldAll(file.syntaxTree) { _ in /* Don't handle errors. */ }
    .as(SourceFileSyntax.self)
}

private let locationConverterCache = Cache { file -> SourceLocationConverter in
  SourceLocationConverter(fileName: file.path ?? "<nopath>", tree: file.syntaxTree)
}

private let commandsCache = Cache { file -> [Command] in
  guard file.contents.contains("sm:") else {
    return []
  }
  return CommandVisitor(locationConverter: file.locationConverter)
    .walk(file: file, handler: \.commands)
}

private let syntaxMapCache = Cache { file -> ResolvedSyntaxMap? in
  responseCache.get(file).map { ResolvedSyntaxMap(value: SyntaxMap(sourceKitResponse: $0)) }
}

private let syntaxClassificationsCache = Cache { $0.syntaxTree.classifications }
private let linesWithTokensCache = Cache { $0.computeLinesWithTokens() }
private let swiftSyntaxTokensCache = Cache { file -> [ResolvedSyntaxToken]? in
  // Use SyntaxKindMapper to derive SourceKit-compatible tokens from SwiftSyntax
  SyntaxKindMapper.sourceKitSyntaxKinds(for: file)
}

private let commentLinesCache = Cache { CommentLinesVisitor.commentLines(in: $0) }
private let emptyLinesCache = Cache { EmptyLinesVisitor.emptyLines(in: $0) }

/// Re-enable once all parser diagnostics in tests have been addressed.
/// https://github.com/realm/SwiftLint/issues/3348
@TaskLocal public var parserDiagnosticsDisabledForTests = false

/// Thread-safe, lazily-populated cache keyed by ``SwiftSource`` identity
///
/// Each cache wraps a factory closure that produces a value on first access.
/// Subsequent accesses for the same file return the cached value without
/// re-invoking the factory. All mutations are serialized through a ``Mutex``.
private final class Cache<T: Sendable>: Sendable {
  private struct CacheStorage: Sendable {
    var values = [FileCacheKey: T]()
  }

  private let storage = Mutex(CacheStorage())
  private let factory: @Sendable (SwiftSource) -> T

  /// - Parameters:
  ///   - factory: Closure invoked to produce a value the first time a given
  ///     ``SwiftSource`` is looked up.
  fileprivate init(_ factory: @escaping @Sendable (SwiftSource) -> T) {
    self.factory = factory
  }

  /// Return the cached value for `file`, computing it via the factory if absent
  ///
  /// - Parameters:
  ///   - file: The source file whose cached value is requested.
  fileprivate func get(_ file: SwiftSource) -> T {
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
  fileprivate func invalidate(_ file: SwiftSource) {
    storage.withLock { _ = $0.values.removeValue(forKey: file.cacheKey) }
  }

  /// Remove all cached values, releasing associated memory
  fileprivate func clear() {
    storage.withLock { $0.values.removeAll(keepingCapacity: false) }
  }

  /// Directly store a value, bypassing the factory
  ///
  /// - Parameters:
  ///   - key: The cache key (derived from a ``SwiftSource`` identity).
  ///   - value: The value to cache.
  fileprivate func set(key: FileCacheKey, value: T) {
    storage.withLock { $0.values[key] = value }
  }

  /// Remove a previously stored value by key
  ///
  /// - Parameters:
  ///   - key: The cache key to remove.
  fileprivate func unset(key: FileCacheKey) {
    storage.withLock { _ = $0.values.removeValue(forKey: key) }
  }

  /// Returns true if a value has been cached for this key (without triggering the factory).
  fileprivate func has(key: FileCacheKey) -> Bool {
    storage.withLock { $0.values[key] != nil }
  }
}

extension SwiftSource {
  fileprivate var cacheKey: FileCacheKey { id }

  /// Whether the SourceKit daemon returned `nil` for this file
  ///
  /// Reading this property does **not** trigger a SourceKit request if one has not
  /// already been made. This avoids the `SIGSEGV` from background `sourcekitd`
  /// threads described in apple/swift#55112.
  var sourcekitdFailed: Bool {
    get {
      // Only check if a response has already been cached. If the cache has no entry for this file,
      // SourceKit hasn't been invoked yet — return false to avoid triggering initialization.
      // This prevents the SIGSEGV from sourcekitd background threads (apple/swift#55112).
      guard responseCache.has(key: cacheKey) else { return false }
      return responseCache.get(self) == nil
    }
    set {
      if newValue {
        responseCache.set(key: cacheKey, value: [String: SourceKitValue]?.none)
      } else {
        responseCache.unset(key: cacheKey)
      }
    }
  }

  /// Error-severity diagnostics emitted by the Swift parser for this file
  var parserDiagnostics: [String] {
    if parserDiagnosticsDisabledForTests {
      return []
    }

    return ParseDiagnosticsGenerator.diagnostics(for: syntaxTree)
      .filter { $0.diagMessage.severity == .error }
      .map(\.message)
  }

  var linesWithTokens: Set<Int> {
    linesWithTokensCache.get(self)
  }

  var structureDictionary: SourceKitDictionary {
    structureDictionaryCache.get(self) ?? SourceKitDictionary([:])
  }

  var syntaxClassifications: SyntaxClassifications {
    syntaxClassificationsCache.get(self)
  }

  var syntaxMap: ResolvedSyntaxMap {
    syntaxMapCache.get(self) ?? ResolvedSyntaxMap(value: SyntaxMap(tokens: []))
  }

  /// Parsed ``SourceFileSyntax`` tree, cached per file identity
  var syntaxTree: SourceFileSyntax {
    syntaxTreeCache.get(self)
  }

  /// Syntax tree with operators folded using the standard operator table, or `nil` on failure
  var foldedSyntaxTree: SourceFileSyntax? {
    foldedSyntaxTreeCache.get(self)
  }

  /// Converter between syntax-tree positions and file line/column locations
  var locationConverter: SourceLocationConverter {
    locationConverterCache.get(self)
  }

  /// Valid enable/disable ``Command`` annotations found in this file
  var commands: [Command] {
    commandsCache.get(self).filter(\.isValid)
  }

  /// ``Command`` annotations that failed validation (e.g. unknown rule identifiers)
  var invalidCommands: [Command] {
    commandsCache.get(self).filter { !$0.isValid }
  }

  var swiftSyntaxDerivedSourceKitTokens: [ResolvedSyntaxToken]? {
    swiftSyntaxTokensCache.get(self)
  }

  var commentLines: Set<Int> {
    commentLinesCache.get(self)
  }

  var emptyLines: Set<Int> {
    emptyLinesCache.get(self)
  }

  /// Invalidates all cached data for this file.
  func invalidateCache() {
    file.clearCaches()
    responseCache.invalidate(self)
    structureDictionaryCache.invalidate(self)
    syntaxClassificationsCache.invalidate(self)
    syntaxMapCache.invalidate(self)
    swiftSyntaxTokensCache.invalidate(self)
    syntaxTreeCache.invalidate(self)
    foldedSyntaxTreeCache.invalidate(self)
    locationConverterCache.invalidate(self)
    commandsCache.invalidate(self)
    linesWithTokensCache.invalidate(self)
    commentLinesCache.invalidate(self)
    emptyLinesCache.invalidate(self)
  }

  /// Remove every cached value across all per-file caches
  public static func clearCaches() {
    responseCache.clear()
    structureDictionaryCache.clear()
    syntaxClassificationsCache.clear()
    syntaxMapCache.clear()
    swiftSyntaxTokensCache.clear()
    syntaxTreeCache.clear()
    foldedSyntaxTreeCache.clear()
    locationConverterCache.clear()
    commandsCache.clear()
    linesWithTokensCache.clear()
    commentLinesCache.clear()
    emptyLinesCache.clear()
  }
}
