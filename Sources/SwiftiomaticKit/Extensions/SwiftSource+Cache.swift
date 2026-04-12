import Foundation
public import SwiftiomaticSyntax
import Synchronization

private let responseCache = SyntaxCache { file -> [String: SourceKitValue]? in
  do {
    return try Request.editorOpen(file: file.file).sendIfNotDisabled()
  } catch let error as Request.Error {
    Console.printError(error.description)
    return nil
  } catch {
    return nil
  }
}

private let structureDictionaryCache = SyntaxCache { file in
  responseCache.get(file).map(Structure.init).map { SourceKitDictionary($0.dictionary) }
}

private let syntaxMapCache = SyntaxCache { file -> ResolvedSyntaxMap? in
  responseCache.get(file).map { ResolvedSyntaxMap(value: SyntaxMap(sourceKitResponse: $0)) }
}

private let linesWithTokensCache = SyntaxCache { $0.computeLinesWithTokens() }
private let swiftSyntaxTokensCache = SyntaxCache { file -> [ResolvedSyntaxToken]? in
  // Use SyntaxKindMapper to derive SourceKit-compatible tokens from SwiftSyntax
  SyntaxKindMapper.sourceKitSyntaxKinds(for: file)
}

extension SwiftSource {
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

  var linesWithTokens: Set<Int> {
    linesWithTokensCache.get(self)
  }

  var structureDictionary: SourceKitDictionary {
    structureDictionaryCache.get(self) ?? SourceKitDictionary([:])
  }

  var syntaxMap: ResolvedSyntaxMap {
    syntaxMapCache.get(self) ?? ResolvedSyntaxMap(value: SyntaxMap(tokens: []))
  }

  var swiftSyntaxDerivedSourceKitTokens: [ResolvedSyntaxToken]? {
    swiftSyntaxTokensCache.get(self)
  }

  /// Invalidates all cached data for this file.
  func invalidateCache() {
    invalidateSyntaxCaches()
    responseCache.invalidate(self)
    structureDictionaryCache.invalidate(self)
    syntaxMapCache.invalidate(self)
    swiftSyntaxTokensCache.invalidate(self)
    linesWithTokensCache.invalidate(self)
  }

  /// Remove every cached value across all per-file caches
  public static func clearCaches() {
    clearSyntaxCaches()
    responseCache.clear()
    structureDictionaryCache.clear()
    syntaxMapCache.clear()
    swiftSyntaxTokensCache.clear()
    linesWithTokensCache.clear()
  }
}
