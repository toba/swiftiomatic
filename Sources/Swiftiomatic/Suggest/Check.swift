import SwiftSyntax

/// Protocol that all analysis checks conform to.
///
/// Each check is a `SyntaxVisitor` subclass that collects findings
/// as it walks the syntax tree.
public protocol Check: SyntaxVisitor {
    /// The findings collected by this check.
    var findings: [Finding] { get }

    /// The file path being analyzed (for location reporting).
    var filePath: String { get }
}

/// A check that runs in a second pass after all files have been parsed.
///
/// Pass 1: `collectDeclarations` gathers symbols across all files.
/// Pass 2: the check runs as a normal visitor to find references.
public protocol CrossFileCheck: Check {
    /// Called during pass 1 to collect declarations from a file.
    func collectDeclarations(from tree: SourceFileSyntax, file: String)
}
