import SwiftSyntax

/// Flag a `ForEach` or `List` row closure that reads a member of the enclosing view.
///
/// A row that reads only its element depends only on that element. When the closure also reads a
/// property or calls a method of the enclosing view, every row depends on that value, and a change
/// to it re-evaluates every row. Pass what the row needs into a row `View` as a stored input.
///
/// These reads are allowed:
///
/// - A `private let` or `static` member, because neither can change while the view lives.
/// - A method or computed property that itself reads only allowed members. It is a pure helper.
/// - A projected binding such as `$selection` . Forwarding it to a row `View` does not read the
///   value, and the row that writes the selection needs it.
/// - A read inside an argument of the custom row `View` the closure builds, such as
///   `TagRow(tag: tag, isSelected: selection == tag)` or `ItemRow(item: item, canWrite: canWrite)`
///   . The row stores the value as an input, and SwiftUI skips it when the value does not change.
///   This is the fix the finding recommends. Whether the input is too large a value is the concern
///   of `flagWholeValueModelViewInput` .
/// - A read inside a closure passed to the custom row `View` , such as
///   `copy: { library.copy(theme) }` , or inside a closure that runs after `body` on one of its
///   modifiers, such as `.onTapGesture { selection = tag }` . The closure runs later, and the row
///   is already one named `View` . The content of `.background { }` or `.overlay { }` runs during
///   `body` , so a read there still counts.
///
/// The rule reports each row once, at the `ForEach` or `List` call, and adds a note at each read.
///
/// Lint: A row closure reads a same-type member outside those cases.
final class ForEachRowReadsOnlyElement: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let closure = node.rowContentClosure(includingList: true),
              let entry = context.typeMembers(around: node).enclosingType(of: node),
              entry.isView else { return .visitChildren }

        // A nested row closure reports its own reads when the visitor reaches it
        let references = TypeMemberIndex.references(in: closure, of: entry) { inner in
            inner.id != closure.id && Self.isRowClosure(inner)
        }
        let stability = StabilityCheck(entry: entry)
        var names: [String] = []
        var notes: [Finding.Note] = []

        for reference in references {
            if reference.spelling.hasPrefix("$") { continue }
            if stability.isStable(reference.members) { continue }
            if Self.isRowArgument(reference.node, in: closure) { continue }
            guard !names.contains(reference.name) else { continue }
            names.append(reference.name)
            notes.append(Finding.Note(
                message: .readHere(reference.name),
                location: Finding.Location(reference.node.startLocation(
                    converter: context.sourceLocationConverter)),
                role: .member
            ))
        }
        guard !names.isEmpty else { return .visitChildren }

        let call = node.calleeBaseName ?? "ForEach"
        diagnose(.readsOutsideElement(call, names), on: node.calledExpression, notes: notes)
        return .visitChildren
    }

    /// Memoized stability answers for one `visit` , keyed by member declaration
    ///
    /// A row that reads the same helper several times, or a view with several rows, asks about the
    /// same members again. The memo walks each member's body once.
    private final class StabilityCheck {
        let entry: TypeMemberIndex.TypeEntry
        private var memo: [SyntaxIdentifier: Bool] = [:]

        init(entry: TypeMemberIndex.TypeEntry) { self.entry = entry }

        /// Whether reading any of `members` cannot change between two evaluations of the same view
        /// value. Every overload must qualify, because the rule cannot tell which one runs.
        func isStable(_ members: [TypeMemberIndex.Member]) -> Bool {
            members.allSatisfy { isStable($0) }
        }

        private func isStable(_ member: TypeMemberIndex.Member) -> Bool {
            if member.isStatic { return true }
            guard let body = member.body else { return member.isLet && member.isPrivate }
            if let known = memo[member.declaration.id] { return known }

            // a member already on the path adds nothing new
            memo[member.declaration.id] = true
            let stable = !ForEachRowReadsOnlyElement.usesBareSelf(body)
                && TypeMemberIndex.references(in: body, of: entry).allSatisfy {
                    !$0.spelling.hasPrefix("$") && isStable($0.members)
                }
            memo[member.declaration.id] = stable
            return stable
        }
    }

    /// Whether `body` uses `self` other than as the base of a member access
    private static func usesBareSelf(_ body: Syntax) -> Bool {
        body.tokens(viewMode: .sourceAccurate).contains { token in
            guard token.tokenKind == .keyword(.self),
                  let reference = token.parent?.as(DeclReferenceExprSyntax.self)
            else { return false }
            let access = reference.parent?.as(MemberAccessExprSyntax.self)
            return access?.base?.id != reference.id
        }
    }

    /// Whether `node` sits inside an input of the custom row `View` that `closure` builds
    ///
    /// An input is an argument of the row `View` , a closure among those arguments included. A
    /// closure passed to a modifier of the row, such as `.onTapGesture { selection = row }` , also
    /// counts when the read sits in a closure that runs after `body` . That closure runs later, and
    /// the named row is already the update boundary the finding asks for. A closure that runs
    /// during `body` , such as the content of `.background { }` or `.overlay { }` , does not count.
    private static func isRowArgument(
        _ node: DeclReferenceExprSyntax,
        in closure: ClosureExprSyntax
    ) -> Bool {
        var current = Syntax(node)
        var crossedClosure = false
        var crossedDeferredClosure = false

        while let parent = current.parent, parent.id != closure.id {
            if let crossed = parent.as(ClosureExprSyntax.self) {
                crossedClosure = true
                if crossed.runsAfterBody { crossedDeferredClosure = true }
            }

            if let argument = parent.as(LabeledExprSyntax.self),
               let call = argument.parent?.parent?.as(FunctionCallExprSyntax.self)
            {
                if isCustomRow(call, in: closure) { return true }
                if crossedDeferredClosure, isModifier(call, ofRowIn: closure) { return true }
            }
            // a trailing closure of the row or of one of its modifiers
            if crossedClosure, let call = parent.as(FunctionCallExprSyntax.self),
               call.calledExpression.id != current.id
            {
                if isCustomRow(call, in: closure) { return true }
                if crossedDeferredClosure, isModifier(call, ofRowIn: closure) { return true }
            }
            current = parent
        }
        return false
    }

    /// Whether `call` applies a modifier to the custom row `View` that `closure` builds
    private static func isModifier(
        _ call: FunctionCallExprSyntax,
        ofRowIn closure: ClosureExprSyntax
    ) -> Bool {
        guard let root = ExprSyntax(call).modifierChainRoot.as(FunctionCallExprSyntax.self),
              root.id != call.id else { return false }
        return isCustomRow(root, in: closure)
    }

    /// Whether `call` builds a custom `View` as a top-level row of `closure` , modifiers included
    private static func isCustomRow(
        _ call: FunctionCallExprSyntax,
        in closure: ClosureExprSyntax
    ) -> Bool {
        guard let name = call.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text,
              SwiftUIBuiltInViews.isCustomViewName(name) else { return false }
        var expression = Syntax(call)

        while let parent = expression.parent {
            if let access = parent.as(MemberAccessExprSyntax.self), access.base?.id == expression.id
            {
                expression = parent
            } else if let outer = parent.as(FunctionCallExprSyntax.self),
               outer.calledExpression.id == expression.id
            {
                expression = parent
            } else if parent.is(CodeBlockItemSyntax.self) {
                return parent.parent?.parent?.id == closure.id
            } else {
                return false
            }
        }
        return false
    }

    private static func isRowClosure(_ closure: ClosureExprSyntax) -> Bool {
        closure.owningCall?.rowContentClosure(includingList: true)?.id == closure.id
    }
}

fileprivate extension Finding.Message {
    static func readsOutsideElement(_ call: String, _ names: [String]) -> Finding.Message {
        let list = names.map { "'\($0)'" }.joined(separator: ", ")
        return "'\(call)' row reads \(list) from the enclosing view. Extract the row into a 'View' that takes the values as inputs so the row depends only on its element"
    }

    static func readHere(_ name: String) -> Finding.Message { "the row reads '\(name)' here" }
}
