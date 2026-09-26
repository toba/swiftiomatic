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
/// - A read inside a derived argument of the custom row `View` the closure builds, such as
///   `TagRow(tag: tag, isSelected: selection == tag)` . The row gets a small value and SwiftUI
///   skips it when the value does not change. A bare `citations: citations` still counts, because
///   the row then depends on the whole value.
///
/// Lint: A row closure reads a same-type member outside those cases.
final class ForEachRowReadsOnlyElement: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }

    /// SwiftUI views that a row closure builds inline, as opposed to a custom row `View`
    private static let builtInViews: Set<String> = [
        "Button", "Canvas", "Capsule", "Circle", "Color", "ColorPicker", "ControlGroup",
        "DatePicker", "DisclosureGroup", "Divider", "EmptyView", "ForEach", "Gauge",
        "GeometryReader", "Grid", "GridRow", "Group", "HStack", "Image", "Label", "LabeledContent",
        "LazyHGrid", "LazyHStack", "LazyVGrid", "LazyVStack", "Link", "List", "Menu",
        "NavigationLink", "OutlineGroup", "Picker", "ProgressView", "Rectangle", "RoundedRectangle",
        "ScrollView", "Section", "SecureField", "ShareLink", "Slider", "Spacer", "Stepper", "Text",
        "TextEditor", "TextField", "TimelineView", "Toggle", "VStack", "ViewThatFits", "ZStack",
    ]

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let closure = node.rowContentClosure(includingList: true),
              let entry = context.typeMembers(around: node).enclosingType(of: node),
              entry.isView else { return .visitChildren }

        // A nested row closure reports its own reads when the visitor reaches it
        let references = TypeMemberIndex.references(in: closure, of: entry) { inner in
            inner.id != closure.id && Self.isRowClosure(inner)
        }
        let stability = StabilityCheck(entry: entry)
        var reported: Set<String> = []

        for reference in references {
            if reference.spelling.hasPrefix("$") { continue }
            if stability.isStable(reference.members) { continue }
            if Self.isDerivedRowArgument(reference.node, in: closure) { continue }
            guard reported.insert(reference.name).inserted else { continue }
            diagnose(.readsOutsideElement(reference.name), on: reference.node)
        }
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

    /// Whether `node` sits inside a derived argument of the custom row `View` that `closure` builds
    private static func isDerivedRowArgument(
        _ node: DeclReferenceExprSyntax,
        in closure: ClosureExprSyntax
    ) -> Bool {
        // `self.name` reads as the whole member access
        var read = Syntax(node)

        if let access = node.parent?.as(MemberAccessExprSyntax.self), access.declName.id == node.id
        { read = Syntax(access) }
        var current = read

        while let parent = current.parent {
            if parent.is(ClosureExprSyntax.self) { return false }

            if let argument = parent.as(LabeledExprSyntax.self),
               let call = argument.parent?.parent?.as(FunctionCallExprSyntax.self),
               isCustomRow(call, in: closure) { return argument.expression.id != read.id }
            current = parent
        }
        return false
    }

    /// Whether `call` builds a custom `View` as a top-level row of `closure` , modifiers included
    private static func isCustomRow(
        _ call: FunctionCallExprSyntax,
        in closure: ClosureExprSyntax
    ) -> Bool {
        guard let name = call.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text,
              name.first?.isUppercase == true,
              !builtInViews.contains(name) else { return false }
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
    static func readsOutsideElement(_ name: String) -> Finding.Message {
        "'ForEach' row reads '\(name)' from the enclosing view. Pass the value into a row 'View' so the row depends only on its element"
    }
}
