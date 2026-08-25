import SwiftSyntax

/// Flag `FileDocument` and `ReferenceFileDocument` in favour of the OS 27 document protocols.
///
/// `ReadableDocument` and `WritableDocument` replace both. The document becomes a reference type
/// meant to carry `@Observable` , so SwiftUI stops rebuilding it on every edit, and reading and
/// writing move off the main actor.
///
/// Neither old protocol carries a deprecation attribute in the 27.0 SDK, so existing code still
/// compiles. Treat the finding as a modernization, not as a break.
///
/// Migrating means the conforming type becomes a class. `ReadableDocument` refines `AnyObject` , so
/// a `struct FileDocument` cannot conform as it stands.
///
/// Lint: A conformance to `FileDocument` or `ReferenceFileDocument` raises a warning.
final class UseReadableDocument: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        flag(node.inheritanceClause)
        return .visitChildren
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        flag(node.inheritanceClause)
        return .visitChildren
    }

    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        flag(node.inheritanceClause)
        return .visitChildren
    }

    private func flag(_ inheritance: InheritanceClauseSyntax?) {
        guard let inheritance else { return }

        if let inherited = inheritance.inherited(named: "FileDocument") {
            diagnose(.useReadableDocument, on: inherited)
        }
        if let inherited = inheritance.inherited(named: "ReferenceFileDocument") {
            diagnose(.useWritableDocument, on: inherited)
        }
    }
}

fileprivate extension Finding.Message {
    static let useReadableDocument: Finding.Message =
        "'FileDocument' is superseded on OS 27 — adopt 'ReadableDocument' and 'WritableDocument', which need a class and read and write off the main actor"
    static let useWritableDocument: Finding.Message =
        "'ReferenceFileDocument' is superseded on OS 27 — adopt 'ReadableDocument' and 'WritableDocument', which carry '@Observable' instead of 'ObservableObject'"
}
