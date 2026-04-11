import Foundation
import Synchronization

/// SourceKit-backed ``TypeResolver`` that wraps cursorinfo, index, and expression-type requests
///
/// Caches compiler arguments and file indexes for the lifetime of the scan.
///
/// Marked `@unchecked Sendable` because the underlying sourcekitd XPC calls touch
/// global C state. All mutable state is protected by ``Mutex``, and C FFI calls
/// are serialized by a global request gate.
public final class SourceKitResolver: TypeResolver, @unchecked Sendable {
  private let compilerArgs: [String]
  private let indexCache = Mutex<[String: FileIndex]>([:])

  public var isAvailable: Bool {
    true
  }

  /// Create a resolver with explicit compiler arguments
  ///
  /// - Parameters:
  ///   - compilerArgs: The compiler arguments passed to SourceKit requests.
  public init(compilerArgs: [String]) {
    self.compilerArgs = compilerArgs
  }

  /// Create a resolver that discovers compiler arguments from an SPM project root
  ///
  /// Returns `nil` if `.build/debug.yaml` cannot be found or parsed.
  ///
  /// - Parameters:
  ///   - projectRoot: The root directory of the Swift Package Manager project.
  public init?(projectRoot: String) {
    guard let args = SwiftPMCompilationDB.compilerArguments(inPath: projectRoot) else {
      return nil
    }
    compilerArgs = args
  }

  // MARK: - TypeResolver

  /// Resolve the type at a byte offset via a cursorinfo request
  ///
  /// - Parameters:
  ///   - file: The absolute path to the source file.
  ///   - offset: The byte offset of the expression to resolve.
  public func resolveType(inFile file: String, offset: Int) -> ResolvedType? {
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

  /// Index a file and return its declarations and references
  ///
  /// Results are cached per file path for the lifetime of this resolver.
  ///
  /// - Parameters:
  ///   - file: The absolute path to the source file.
  public func indexFile(_ file: String) -> FileIndex? {
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

  /// Retrieve resolved types for all expressions in the file
  ///
  /// - Parameters:
  ///   - file: The absolute path to the source file.
  public func expressionTypes(inFile file: String) -> [ExpressionTypeInfo] {
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

  private func collectSymbols(
    from entities: [SourceKitValue],
    into symbols: inout [IndexSymbol],
  ) {
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
