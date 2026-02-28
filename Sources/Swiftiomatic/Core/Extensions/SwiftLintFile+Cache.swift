#if canImport(Darwin)
import Darwin
#endif
import Foundation
import SourceKittenFramework
import SwiftDiagnostics
import SwiftIDEUtils
import SwiftOperators
import SwiftParser
import SwiftParserDiagnostics
import SwiftSyntax

private typealias FileCacheKey = UUID

private let responseCache = Cache { file -> [String: any SourceKitRepresentable]? in
    do {
        return try Request.editorOpen(file: file.file).sendIfNotDisabled()
    } catch let error as Request.Error {
        queuedPrintError(error.description)
        return nil
    } catch {
        return nil
    }
}
private let structureDictionaryCache = Cache { file in
    responseCache.get(file).map(Structure.init).map { SourceKittenDictionary($0.dictionary) }
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
    guard file.contents.contains("swiftlint:") else {
        return []
    }
    return CommandVisitor(locationConverter: file.locationConverter)
        .walk(file: file, handler: \.commands)
}
private let syntaxMapCache = Cache { file in
    responseCache.get(file).map { SwiftLintSyntaxMap(value: SyntaxMap(sourceKitResponse: $0)) }
}
private let syntaxClassificationsCache = Cache { $0.syntaxTree.classifications }
private let linesWithTokensCache = Cache { $0.computeLinesWithTokens() }
private let swiftSyntaxTokensCache = Cache { file -> [SwiftLintSyntaxToken]? in
    // Use SwiftSyntaxKindBridge to derive SourceKitten-compatible tokens from SwiftSyntax
    SwiftSyntaxKindBridge.sourceKittenSyntaxKinds(for: file)
}
private let commentLinesCache = Cache { CommentLinesVisitor.commentLines(in: $0) }
private let emptyLinesCache = Cache { EmptyLinesVisitor.emptyLines(in: $0) }

package typealias AssertHandler = () -> Void
// Re-enable once all parser diagnostics in tests have been addressed.
// https://github.com/realm/SwiftLint/issues/3348
@TaskLocal package var parserDiagnosticsDisabledForTests = false

private let assertHandlerCache = Cache { (_: SwiftLintFile) -> AssertHandler? in nil }

private final class Cache<T>: Sendable {
    nonisolated(unsafe) private var values = [FileCacheKey: T]()
    private let factory: @Sendable (SwiftLintFile) -> T
    private let lock = PlatformLock()

    fileprivate init(_ factory: @escaping @Sendable (SwiftLintFile) -> T) {
        self.factory = factory
    }

    fileprivate func get(_ file: SwiftLintFile) -> T {
        let key = file.cacheKey
        return lock.doLocked {
            if let cachedValue = values[key] {
                return cachedValue
            }
            let value = factory(file)
            values[key] = value
            return value
        }
    }

    fileprivate func invalidate(_ file: SwiftLintFile) {
        lock.doLocked { values.removeValue(forKey: file.cacheKey) }
    }

    fileprivate func clear() {
        lock.doLocked { values.removeAll(keepingCapacity: false) }
    }

    fileprivate func set(key: FileCacheKey, value: T) {
        lock.doLocked { values[key] = value }
    }

    fileprivate func unset(key: FileCacheKey) {
        lock.doLocked { values.removeValue(forKey: key) }
    }
}

extension SwiftLintFile {
    fileprivate var cacheKey: FileCacheKey {
        id
    }

    var sourcekitdFailed: Bool {
        get {
            responseCache.get(self) == nil
        }
        set {
            if newValue {
                responseCache.set(key: cacheKey, value: nil)
            } else {
                responseCache.unset(key: cacheKey)
            }
        }
    }

    package var assertHandler: AssertHandler? {
        get {
            assertHandlerCache.get(self)
        }
        set {
            assertHandlerCache.set(key: cacheKey, value: newValue)
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

    var linesWithTokens: Set<Int> { linesWithTokensCache.get(self) }

    var structureDictionary: SourceKittenDictionary {
        guard let structureDictionary = structureDictionaryCache.get(self) else {
            if let handler = assertHandler {
                handler()
                return SourceKittenDictionary([:])
            }
            queuedFatalError("Never call this for file that sourcekitd fails.")
        }
        return structureDictionary
    }

    var syntaxClassifications: SyntaxClassifications { syntaxClassificationsCache.get(self) }

    var syntaxMap: SwiftLintSyntaxMap {
        guard let syntaxMap = syntaxMapCache.get(self) else {
            if let handler = assertHandler {
                handler()
                return SwiftLintSyntaxMap(value: SyntaxMap(data: []))
            }
            queuedFatalError("Never call this for file that sourcekitd fails.")
        }
        return syntaxMap
    }

    var syntaxTree: SourceFileSyntax { syntaxTreeCache.get(self) }

    var foldedSyntaxTree: SourceFileSyntax? { foldedSyntaxTreeCache.get(self) }

    var locationConverter: SourceLocationConverter { locationConverterCache.get(self) }

    var commands: [Command] { commandsCache.get(self).filter(\.isValid) }

    var invalidCommands: [Command] { commandsCache.get(self).filter { !$0.isValid } }

    var swiftSyntaxDerivedSourceKittenTokens: [SwiftLintSyntaxToken]? {
        swiftSyntaxTokensCache.get(self)
    }

    var commentLines: Set<Int> { commentLinesCache.get(self) }
    var emptyLines: Set<Int> { emptyLinesCache.get(self) }

    /// Invalidates all cached data for this file.
    func invalidateCache() {
        file.clearCaches()
        responseCache.invalidate(self)
        assertHandlerCache.invalidate(self)
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
        assertHandlerCache.clear()
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

private final class PlatformLock: Sendable {
    nonisolated(unsafe) private let primitiveLock: UnsafeMutablePointer<os_unfair_lock>

    init() {
        primitiveLock = UnsafeMutablePointer<os_unfair_lock>.allocate(capacity: 1)
        primitiveLock.initialize(to: os_unfair_lock())
    }

    @discardableResult
    func doLocked<U>(_ closure: () -> U) -> U {
        os_unfair_lock_lock(primitiveLock)
        defer { os_unfair_lock_unlock(primitiveLock) }
        return closure()
    }
}
