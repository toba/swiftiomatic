import SwiftSyntax

/// Flag the `CKAccountChanged` notification in a project that uses `CKSyncEngine` .
///
/// `CKSyncEngine` sends an `.accountChange` event to its delegate when the iCloud account signs
/// in, signs out or switches. A separate `CKAccountChanged` observer handles the same change a
/// second time, and the two handlers can run in either order. The delegate event is the one source
/// of account changes that the engine keeps in step with its sync state.
///
/// The rule reports `CKAccountChanged` when the same file or another file of the project uses the
/// identifier `CKSyncEngine` . Without a project index, the rule reads the linted file only.
///
/// Lint: `CKAccountChanged` appears in a project that also uses `CKSyncEngine` .
final class NoAccountChangedWithSyncEngine: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }
    override class var guidance: GuidanceLevel { .shouldNot }

    override func visit(_ node: DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
        guard node.baseName.text == "CKAccountChanged",
              context.projectReferences("CKSyncEngine") else {
            return .visitChildren
        }
        diagnose(.accountChangedWithSyncEngine, on: node)
        return .visitChildren
    }
}

fileprivate extension Finding.Message {
    static let accountChangedWithSyncEngine: Finding.Message =
        "'CKAccountChanged' duplicates the '.accountChange' event of 'CKSyncEngine'; handle the account change in the sync engine delegate"
}
