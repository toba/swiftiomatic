import Foundation
import Synchronization
@preconcurrency import SourceKittenFramework

/// SourceKit-backed type resolver using SourceKitten.
///
/// Wraps cursorinfo, index, and expression-type requests.
/// Caches compiler args and file indexes for the lifetime of the scan.
final class SourceKittenResolver: TypeResolver, @unchecked Sendable {
    private let compilerArgs: [String]
    private let indexCache = Mutex<[String: FileIndex]>([:])


    var isAvailable: Bool { true }

    /// Create a resolver with explicit compiler arguments.
    init(compilerArgs: [String]) {
        self.compilerArgs = compilerArgs
    }

    /// Create a resolver that discovers compiler args from an SPM project root.
    init?(projectRoot: String) {
        guard let module = Module(spmArguments: [], inPath: projectRoot) else {
            return nil
        }
        self.compilerArgs = module.compilerArguments
    }

    // MARK: - TypeResolver

    func resolveType(inFile file: String, offset: Int) async -> ResolvedType? {
        let request = Request.cursorInfo(
            file: file,
            offset: ByteCount(offset),
            arguments: compilerArgs
        )
        guard let response = try? request.send() else { return nil }

        guard let typeName = response["key.typename"] as? String else { return nil }
        let usr = response["key.usr"] as? String
        let moduleName = response["key.modulename"] as? String

        return ResolvedType(typeName: typeName, usr: usr, moduleName: moduleName)
    }

    func indexFile(_ file: String) async -> FileIndex? {
        if let cached = indexCache.withLock({ $0[file] }) {
            return cached
        }

        let request = Request.index(file: file, arguments: compilerArgs)
        guard let response = try? request.send() else { return nil }

        var symbols: [IndexSymbol] = []
        if let entities = response["key.entities"] as? [[String: Any]] {
            collectSymbols(from: entities, into: &symbols)
        }

        let index = FileIndex(file: file, symbols: symbols)
        indexCache.withLock { $0[file] = index }

        return index
    }

    func expressionTypes(inFile file: String) async -> [ExpressionTypeInfo] {
        guard let source = try? String(contentsOfFile: file, encoding: .utf8) else { return [] }

        let request = Request.customRequest(request: [
            "key.request": SourceKit.UID("source.request.expression.type"),
            "key.sourcefile": file,
            "key.sourcetext": source,
            "key.compilerargs": compilerArgs,
        ])
        guard let response = try? request.send() else { return [] }

        guard let types = response["key.expression_type_list"] as? [[String: Any]] else { return [] }

        return types.compactMap { entry in
            guard let offset = entry["key.expression_offset"] as? Int64,
                  let length = entry["key.expression_length"] as? Int64,
                  let typeName = entry["key.expression_type"] as? String
            else { return nil }
            return ExpressionTypeInfo(
                offset: Int(offset),
                length: Int(length),
                typeName: typeName
            )
        }
    }

    // MARK: - Helpers

    private func collectSymbols(from entities: [[String: Any]], into symbols: inout [IndexSymbol]) {
        for entity in entities {
            guard let name = entity["key.name"] as? String,
                  let usr = entity["key.usr"] as? String,
                  let kindUID = entity["key.kind"] as? String
            else { continue }

            let line = (entity["key.line"] as? Int64).map(Int.init) ?? 0
            let column = (entity["key.column"] as? Int64).map(Int.init) ?? 0
            let offset = (entity["key.offset"] as? Int64).map(Int.init) ?? 0

            let symbolKind: IndexSymbol.Kind = kindUID.contains(".ref.") ? .reference : .declaration
            symbols.append(IndexSymbol(
                name: name, usr: usr, kind: symbolKind,
                offset: offset, line: line, column: column
            ))

            // Recurse into child entities
            if let children = entity["key.entities"] as? [[String: Any]] {
                collectSymbols(from: children, into: &symbols)
            }
        }
    }
}

// MARK: - SourceKit UID helper

private enum SourceKit {
    static func UID(_ string: String) -> SourceKittenFramework.UID {
        SourceKittenFramework.UID(string)
    }
}
