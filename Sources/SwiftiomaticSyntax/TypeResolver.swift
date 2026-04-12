/// Protocol for semantic type resolution via SourceKit
///
/// Rules use this to upgrade confidence when type information is available.
/// The default ``NullResolver`` returns `nil` for everything, preserving
/// syntax-only behavior when `--sourcekit` is not passed.
public protocol TypeResolver: Sendable {
  /// Whether the resolver has a working connection to sourcekitd
  var isAvailable: Bool { get }

  /// Resolve the type of the expression at the given byte offset via cursorinfo
  ///
  /// - Parameters:
  ///   - file: The absolute path to the source file.
  ///   - offset: The byte offset of the expression.
  func resolveType(inFile file: String, offset: Int) async -> ResolvedType?

  /// Index a file, returning declarations and references with USRs
  ///
  /// - Parameters:
  ///   - file: The absolute path to the source file.
  func indexFile(_ file: String) async -> FileIndex?

  /// Get expression types for all expressions in a file
  ///
  /// - Parameters:
  ///   - file: The absolute path to the source file.
  func expressionTypes(inFile file: String) async -> [ExpressionTypeInfo]
}

/// Resolved type information from a cursorinfo request
public struct ResolvedType: Sendable, Equatable {
  /// The fully-qualified type name (e.g. `Swift.Bool`, `Dispatch.DispatchQueue`)
  package let typeName: String

  /// The Unique Symbol Reference for the type (e.g. `s:Sb` for `Bool`)
  package let usr: String?

  /// The module the type belongs to (e.g. `Swift`, `Dispatch`)
  package let moduleName: String?

  /// Create a resolved type
  ///
  /// - Parameters:
  ///   - typeName: The fully-qualified type name.
  ///   - usr: The USR, if available.
  ///   - moduleName: The module name, if available.
  package init(typeName: String, usr: String? = nil, moduleName: String? = nil) {
    self.typeName = typeName
    self.usr = usr
    self.moduleName = moduleName
  }
}

/// A declaration or reference found during file indexing
public struct IndexSymbol: Sendable, Equatable {
  /// Whether an index entry is a declaration or a reference
  public enum Kind: String, Sendable {
    case declaration
    case reference
  }

  /// The symbol's name
  package let name: String

  /// The Unique Symbol Reference, stable across files
  package let usr: String

  /// Whether this is a declaration or a reference
  package let kind: Kind

  /// Byte offset in the source file
  package let offset: Int

  /// One-based line number
  package let line: Int

  /// One-based column number
  package let column: Int

  /// Creates an index symbol
  ///
  /// - Parameters:
  ///   - name: The symbol's name.
  ///   - usr: The Unique Symbol Reference.
  ///   - kind: Whether this is a declaration or reference.
  ///   - offset: Byte offset in the source file.
  ///   - line: One-based line number.
  ///   - column: One-based column number.
  package init(name: String, usr: String, kind: Kind, offset: Int, line: Int, column: Int) {
    self.name = name
    self.usr = usr
    self.kind = kind
    self.offset = offset
    self.line = line
    self.column = column
  }
}

/// Index data for a single file containing declarations and references with USRs
public struct FileIndex: Sendable {
  /// The absolute path to the indexed file
  package let file: String
  /// All symbols (declarations and references) found in this file
  package let symbols: [IndexSymbol]

  /// Creates a file index
  ///
  /// - Parameters:
  ///   - file: The absolute path to the indexed file.
  ///   - symbols: All symbols found in this file.
  package init(file: String, symbols: [IndexSymbol]) {
    self.file = file
    self.symbols = symbols
  }

  /// All declaration symbols in this file
  package var declarations: [IndexSymbol] {
    symbols.filter { $0.kind == .declaration }
  }

  /// All reference symbols in this file
  package var references: [IndexSymbol] {
    symbols.filter { $0.kind == .reference }
  }
}

/// Type information for an expression span, from the expression-type request
public struct ExpressionTypeInfo: Sendable, Equatable {
  /// Byte offset of the expression start
  package let offset: Int

  /// Byte length of the expression
  package let length: Int

  /// The resolved type name
  package let typeName: String

  /// Creates an expression type info
  ///
  /// - Parameters:
  ///   - offset: Byte offset of the expression start.
  ///   - length: Byte length of the expression.
  ///   - typeName: The resolved type name.
  package init(offset: Int, length: Int, typeName: String) {
    self.offset = offset
    self.length = length
    self.typeName = typeName
  }
}
