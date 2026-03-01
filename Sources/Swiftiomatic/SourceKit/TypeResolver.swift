/// Protocol for semantic type resolution via SourceKit
///
/// Rules use this to upgrade confidence when type information is available.
/// The default ``NullResolver`` returns `nil` for everything, preserving
/// syntax-only behavior when `--sourcekit` is not passed.
package protocol TypeResolver: Sendable {
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
package struct ResolvedType: Sendable, Equatable {
    /// The fully-qualified type name (e.g. `Swift.Bool`, `Dispatch.DispatchQueue`)
    let typeName: String

    /// The Unique Symbol Reference for the type (e.g. `s:Sb` for `Bool`)
    let usr: String?

    /// The module the type belongs to (e.g. `Swift`, `Dispatch`)
    let moduleName: String?

    /// Create a resolved type
    ///
    /// - Parameters:
    ///   - typeName: The fully-qualified type name.
    ///   - usr: The USR, if available.
    ///   - moduleName: The module name, if available.
    init(typeName: String, usr: String? = nil, moduleName: String? = nil) {
        self.typeName = typeName
        self.usr = usr
        self.moduleName = moduleName
    }
}

/// A declaration or reference found during file indexing
package struct IndexSymbol: Sendable, Equatable {
    /// Whether an index entry is a declaration or a reference
    package enum Kind: String, Sendable {
        case declaration
        case reference
    }

    /// The symbol's name
    let name: String

    /// The Unique Symbol Reference, stable across files
    let usr: String

    /// Whether this is a declaration or a reference
    let kind: Kind

    /// Byte offset in the source file
    let offset: Int

    /// One-based line number
    let line: Int

    /// One-based column number
    let column: Int
}

/// Index data for a single file containing declarations and references with USRs
package struct FileIndex: Sendable {
    /// The absolute path to the indexed file
    let file: String
    /// All symbols (declarations and references) found in this file
    let symbols: [IndexSymbol]

    /// All declaration symbols in this file
    var declarations: [IndexSymbol] {
        symbols.filter { $0.kind == .declaration }
    }

    /// All reference symbols in this file
    var references: [IndexSymbol] {
        symbols.filter { $0.kind == .reference }
    }
}

/// Type information for an expression span, from the expression-type request
package struct ExpressionTypeInfo: Sendable, Equatable {
    /// Byte offset of the expression start
    let offset: Int

    /// Byte length of the expression
    let length: Int

    /// The resolved type name
    let typeName: String
}
