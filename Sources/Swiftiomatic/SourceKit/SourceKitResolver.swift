import Foundation
import Synchronization

/// SourceKit-backed type resolver.
///
/// Wraps cursorinfo, index, and expression-type requests.
/// Caches compiler args and file indexes for the lifetime of the scan.
///
/// `@unchecked Sendable` because the underlying sourcekitd XPC calls touch global C state.
/// All mutable state is protected by `Mutex`, and the C FFI calls are serialized by
/// `sourceKitRequestGate` (also a `Mutex`).
final class SourceKitResolver: TypeResolver, @unchecked Sendable {
    private let compilerArgs: [String]
    private let indexCache = Mutex<[String: FileIndex]>([:])

    var isAvailable: Bool {
        true
    }

    /// Create a resolver with explicit compiler arguments.
    init(compilerArgs: [String]) {
        self.compilerArgs = compilerArgs
    }

    /// Create a resolver that discovers compiler args from an SPM project root.
    init?(projectRoot: String) {
        guard let args = SwiftPMCompilationDB.compilerArguments(inPath: projectRoot) else {
            return nil
        }
        compilerArgs = args
    }

    // MARK: - TypeResolver

    func resolveType(inFile file: String, offset: Int) -> ResolvedType? {
        let request = Request.cursorInfo(
            file: file,
            offset: ByteCount(offset),
            arguments: compilerArgs,
        )
        guard let response = try? request.send() else { return nil }

        guard let typeName = response["key.typename"]?.stringValue else { return nil }
        let usr = response["key.usr"]?.stringValue
        let moduleName = response["key.modulename"]?.stringValue

        return ResolvedType(typeName: typeName, usr: usr, moduleName: moduleName)
    }

    func indexFile(_ file: String) -> FileIndex? {
        if let cached = indexCache.withLock({ $0[file] }) {
            return cached
        }

        let request = Request.index(file: file, arguments: compilerArgs)
        guard let response = try? request.send() else { return nil }

        var symbols: [IndexSymbol] = []
        if let entities = response["key.entities"]?.arrayValue {
            collectSymbols(from: entities, into: &symbols)
        }

        let index = FileIndex(file: file, symbols: symbols)
        indexCache.withLock { $0[file] = index }

        return index
    }

    func expressionTypes(inFile file: String) -> [ExpressionTypeInfo] {
        guard let source = try? String(contentsOfFile: file, encoding: .utf8) else { return [] }

        let request = Request.customRequest(request: [
            "key.request": UID("source.request.expression.type"),
            "key.sourcefile": file,
            "key.sourcetext": source,
            "key.compilerargs": compilerArgs,
        ])
        guard let response = try? request.send() else { return [] }

        guard let types = response["key.expression_type_list"]?.arrayValue
        else { return [] }

        return types.compactMap { entry in
            guard let dict = entry.dictionaryValue,
                  let offset = dict["key.expression_offset"]?.int64Value,
                  let length = dict["key.expression_length"]?.int64Value,
                  let typeName = dict["key.expression_type"]?.stringValue
            else { return nil }
            return ExpressionTypeInfo(
                offset: Int(offset),
                length: Int(length),
                typeName: typeName,
            )
        }
    }

    // MARK: - Helpers

    private func collectSymbols(from entities: [SourceKitValue],
                                into symbols: inout [IndexSymbol])
    {
        for entity in entities {
            guard let dict = entity.dictionaryValue,
                  let name = dict["key.name"]?.stringValue,
                  let usr = dict["key.usr"]?.stringValue,
                  let kindUID = dict["key.kind"]?.stringValue
            else { continue }

            let line = dict["key.line"]?.int64Value.map(Int.init) ?? 0
            let column = dict["key.column"]?.int64Value.map(Int.init) ?? 0
            let offset = dict["key.offset"]?.int64Value.map(Int.init) ?? 0

            let symbolKind: IndexSymbol.Kind = kindUID.contains(".ref.") ? .reference : .declaration
            symbols.append(
                IndexSymbol(
                    name: name, usr: usr, kind: symbolKind,
                    offset: offset, line: line, column: column,
                ),
            )

            // Recurse into child entities
            if let children = dict["key.entities"]?.arrayValue {
                collectSymbols(from: children, into: &symbols)
            }
        }
    }
}
