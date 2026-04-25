import SwiftSyntax

/// Capturing a `var` by name in a closure captures its current value, not the
/// variable. Subsequent mutations through the original binding are invisible
/// to the closure, which is almost always surprising.
///
/// This rule is purely syntactic: it pre-scans the source file for `var`
/// declarations (excluding `lazy var` and IUOs) and flags closure captures
/// whose name matches any such declaration. Captures with an explicit
/// initializer (`[x = self.x]`) and `weak`/`unowned` captures are not flagged.
///
/// Lint: When a closure captures a name that matches a `var` declaration in
/// the same file, a warning is raised.
final class MutableCapture: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .closures }

    private var mutableNames: Set<String> = []

    override func visit(_ node: SourceFileSyntax) -> SyntaxVisitorContinueKind {
        let collector = MutableVarNameCollector(viewMode: .sourceAccurate)
        collector.walk(node)
        mutableNames = collector.names
        return .visitChildren
    }

    override func visit(_ node: ClosureCaptureSyntax) -> SyntaxVisitorContinueKind {
        // `[x = self.x]` introduces a new constant; the original `x` isn't
        // captured directly.
        guard node.initializer == nil else { return .visitChildren }

        // `[weak x]` and `[unowned x]` imply reference semantics — not the
        // bug this rule targets.
        if let specifier = node.specifier?.specifier.text,
            specifier == "weak" || specifier == "unowned"
        {
            return .visitChildren
        }

        let name = node.name.text
        guard name != "self", mutableNames.contains(name) else {
            return .visitChildren
        }

        diagnose(.mutableCapture(name), on: node.name)
        return .visitChildren
    }
}

/// Collects names of `var` declarations across a file.
///
/// Skips `lazy var` (the value is computed once on access, not mutated like a
/// regular var) and implicitly-unwrapped optionals (where `var x: Int!` is a
/// common late-init idiom whose value is set once).
private final class MutableVarNameCollector: SyntaxVisitor {
    var names: Set<String> = []

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        guard node.bindingSpecifier.tokenKind == .keyword(.var) else {
            return .visitChildren
        }
        if node.modifiers.contains(where: { $0.name.tokenKind == .keyword(.lazy) }) {
            return .visitChildren
        }
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

extension Finding.Message {
    fileprivate static func mutableCapture(_ name: String) -> Finding.Message {
        "captured variable '\(name)' is declared with 'var'; closure captures the value at creation time, not subsequent mutations"
    }
}
