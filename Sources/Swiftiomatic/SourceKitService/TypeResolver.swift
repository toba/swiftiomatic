/// Protocol for semantic type resolution via SourceKit.
///
/// Checks use this to upgrade confidence when type information is available.
/// The default `NullResolver` returns nil for everything, preserving
/// syntax-only behavior when `--sourcekit` is not passed.
protocol TypeResolver: Sendable {
    /// Whether the resolver has a working connection to sourcekitd.
    var isAvailable: Bool { get }

    /// Resolve the type of the expression at the given offset via cursorinfo.
    func resolveType(inFile file: String, offset: Int) async -> ResolvedType?

    /// Index a file, returning declarations and references with USRs.
    func indexFile(_ file: String) async -> FileIndex?

    /// Get expression types for all expressions in a file.
    func expressionTypes(inFile file: String) async -> [ExpressionTypeInfo]
}

/// Resolved type information from a cursorinfo request.
struct ResolvedType: Sendable, Equatable {
    /// The fully-qualified type name (e.g. "Swift.Bool", "Dispatch.DispatchQueue").
    let typeName: String

    /// The Unique Symbol Reference for the type (e.g. "s:Sb" for Bool).
    let usr: String?

    /// The module the type belongs to (e.g. "Swift", "Dispatch").
    let moduleName: String?

    init(typeName: String, usr: String? = nil, moduleName: String? = nil) {
        self.typeName = typeName
        self.usr = usr
        self.moduleName = moduleName
    }
}

/// A declaration or reference found during file indexing.
struct IndexSymbol: Sendable, Equatable {
    enum Kind: String, Sendable {
        case declaration
        case reference
    }

    /// The symbol's name.
    let name: String

    /// The Unique Symbol Reference — stable across files.
    let usr: String

    /// Whether this is a declaration or a reference.
    let kind: Kind

    /// Byte offset in the source file.
    let offset: Int

    /// Line number (1-based).
    let line: Int

    /// Column number (1-based).
    let column: Int

    init(name: String, usr: String, kind: Kind, offset: Int, line: Int, column: Int) {
        self.name = name
        self.usr = usr
        self.kind = kind
        self.offset = offset
        self.line = line
        self.column = column
    }
}

/// Index data for a single file — declarations and references with USRs.
struct FileIndex: Sendable {
    let file: String
    let symbols: [IndexSymbol]

    init(file: String, symbols: [IndexSymbol]) {
        self.file = file
        self.symbols = symbols
    }

    /// All declarations in this file.
    var declarations: [IndexSymbol] {
        symbols.filter { $0.kind == .declaration }
    }

    /// All references in this file.
    var references: [IndexSymbol] {
        symbols.filter { $0.kind == .reference }
    }
}

/// Type information for an expression span, from the expression-type request.
struct ExpressionTypeInfo: Sendable, Equatable {
    /// Byte offset of the expression start.
    let offset: Int

    /// Byte length of the expression.
    let length: Int

    /// The resolved type name.
    let typeName: String

    init(offset: Int, length: Int, typeName: String) {
        self.offset = offset
        self.length = length
        self.typeName = typeName
    }
}
