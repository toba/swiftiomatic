import SwiftSyntax

/// Flag a `ForEach` or `List` row closure that reads a member of the enclosing view.
///
/// A row that reads only its element depends only on that element. When the closure also reads a
/// property or calls a method of the enclosing view, every row depends on that value, and a change
/// to it re-evaluates every row. Pass what the row needs into a row `View` as a stored input.
///
/// A value that the closure passes into the custom row `View` it builds also counts, such as
/// `TagRow(tag: tag, isSelected: selection == tag)` or `ItemRow(item: item, error: $error)` . The
/// closure still reads the value, so every row still depends on it. The row can obtain the value
/// itself, for example from the environment, or the element can carry it. The rule uses a separate
/// message for a row that only passes such values.
///
/// These reads are allowed:
///
/// - A `private let` or `static` member, because neither can change while the view lives.
/// - A method or computed property that itself reads only allowed members. It is a pure helper.
/// - A method that the row receives as a function value and does not call, such as
///   `reachedEnd: showMore` .
/// - A read inside a closure passed to the custom row `View` , such as
///   `copy: { library.copy(theme) }` , or inside a closure that runs after `body` on one of its
///   modifiers, such as `.onTapGesture { selection = tag }` . The closure runs later, and the row
///   is already one named `View` . The content of `.background { }` or `.overlay { }` runs during
///   `body` , so a read there still counts.
///
/// The rule reports each row once, at the `ForEach` or `List` call, and adds a note at each read.
///
/// Lint: A row closure reads or passes on a same-type member outside those cases.
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
        var readsDirectly = false

        for reference in references {
            if stability.isStable(reference.members) { continue }
            if Self.isUncalledMethod(reference) { continue }
            let use = Self.use(of: reference.node, in: closure)
            if use == .captured { continue }
            guard !names.contains(reference.name) else { continue }
            names.append(reference.name)
            if use == .read { readsDirectly = true }
            notes.append(Finding.Note(
                message: use == .read ? .readHere(reference.name) : .passedHere(reference.name),
                location: Finding.Location(reference.node.startLocation(
                    converter: context.sourceLocationConverter)),
                role: .member
            ))
        }
        guard !names.isEmpty else { return .visitChildren }

        let call = node.calleeBaseName ?? "ForEach"
        let message: Finding.Message = readsDirectly
            ? .readsOutsideElement(call, names)
            : .passesOutsideElement(call, names)
        diagnose(message, on: node.calledExpression, notes: notes)
        return .visitChildren
    }

    /// How a row closure uses a member read
    private enum Use {
        /// The closure reads the value while it builds the row.
        case read
        /// The closure passes the value into the custom row `View` it builds.
        case passed
        /// A closure inside the row captures the value and reads it later, or in the row's body.
        case captured
    }

    /// Whether `reference` names only methods and uses one as a function value, not as a call
    private static func isUncalledMethod(_ reference: TypeMemberIndex.Reference) -> Bool {
        guard reference.members.allSatisfy({ $0.kind == .method }) else { return false }
        let expression = reference.node.selfQualifiedUse
        guard let call = expression.parent?.as(FunctionCallExprSyntax.self) else { return true }
        return call.calledExpression.id != expression.id
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

    /// How `closure` uses the member read at `node`
    ///
    /// A read directly in an argument of the custom row `View` is `passed` . A read in a closure
    /// among those arguments is `captured` . A read in a closure passed to a modifier of the row,
    /// such as `.onTapGesture { selection = row }` , is also `captured` when that closure runs after
    /// `body` . The named row is already the update boundary the finding asks for. A closure that
    /// runs during `body` , such as the content of `.background { }` or `.overlay { }` , does not
    /// count. Every other read is a `read` .
    private static func use(
        of node: DeclReferenceExprSyntax,
        in closure: ClosureExprSyntax
    ) -> Use {
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
                if isCustomRow(call, in: closure) { return crossedClosure ? .captured : .passed }
                if crossedDeferredClosure, isModifier(call, ofRowIn: closure) { return .captured }
            }
            // a trailing closure of the row or of one of its modifiers
            if crossedClosure, let call = parent.as(FunctionCallExprSyntax.self),
               call.calledExpression.id != current.id
            {
                if isCustomRow(call, in: closure) { return .captured }
                if crossedDeferredClosure, isModifier(call, ofRowIn: closure) { return .captured }
            }
            current = parent
        }
        return .read
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
        let list = names.lazy.map { "'\($0)'" }.joined(separator: ", ")
        return "'\(call)' row reads \(list) from the enclosing view. Extract the row into a 'View' that takes the values as inputs so the row depends only on its element"
    }

    static func passesOutsideElement(_ call: String, _ names: [String]) -> Finding.Message {
        let list = names.lazy.map { "'\($0)'" }.joined(separator: ", ")
        return "'\(call)' row passes \(list) from the enclosing view into its row 'View'. Let the row obtain the values itself or carry them in the element so the row depends only on its element"
    }

    static func readHere(_ name: String) -> Finding.Message { "the row reads '\(name)' here" }

    static func passedHere(_ name: String) -> Finding.Message { "the row passes '\(name)' here" }
}
