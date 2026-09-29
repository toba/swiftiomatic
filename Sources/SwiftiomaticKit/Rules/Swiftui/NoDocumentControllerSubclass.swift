import SwiftSyntax

/// Flag a subclass of `NSDocumentController` in a project that uses `DocumentGroup` .
///
/// A `DocumentGroup` scene installs and drives the shared document controller of the app. AppKit
/// makes the first `NSDocumentController` instance the shared one. A custom subclass that the app
/// creates takes that place, and the document scene then opens, saves and restores documents
/// through a controller that it does not expect.
///
/// Customize the document behavior through the `DocumentGroup` API, the document type and the
/// scene modifiers instead.
///
/// The rule reads the other files of the project through the project index. Without a project
/// index, it reads the linted file alone.
///
/// Lint: A class inherits from `NSDocumentController` , and a file of the project uses
/// `DocumentGroup` .
final class NoDocumentControllerSubclass: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }
    override class var guidance: GuidanceLevel { .shouldNot }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        guard let inheritance = node.inheritanceClause,
              inheritance.inheritedTypes.contains(where: {
                  $0.type.simpleName == "NSDocumentController"
              }),
              context.projectReferences("DocumentGroup") else { return .visitChildren }
        diagnose(.documentControllerSubclass(node.name.text), on: node.name)
        return .visitChildren
    }
}

fileprivate extension Finding.Message {
    static func documentControllerSubclass(_ name: String) -> Finding.Message {
        "remove the 'NSDocumentController' subclass '\(name)'. 'DocumentGroup' owns the document controller"
    }
}
