import SwiftSyntax

/// Flag a `ForEach` row closure whose number of top-level views can change.
///
/// A lazy container such as a `List` reads the identifiers of all elements at once, but it builds
/// row content only for the visible rows. For this, each element of a `ForEach` must build a fixed
/// number of views, so SwiftUI can count the rows without running the row content. When a row can
/// build a different number, SwiftUI runs the content of every element before it shows a row. For a
/// large collection, or for rows that load images, this blocks the main actor and increases memory
/// use. An `if` without `else`, a nested `ForEach` or several top-level views each break the
/// one-view-per-element shape.
///
/// Filter the collection before `ForEach`. Keep the filtered collection in the model, for example
/// `walks = allWalks.filter { $0.durationInDays == 1 }`, and do not filter it in `body`. Then give
/// each element one view: `ForEach(model.walks) { walk in WalkRow(walk: walk) }`. A row view can
/// hold conditional content inside one root container, such as a `VStack`.
///
/// For sectioned data, give each element one `Section` that holds the inner `ForEach`. The rule
/// accepts this shape. A wrapper that you add only to keep the count constant can change where row
/// modifiers such as `listRowBackground` apply. Put a row modifier on the view that is the row.
///
/// To confirm the slow path, run the app with the launch argument `-LogForEachSlowPath YES`.
/// SwiftUI then logs a warning that names the collection type.
///
/// The rule follows a call to a `@ViewBuilder` method or computed property of the same type, at the
/// top level of the row or inside a `switch` case or `if` branch. A helper that builds more than
/// one view, an `if` without `else` or a `ForEach` changes the row's view count the same way.
///
/// The rule also follows a row that is one custom `View` of the same file into that type's `body` .
/// Several root views, an `if` without `else` or a branch at the root of that body change the row's
/// view count, or make a lazy container run the body only to count the rows.
///
/// A row whose content starts with an `if` / `else` or a `switch` also makes a lazy container run
/// the content of every element to count its rows. Filter the data before `ForEach` , or move the
/// branch inside one row view such as an `HStack` . A branch inside such a wrapper does not change
/// the row count, so the rule stays silent there.
///
/// A `Group` does not wrap its views into one view. It hands each child to the parent. The rule
/// counts the children of a `Group` as views of the row.
///
/// Lint: A `ForEach` content closure holds an `if` without a final `else` , a `ForEach` at its top
/// level, more than one top-level view, a branch as its only view, or a call to a same-type
/// `@ViewBuilder` helper that builds a variable number of views, or the row is a custom `View`
/// whose `body` root holds several views, an `if` without `else` or a branch. A finding in a row
/// `View` carries a note at the `ForEach` that builds it.
final class ConstantForEachRowCount: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }
    override class var guidance: GuidanceLevel { .shouldNot }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let closure = node.rowContentClosure() else { return .visitChildren }

        let views = Self.views(in: closure.statements)
        if views.count > 1 { diagnose(.severalViews(views.count), on: node.calledExpression) }

        if views.count == 1, let view = views.first, let keyword = Self.branchKeyword(of: view) {
            let note = Finding.Note(
                message: .branchPicksViews,
                location: Finding.Location(keyword.startLocation(
                    converter: context.sourceLocationConverter)),
                role: .branch
            )
            diagnose(.rowBranch, on: node.calledExpression, notes: [note])
        }

        let index = context.typeMembers(around: node)
        checkRowViews(views, in: index.enclosingType(of: node))
        if views.count == 1, let view = views.first { checkNamedRow(view, of: node, in: index) }
        return .visitChildren
    }

    /// The keyword of `view` when it is a `switch` or an `if` chain that ends in `else`
    ///
    /// An `if` without `else` has its own finding, so this returns `nil` for it.
    private static func branchKeyword(of view: ExprSyntax) -> TokenSyntax? {
        if let switchExpr = view.as(SwitchExprSyntax.self) { return switchExpr.switchKeyword }
        if let ifExpr = view.as(IfExprSyntax.self), hasFinalElse(ifExpr) { return ifExpr.ifKeyword }
        return nil
    }

    /// The row `View` bodies the rule already reported, so a recursive row reports once
    private var checkedRowBodies: Set<SyntaxIdentifier> = []

    /// Reports the root of the body of the custom row `View` that `view` builds
    ///
    /// A lazy container counts the rows of each element from the row's type. A row `View` whose
    /// body holds several root views, an `if` without `else` , or a branch at its root makes the
    /// container run every row's body only to count its rows. A `Form` or `List` also flattens the
    /// views of a multi-view body into separate rows.
    private func checkNamedRow(
        _ view: ExprSyntax,
        of forEach: FunctionCallExprSyntax,
        in index: TypeMemberIndex
    ) {
        guard let name = Self.customViewName(view),
              let entry = index.types[name],
              entry.isView,
              let body = Self.bodyStatements(of: entry),
              checkedRowBodies.insert(body.id).inserted else { return }

        let note = Finding.Note(
            message: .forEachBuildsRow(name),
            location: Finding.Location(forEach.startLocation(
                converter: context.sourceLocationConverter)),
            role: .closure
        )
        func diagnose(_ message: Finding.Message, on node: some SyntaxProtocol) {
            // A row declared in another file has no location here, so the `ForEach` carries the
            // finding and a note points at the row body
            guard context.isForeign(node) else {
                self.diagnose(message, on: node, notes: [note])
                return
            }
            let rowNote = Finding.Note(
                message: .rowBodyRoot(name), location: context.location(of: node), role: .related)
            self.diagnose(message, on: forEach.calledExpression, notes: [rowNote])
        }

        let views = Self.views(in: body)

        if views.count > 1, let first = views.first {
            diagnose(.rowBodyViews(name, views.count), on: first)
        }

        for root in views {
            if let ifExpr = root.as(IfExprSyntax.self) {
                if Self.hasFinalElse(ifExpr) {
                    if views.count == 1 { diagnose(.rowBodyBranch(name), on: ifExpr.ifKeyword) }
                } else {
                    diagnose(.rowBodyIfWithoutElse(name), on: ifExpr.ifKeyword)
                }
            } else if let switchExpr = root.as(SwitchExprSyntax.self), views.count == 1 {
                diagnose(.rowBodyBranch(name), on: switchExpr.switchKeyword)
            } else if Self.isForEach(root) { diagnose(.nestedForEach, on: root) }
        }
    }

    /// The name of the custom `View` that `view` builds, with or without modifiers applied to it
    private static func customViewName(_ view: ExprSyntax) -> String? {
        guard let name = view.modifierChainRoot.as(FunctionCallExprSyntax.self)?
            .calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text,
              SwiftUIBuiltInViews.isCustomViewName(name) else { return nil }
        return name
    }

    /// The statements of the `body` property of a `View` type
    private static func bodyStatements(
        of entry: TypeMemberIndex.TypeEntry
    ) -> CodeBlockItemListSyntax? {
        entry.members(named: "body")?.lazy.filter { !$0.isStatic }.compactMap(\.statements).first
    }

    /// The deepest chain of helper calls the rule follows
    private static let maxHelperDepth = 4

    /// Reports the views of a row, and descends into `switch` cases and `if` branches
    private func checkRowViews(_ views: [ExprSyntax], in owner: TypeMemberIndex.TypeEntry?) {
        for view in views {
            if let ifExpr = view.as(IfExprSyntax.self) {
                if !Self.hasFinalElse(ifExpr) {
                    diagnose(.ifWithoutElse, on: ifExpr.ifKeyword)
                } else {
                    for branch in Self.branches(of: ifExpr) {
                        checkRowViews(Self.views(in: branch), in: owner)
                    }
                }
            } else if let switchExpr = view.as(SwitchExprSyntax.self) {
                for case let .switchCase(switchCase) in switchExpr.cases {
                    checkRowViews(Self.views(in: switchCase.statements), in: owner)
                }
            } else if Self.isForEach(view) {
                diagnose(.nestedForEach, on: view)
            } else if let owner,
               let helper = Self.helper(view, in: owner),
               Self.buildsVariableViews(helper.body, in: owner, depth: 1) {
                diagnose(.variableHelper(helper.reference.baseName.text), on: helper.reference)
            }
        }
    }

    /// Whether the statements of a helper build a number of views other than one
    private static func buildsVariableViews(
        _ statements: CodeBlockItemListSyntax,
        in owner: TypeMemberIndex.TypeEntry,
        depth: Int
    ) -> Bool {
        let views = views(in: statements)
        guard views.count == 1, let view = views.first else { return views.count > 1 }

        if let ifExpr = view.as(IfExprSyntax.self) {
            return !hasFinalElse(ifExpr)
                || branches(of: ifExpr).contains {
                    buildsVariableViews($0, in: owner, depth: depth)
                }
        }
        if let switchExpr = view.as(SwitchExprSyntax.self) {
            return switchExpr.cases.contains {
                guard case let .switchCase(switchCase) = $0 else { return false }
                return buildsVariableViews(switchCase.statements, in: owner, depth: depth)
            }
        }
        if isForEach(view) { return true }

        if depth < maxHelperDepth, let helper = helper(view, in: owner) {
            return buildsVariableViews(helper.body, in: owner, depth: depth + 1)
        }
        return false
    }

    /// The name and body of the same-type `@ViewBuilder` helper that `view` calls or reads
    ///
    /// A helper without a result builder returns one view, so the rule does not follow it.
    private static func helper(
        _ view: ExprSyntax,
        in owner: TypeMemberIndex.TypeEntry
    ) -> (reference: DeclReferenceExprSyntax, body: CodeBlockItemListSyntax)? {
        let callee = view.as(FunctionCallExprSyntax.self)?.calledExpression ?? view
        guard let reference = callee.selfMemberReference else { return nil }

        for member in owner.members(named: reference.baseName.text) ?? [] {
            guard let statements = member.statements, hasViewBuilder(member.declaration)
            else { continue }
            return (reference, statements)
        }
        return nil
    }

    private static func hasViewBuilder(_ decl: DeclSyntax) -> Bool {
        if let function = decl.as(FunctionDeclSyntax.self) {
            return function.attributes.hasResultBuilder
        }
        return decl.as(VariableDeclSyntax.self)?.attributes.hasResultBuilder == true
    }

    /// The expressions among `statements` , which are the views a result builder collects
    ///
    /// A `Group` hands each of its children to the parent, so the children of a `Group` count in
    /// its place.
    private static func views(in statements: CodeBlockItemListSyntax) -> [ExprSyntax] {
        statements.flatMap { item -> [ExprSyntax] in
            guard let expression = item.expression else { return [] }
            if let content = groupContent(of: expression) { return views(in: content) }
            return [expression]
        }
    }

    /// The statements of the content closure when `expression` is a `Group` , with or without
    /// modifiers applied to it
    private static func groupContent(of expression: ExprSyntax) -> CodeBlockItemListSyntax? {
        guard let call = expression.modifierChainRoot.as(FunctionCallExprSyntax.self),
            call.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text == "Group",
            call.arguments.isEmpty,
            let closure = call.trailingClosure else { return nil }
        return closure.statements
    }

    /// The statements of every branch of an `if` chain that ends in `else`
    private static func branches(of ifExpr: IfExprSyntax) -> [CodeBlockItemListSyntax] {
        var result = [ifExpr.body.statements]

        switch ifExpr.elseBody {
            case nil: break
            case let .codeBlock(block): result.append(block.statements)
            case let .ifExpr(next): result += branches(of: next)
        }
        return result
    }

    private static func hasFinalElse(_ ifExpr: IfExprSyntax) -> Bool {
        switch ifExpr.elseBody {
            case nil: false
            case .codeBlock: true
            case let .ifExpr(next): hasFinalElse(next)
        }
    }

    /// Whether `expression` is a `ForEach` call, with or without modifiers applied to it
    private static func isForEach(_ expression: ExprSyntax) -> Bool {
        var current: ExprSyntax? = expression

        while let call = current?.as(FunctionCallExprSyntax.self) {
            if call.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text == "ForEach" {
                return true
            }
            current = call.calledExpression.as(MemberAccessExprSyntax.self)?.base
        }
        return false
    }
}

fileprivate extension Finding.Message {
    static let ifWithoutElse: Finding.Message =
        "'if' without 'else' in a 'ForEach' row changes the row's view count. Filter the data before 'ForEach' or move the condition into one row view"

    static let nestedForEach: Finding.Message =
        "'ForEach' directly inside a 'ForEach' row changes the row's view count. Wrap it in a container or a row 'View'"

    static func variableHelper(_ name: String) -> Finding.Message {
        "'\(name)' builds a variable number of views, so this 'ForEach' row changes its view count. Give the helper one root view or extract a row 'View'"
    }

    static func rowBodyViews(_ name: String, _ count: Int) -> Finding.Message {
        "'\(name)' body builds \(count) top-level views, so each 'ForEach' element makes \(count) rows. Wrap them in one container"
    }

    static func rowBodyIfWithoutElse(_ name: String) -> Finding.Message {
        "'if' without 'else' at the root of the '\(name)' row body changes the row's view count. Wrap the body in one container, such as a 'VStack'"
    }

    static func rowBodyBranch(_ name: String) -> Finding.Message {
        "'\(name)' row body starts with a branch, so a lazy container runs every row's body to count its rows. Move the branch inside one root view"
    }

    static let rowBranch: Finding.Message =
        "'ForEach' row content starts with a branch, so a lazy container runs every element's content to count its rows. Filter the data before 'ForEach' or move the branch inside one row view"

    static let branchPicksViews: Finding.Message = "This branch picks the views of each row"

    static func forEachBuildsRow(_ name: String) -> Finding.Message {
        "This 'ForEach' builds one '\(name)' for each element"
    }

    static func rowBodyRoot(_ name: String) -> Finding.Message {
        "The body of '\(name)' starts here, in another file"
    }

    static func severalViews(_ count: Int) -> Finding.Message {
        "'ForEach' row builds \(count) top-level views. Wrap them in one container or a row 'View' so each element makes one view"
    }
}
