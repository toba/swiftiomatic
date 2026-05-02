import SwiftSyntax

/// Capturing a `var` *implicitly* in a closure body is a footgun: the closure silently retains the
/// mutable binding and observes subsequent mutations through the original variable, which is almost
/// always surprising — especially for `Sendable` hand-off across isolation boundaries.
///
/// The remedy is an explicit capture list (`{ [counter] in ... }`), which snapshots the value at
/// closure-creation time. Explicit `[var]` captures are therefore *not* flagged: they are the
/// documented Swift 6 idiom for value-snapshot capture and are often required to satisfy strict
/// concurrency.
///
/// This rule is purely syntactic. It pre-scans the source file for `var` declarations (excluding
/// `lazy var` and IUOs). Inside each closure it collects the names that shadow file-level vars
/// (explicit captures, closure parameters, and locally-declared bindings), then flags any
/// `DeclReferenceExpr` in the closure body that references an unshadowed file-level `var` name.
///
/// Lint: When a closure body references a name that matches a `var` declaration in the same file
/// without explicitly capturing it, a warning is raised.
final class NoMutableCapture: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .closures }
    override class var defaultValue: LintOnlyValue { .init(lint: .warn) }

    private var mutableNames: Set<String> = []

    override func visit(_ node: SourceFileSyntax) -> SyntaxVisitorContinueKind {
        let collector = MutableVarNameCollector(viewMode: .sourceAccurate)
        collector.walk(node)
        mutableNames = collector.names
        return .visitChildren
    }

    override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
        guard !mutableNames.isEmpty else { return .visitChildren }

        var shadowed: Set<String> = []
        if let signature = node.signature {
            if let captureClause = signature.capture {
                for capture in captureClause.items {
                    shadowed.insert(capture.name.text)
                }
            }
            if let paramClause = signature.parameterClause {
                switch paramClause {
                    case let .simpleInput(params):
                        for param in params { shadowed.insert(param.name.text) }
                    case let .parameterClause(clause):
                        for param in clause.parameters {
                            let internalName = param.secondName ?? param.firstName
                            guard internalName.tokenKind != .wildcard else { continue }
                            shadowed.insert(internalName.text)
                        }
                }
            }
        }

        let localCollector = ClosureLocalNameCollector(viewMode: .sourceAccurate)
        for stmt in node.statements { localCollector.walk(stmt) }
        shadowed.formUnion(localCollector.names)

        let refFinder = ImplicitCaptureFinder(
            mutableNames: mutableNames,
            shadowed: shadowed,
            viewMode: .sourceAccurate
        )
        for stmt in node.statements { refFinder.walk(stmt) }

        for ref in refFinder.references {
            diagnose(.implicitMutableCapture(ref.name), on: ref.token)
        }
        return .visitChildren
    }
}

/// Collects names of `var` declarations across a file.
///
/// Skips `lazy var` (the value is computed once on access, not mutated like a regular var) and
/// implicitly-unwrapped optionals (where `var x: Int!` is a common late-init idiom whose value is
/// set once).
private final class MutableVarNameCollector: SyntaxVisitor {
    var names: Set<String> = []

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        guard node.bindingSpecifier.tokenKind == .keyword(.var) else { return .visitChildren }
        if node.modifiers.contains(.lazy) { return .visitChildren }

        for binding in node.bindings {
            if let annotation = binding.typeAnnotation,
               annotation.type.is(ImplicitlyUnwrappedOptionalTypeSyntax.self)
            {
                continue
            }
            if let pattern = binding.pattern.as(IdentifierPatternSyntax.self) {
                names.insert(pattern.identifier.text)
            }
        }
        return .visitChildren
    }
}

/// Collects identifiers introduced inside a closure body without descending into nested scopes.
private final class ClosureLocalNameCollector: SyntaxVisitor {
    var names: Set<String> = []

    override func visit(_ node: IdentifierPatternSyntax) -> SyntaxVisitorContinueKind {
        names.insert(node.identifier.text)
        return .visitChildren
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        names.insert(node.name.text)
        return .skipChildren
    }

    override func visit(_ node: CatchClauseSyntax) -> SyntaxVisitorContinueKind {
        if node.catchItems.isEmpty { names.insert("error") }
        return .visitChildren
    }

    override func visit(_: ClosureExprSyntax) -> SyntaxVisitorContinueKind { .skipChildren }
    override func visit(_: StructDeclSyntax) -> SyntaxVisitorContinueKind { .skipChildren }
    override func visit(_: ClassDeclSyntax) -> SyntaxVisitorContinueKind { .skipChildren }
    override func visit(_: EnumDeclSyntax) -> SyntaxVisitorContinueKind { .skipChildren }
    override func visit(_: ActorDeclSyntax) -> SyntaxVisitorContinueKind { .skipChildren }
    override func visit(_: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind { .skipChildren }
}

/// Finds bare references to file-level `var` names inside a closure body, skipping nested
/// closures and member-access trailing names (e.g. `self.counter` does not flag `counter`).
private final class ImplicitCaptureFinder: SyntaxVisitor {
    let mutableNames: Set<String>
    let shadowed: Set<String>
    var references: [(name: String, token: TokenSyntax)] = []

    init(mutableNames: Set<String>, shadowed: Set<String>, viewMode: SyntaxTreeViewMode) {
        self.mutableNames = mutableNames
        self.shadowed = shadowed
        super.init(viewMode: viewMode)
    }

    override func visit(_: ClosureExprSyntax) -> SyntaxVisitorContinueKind { .skipChildren }

    override func visit(_ node: DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
        // Skip the trailing `.member` of a member access — `self.counter` should not flag.
        if let memberAccess = node.parent?.as(MemberAccessExprSyntax.self),
           memberAccess.declName.id == node.id
        {
            return .visitChildren
        }
        let name = node.baseName.text
        if mutableNames.contains(name), !shadowed.contains(name) {
            references.append((name, node.baseName))
        }
        return .visitChildren
    }
}

fileprivate extension Finding.Message {
    static func implicitMutableCapture(_ name: String) -> Finding.Message {
        "closure implicitly captures mutable variable '\(name)'; add it to the capture list (`[\(name)]`) to snapshot the current value, or rename to avoid collision"
    }
}
