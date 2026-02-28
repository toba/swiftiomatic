import Foundation
import SwiftSyntax
import Synchronization

/// §8a: Two-pass cross-file dead private symbol detection.
///
/// Pass 1: Collect all private declarations across files.
/// Pass 2: Find references to those declarations.
/// Symbols with zero references → dead code.
///
/// When a `FileIndex` is provided (via `--sourcekit`), uses USR-based matching
/// instead of name-only matching, eliminating false negatives from name collisions.
final class DeadSymbolsCheck: BaseCheck {
    /// Shared symbol table across all files.
    let symbolTable: SymbolTable

    /// Optional SourceKit file index for USR-based reference matching.
    let fileIndex: FileIndex?

    init(filePath: String, symbolTable: SymbolTable, fileIndex: FileIndex? = nil) {
        self.symbolTable = symbolTable
        self.fileIndex = fileIndex
        super.init(filePath: filePath)
    }

    /// Pass 2: Find references and mark used symbols.
    /// When a FileIndex is available, use USR-based matching for precision.
    override func visit(_ node: DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
        let loc = node.startLocation(converter: .init(fileName: filePath, tree: node.root))
        let name = node.baseName.text
        let usr = findUSR(for: name, line: loc.line, column: loc.column)
        symbolTable.markReferenced(
            name,
            usr: usr,
            from: filePath,
            line: loc.line,
            column: loc.column,
        )
        return .visitChildren
    }

    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        let loc = node.startLocation(converter: .init(fileName: filePath, tree: node.root))
        let name = node.declName.baseName.text
        let usr = findUSR(for: name, line: loc.line, column: loc.column)
        symbolTable.markReferenced(
            name,
            usr: usr,
            from: filePath,
            line: loc.line,
            column: loc.column,
        )
        return .visitChildren
    }

    /// Look up the USR for a reference at the given location from the file index.
    private func findUSR(for name: String, line: Int, column: Int) -> String? {
        guard let index = fileIndex else { return nil }
        return index.references.first { ref in
            ref.name == name && ref.line == line && ref.column == column
        }?.usr
    }

    /// After all files have been walked, generate findings for dead symbols.
    func generateFindings() -> [Finding] {
        var results: [Finding] = []

        for symbol in symbolTable.unreferencedSymbols {
            results.append(
                Finding(
                    category: .agentReview,
                    severity: .medium,
                    file: symbol.file,
                    line: symbol.line,
                    column: symbol.column,
                    message: "Dead private \(symbol.kind): '\(symbol.name)' — no references found",
                    suggestion: "Remove if unused, or change visibility if needed elsewhere",
                    confidence: .high,
                ),
            )
        }

        return results
    }
}

/// Pass 1 visitor: Collects private declarations.
final class DeclarationCollector: SyntaxVisitor {
    let filePath: String
    let symbolTable: SymbolTable
    let fileIndex: FileIndex?

    init(filePath: String, symbolTable: SymbolTable, fileIndex: FileIndex? = nil) {
        self.filePath = filePath
        self.symbolTable = symbolTable
        self.fileIndex = fileIndex
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        guard isPrivate(node.modifiers), !shouldExclude(node) else { return .visitChildren }

        let loc = node.startLocation(converter: .init(fileName: filePath, tree: node.root))
        symbolTable.addDeclaration(
            name: node.name.text,
            kind: "func",
            file: filePath,
            line: loc.line,
            column: loc.column,
            usr: findUSR(for: node.name.text, line: loc.line, column: loc.column),
        )
        return .visitChildren
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        guard isPrivate(node.modifiers) else { return .visitChildren }

        for binding in node.bindings {
            guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else { continue }
            let name = pattern.identifier.text
            let loc = binding.startLocation(converter: .init(fileName: filePath, tree: node.root))
            symbolTable.addDeclaration(
                name: name,
                kind: node.bindingSpecifier.tokenKind == .keyword(.let) ? "let" : "var",
                file: filePath,
                line: loc.line,
                column: loc.column,
                usr: findUSR(for: name, line: loc.line, column: loc.column),
            )
        }
        return .visitChildren
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        guard isPrivate(node.modifiers) else { return .visitChildren }
        let loc = node.startLocation(converter: .init(fileName: filePath, tree: node.root))
        symbolTable.addDeclaration(
            name: node.name.text, kind: "class", file: filePath,
            line: loc.line, column: loc.column,
            usr: findUSR(for: node.name.text, line: loc.line, column: loc.column),
        )
        return .visitChildren
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        guard isPrivate(node.modifiers) else { return .visitChildren }
        let loc = node.startLocation(converter: .init(fileName: filePath, tree: node.root))
        symbolTable.addDeclaration(
            name: node.name.text, kind: "struct", file: filePath,
            line: loc.line, column: loc.column,
            usr: findUSR(for: node.name.text, line: loc.line, column: loc.column),
        )
        return .visitChildren
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        guard isPrivate(node.modifiers) else { return .visitChildren }
        let loc = node.startLocation(converter: .init(fileName: filePath, tree: node.root))
        symbolTable.addDeclaration(
            name: node.name.text, kind: "enum", file: filePath,
            line: loc.line, column: loc.column,
            usr: findUSR(for: node.name.text, line: loc.line, column: loc.column),
        )
        return .visitChildren
    }

    /// Look up the USR for a declaration at the given location from the file index.
    private func findUSR(for name: String, line: Int, column: Int) -> String? {
        guard let index = fileIndex else { return nil }
        return index.declarations.first { decl in
            decl.name == name && decl.line == line && decl.column == column
        }?.usr
    }

    private func isPrivate(_ modifiers: DeclModifierListSyntax) -> Bool {
        modifiers.contains { $0.name.text == "private" || $0.name.text == "fileprivate" }
    }

    private func shouldExclude(_ node: FunctionDeclSyntax) -> Bool {
        let name = node.name.text

        // Exclude init/deinit
        if name == "init" || name == "deinit" { return true }

        // Exclude @objc methods
        if node.attributes.contains(where: { attr in
            attr.trimmedDescription.hasPrefix("@objc")
        }) {
            return true
        }

        // Exclude override methods
        if node.modifiers.contains(where: { $0.name.text == "override" }) { return true }

        // Exclude test methods
        if name.hasPrefix("test") { return true }

        // Exclude very short names (likely protocol witnesses)
        if name.count < 3 { return true }

        return false
    }
}

/// Thread-safe symbol table for cross-file analysis.
///
/// When USRs are available (via `--sourcekit`), matching is USR-based for precision.
/// Without USRs, falls back to name-based matching (the original behavior).
final class SymbolTable: Sendable {
    struct SymbolEntry: Sendable {
        let name: String
        let kind: String
        let file: String
        let line: Int
        let column: Int
        /// USR from SourceKit indexing. Nil when running without `--sourcekit`.
        let usr: String?
        var referenceCount: Int = 0
        var referencedFromFiles: Set<String> = []
    }

    private let state = Mutex<[String: [SymbolEntry]]>([:])

    init() {}

    func addDeclaration(
        name: String, kind: String, file: String, line: Int, column: Int, usr: String? = nil,
    ) {
        state.withLock { symbols in
            var list = symbols[name, default: []]
            list.append(
                SymbolEntry(
                    name: name, kind: kind, file: file,
                    line: line, column: column, usr: usr,
                ),
            )
            symbols[name] = list
        }
    }

    func markReferenced(
        _ name: String,
        usr: String? = nil,
        from file: String,
        line: Int,
        column: Int,
    ) {
        state.withLock { symbols in
            guard var list = symbols[name] else { return }
            for i in list.indices {
                // Skip the declaration itself (exact location match)
                if list[i].file == file, list[i].line == line, list[i].column == column {
                    continue
                }

                // USR-based matching: if both sides have USRs, match precisely
                if let refUSR = usr, let declUSR = list[i].usr {
                    if refUSR == declUSR {
                        list[i].referenceCount += 1
                        list[i].referencedFromFiles.insert(file)
                    }
                    // USR mismatch — different symbol with same name, skip
                } else {
                    // Fallback: name-based matching (original behavior)
                    list[i].referenceCount += 1
                    list[i].referencedFromFiles.insert(file)
                }
            }
            symbols[name] = list
        }
    }

    var unreferencedSymbols: [SymbolEntry] {
        state.withLock { symbols in
            symbols.values.flatMap(\.self).filter { $0.referenceCount == 0 }
        }
    }
}
