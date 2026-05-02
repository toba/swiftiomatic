import SwiftSyntax

/// Listing a `var` by name in a closure capture list (`{ [counter] in ... }`) snapshots its
/// current value at closure-creation time. Subsequent mutations through the original binding are
/// invisible to the closure, which is almost always surprising.
///
/// This is the same rule SwiftLint emits as `capture_variable`: "Non-constant variables should
/// not be listed in a closure's capture list to avoid confusion about closures capturing
/// variables at creation time."
///
/// The rule is purely syntactic. It pre-scans the source file for `var` declarations
/// (excluding `lazy var`, IUOs, attributed property-wrapper bindings, and stored properties of
/// types — those are accessed through `self`). For each closure capture-list entry, it flags the
/// name when it matches a file-level mutable var. Skipped:
/// - `[weak x]`, `[unowned x]` — reference-type lifetime captures, not value snapshots.
/// - `[x = expr]` — explicit value rebinding; the author has documented intent.
/// - `[self]` — never a "var" candidate.
///
/// Lint: When a closure capture list lists a name that matches a mutable `var` declaration in
/// the same file, a warning is raised.
final class NoMutableInCaptureList: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .closures }
    override class var defaultValue: LintOnlyValue { .init(lint: .warn) }

    private var mutableNames: Set<String> = []

    override func visit(_ node: SourceFileSyntax) -> SyntaxVisitorContinueKind {
        let collector = MutableVarNameCollector(viewMode: .sourceAccurate)
        collector.walk(node)
        mutableNames = collector.names
        return .visitChildren
    }

    override func visit(_ node: ClosureCaptureClauseSyntax) -> SyntaxVisitorContinueKind {
        guard !mutableNames.isEmpty else { return .skipChildren }
        for capture in node.items {
            // Skip `[weak x]`, `[unowned x]`, `[unowned(safe) x]`, etc. These are
            // reference-type lifetime captures, not value-snapshot captures.
            if capture.specifier != nil { continue }
            // Skip `[x = expression]` — explicit rebinding, intent documented.
            if capture.initializer != nil { continue }
            let name = capture.name.text
            if name == "self" { continue }
            if mutableNames.contains(name) {
                diagnose(.mutableInCaptureList(name), on: capture.name)
            }
        }
        return .skipChildren
    }
}

/// Collects names of `var` declarations across a file that are candidates for the
/// capture-list footgun.
///
/// Excludes:
/// - `lazy var` — computed once on first access, not the snapshot footgun.
/// - implicitly-unwrapped optionals (`var x: Int!`) — common late-init idiom.
/// - stored properties of types (struct/class/actor/enum/extension/protocol member-block items)
///   — accessed via `self`, not as bare-name captures.
/// - vars with attributes (`@State`, `@Bindable`, `@Binding`, `@FocusState`, `@AppStorage`, …)
///   — property-wrapper bindings whose runtime semantics are reference-like.
private final class MutableVarNameCollector: SyntaxVisitor {
    var names: Set<String> = []

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        guard node.bindingSpecifier.tokenKind == .keyword(.var) else { return .visitChildren }
        if node.modifiers.contains(.lazy) { return .visitChildren }
        if node.parent?.is(MemberBlockItemSyntax.self) == true { return .visitChildren }
        if !node.attributes.isEmpty { return .visitChildren }

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

fileprivate extension Finding.Message {
    static func mutableInCaptureList(_ name: String) -> Finding.Message {
        "explicit `[\(name)]` captures a mutable `var` by value at closure-creation time; subsequent mutations through the original binding are invisible to the closure — drop the capture list, rename the var, or use `[\(name) = \(name)]` to make the value-snapshot intent explicit"
    }
}
