import SwiftSyntax

/// Flag an in-memory SwiftData store outside tests and previews.
///
/// `ModelConfiguration(isStoredInMemoryOnly: true)` and `.modelContainer(for:inMemory: true)` keep
/// the store in memory only. The app loses every saved model when it quits. That is correct for a
/// unit test and for a preview, and it is almost always a mistake in the app target. A flag that a
/// developer sets for a quick test and does not remove is a common cause.
///
/// The rule does not report a test file, a file that imports XCTest or Testing, a Swift Testing
/// `@Test` function, a `#Preview` body, or a type that conforms to `PreviewProvider` . A test file
/// is a file under a `Tests/` directory or a file whose name ends in `Tests.swift` . The rule
/// reports only the literal `true` , so a value that a launch argument sets does not get a finding.
///
/// Lint: `isStoredInMemoryOnly: true` or `modelContainer(..., inMemory: true)` appears outside a
/// test or a preview.
final class FlagInMemoryModelStore: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftdata }
    override class var guidance: GuidanceLevel { .should }

    override func visit(_ node: SourceFileSyntax) -> SyntaxVisitorContinueKind {
        context.fileURL.isTestFile || Self.importsTestFramework(node)
            ? .skipChildren
            : .visitChildren
    }

    /// Whether the file imports `XCTest` or `Testing` .
    private static func importsTestFramework(_ file: SourceFileSyntax) -> Bool {
        file.statements.contains { item in
            guard let decl = item.item.as(ImportDeclSyntax.self),
                let module = decl.path.first?.name.text else { return false }
            return module == "XCTest" || module == "Testing"
        }
    }

    override func visit(_ node: MacroExpansionExprSyntax) -> SyntaxVisitorContinueKind {
        node.macroName.text == "Preview" ? .skipChildren : .visitChildren
    }

    override func visit(_ node: MacroExpansionDeclSyntax) -> SyntaxVisitorContinueKind {
        node.macroName.text == "Preview" ? .skipChildren : .visitChildren
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        let isModelContainer = Self.calleeName(node.calledExpression) == "modelContainer"

        for argument in node.arguments {
            guard let label = argument.label?.text,
                  label == "isStoredInMemoryOnly" || (isModelContainer && label == "inMemory"),
                  argument.expression.as(BooleanLiteralExprSyntax.self)?.literal
                      .tokenKind
                      == .keyword(.true),
                  !Self.isInPreviewProvider(node),
                  !node.hasTestAncestor else { continue }
            diagnose(.inMemoryStore(label), on: argument)
        }
        return .visitChildren
    }

    private static func calleeName(_ expr: ExprSyntax) -> String? {
        if let member = expr.as(MemberAccessExprSyntax.self) {
            return member.declName.baseName.text
        }
        return expr.as(DeclReferenceExprSyntax.self)?.baseName.text
    }

    /// Whether a type that conforms to `PreviewProvider` holds `node` .
    private static func isInPreviewProvider(_ node: some SyntaxProtocol) -> Bool {
        var current = node.parent

        while let cur = current {
            if let inheritance = cur.asProtocol(DeclGroupSyntax.self)?.inheritanceClause,
               inheritance.inheritedTypes.contains(where: {
                   $0.type.trimmedDescription.hasSuffix("PreviewProvider")
               }) { return true }
            current = cur.parent
        }
        return false
    }
}

fileprivate extension Finding.Message {
    static func inMemoryStore(_ label: String) -> Finding.Message {
        "'\(label): true' outside a test or preview discards every saved model when the app quits"
    }
}
