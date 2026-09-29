import SwiftSyntax

// The code that runs while SwiftUI evaluates the `body` of a view. The rules that flag work in
// `body` share this scope, so each rule reports the same set of members.

extension Context {
    /// The regions that run while SwiftUI evaluates the `body` that `node` declares
    ///
    /// `node` is the `body` property of a `View` , or the `body(content:)` method of a
    /// `ViewModifier` . The type must conform to `View` or `ViewModifier` in this file. The first
    /// region is the code of `body` itself. The next regions are the same-file computed properties
    /// and the called methods that `body` reads, directly or through other members.
    ///
    /// Returns `nil` when `node` is not such a `body` .
    func viewBodyRegions(of node: some DeclSyntaxProtocol) -> [Syntax]? {
        guard let start = Self.bodyRegion(of: node), let entry = viewEntry(forMember: node) else {
            return nil
        }
        var regions = [start]
        var visited: Set<SyntaxIdentifier> = [Syntax(node).id]
        var pending = [start]

        while !pending.isEmpty {
            let region = pending.removeFirst()

            for reference in TypeMemberIndex.references(
                in: region, of: entry, skipping: { $0.runsAfterBody })
            where !reference.spelling.hasPrefix("$") {
                // A method named without a call passes a function reference that runs later
                let use = reference.node.selfQualifiedUse
                let called = use.parent?.as(FunctionCallExprSyntax.self)?.calledExpression.id
                    == use.id

                for member in reference.members
                where member.kind == .computedProperty || (member.kind == .method && called) {
                    guard let body = member.body, !isForeign(body),
                          visited.insert(member.declaration.id).inserted else { continue }
                    regions.append(body)
                    pending.append(body)
                }
            }
        }
        return regions
    }

    /// The function calls that run while SwiftUI evaluates the `body` that `node` declares
    ///
    /// The calls come from `viewBodyRegions(of:)` , in source order for each region. A call inside
    /// a closure that runs later, such as a `Button` action or a `.task` body, does not count.
    func callsDuringViewBody(of node: some DeclSyntaxProtocol) -> [FunctionCallExprSyntax] {
        guard let regions = viewBodyRegions(of: node) else { return [] }
        let finder = BodyCallFinder()
        for region in regions { finder.walk(region) }
        return finder.calls
    }

    /// The code of `body` : the accessor of a `body` property, or the code block of a
    /// `body(content:)` method
    private static func bodyRegion(of node: some DeclSyntaxProtocol) -> Syntax? {
        if let variable = node.as(VariableDeclSyntax.self) {
            guard variable.bindings.count == 1, let binding = variable.bindings.first,
                  binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == "body",
                  let accessor = binding.accessorBlock else { return nil }
            return Syntax(accessor)
        }
        if let function = node.as(FunctionDeclSyntax.self) {
            guard function.name.text == "body",
                  function.signature.parameterClause.parameters.first?.firstName.text == "content",
                  let body = function.body else { return nil }
            return Syntax(body)
        }
        return nil
    }

    private final class BodyCallFinder: SyntaxVisitor {
        var calls: [FunctionCallExprSyntax] = []

        init() { super.init(viewMode: .sourceAccurate) }

        override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
            node.runsAfterBody ? .skipChildren : .visitChildren
        }

        override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
            calls.append(node)
            return .visitChildren
        }
    }
}
