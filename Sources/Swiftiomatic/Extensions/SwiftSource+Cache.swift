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
@TaskLocal package var parserDiagnosticsDisabledForTests = false

private final class Cache<T>: Sendable {
  private struct CacheStorage: @unchecked Sendable {
    var values = [FileCacheKey: T]()
  }

  private let storage = Mutex(CacheStorage())
  private let factory: @Sendable (SwiftSource) -> T

  fileprivate init(_ factory: @escaping @Sendable (SwiftSource) -> T) {
    self.factory = factory
  }

  fileprivate func get(_ file: SwiftSource) -> T {
    let key = file.cacheKey
    if let cached = storage.withLock({ $0.values[key] }) {
      return cached
    }
    let value = factory(file)
    storage.withLock { $0.values[key] = value }
    return value
  }

  fileprivate func invalidate(_ file: SwiftSource) {
    storage.withLock { _ = $0.values.removeValue(forKey: file.cacheKey) }
  }

  fileprivate func clear() {
    storage.withLock { $0.values.removeAll(keepingCapacity: false) }
  }

  fileprivate func set(key: FileCacheKey, value: T) {
    storage.withLock { $0.values[key] = value }
  }

  fileprivate func unset(key: FileCacheKey) {
    storage.withLock { _ = $0.values.removeValue(forKey: key) }
  }

  /// Returns true if a value has been cached for this key (without triggering the factory).
  fileprivate func has(key: FileCacheKey) -> Bool {
    storage.withLock { $0.values[key] != nil }
  }
}

extension SwiftSource {
  fileprivate var cacheKey: FileCacheKey {
    id
  }

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
        responseCache.set(key: cacheKey, value: Optional<[String: SourceKitValue]>.none)
      } else {
        responseCache.unset(key: cacheKey)
      }
    }
  }

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

  var syntaxTree: SourceFileSyntax {
    syntaxTreeCache.get(self)
  }

  var foldedSyntaxTree: SourceFileSyntax? {
    foldedSyntaxTreeCache.get(self)
  }

  var locationConverter: SourceLocationConverter {
    locationConverterCache.get(self)
  }

  var commands: [Command] {
    commandsCache.get(self).filter(\.isValid)
  }

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

  package static func clearCaches() {
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
