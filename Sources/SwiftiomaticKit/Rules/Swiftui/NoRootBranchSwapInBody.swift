import SwiftSyntax

/// Flag a view `body` whose only statement is an `if` / `else` or a `switch` that swaps the root
/// view type between branches.
///
/// SwiftUI gives each branch of an `if` or a `switch` in a view builder its own identity. This is
/// true even when two branches build the same content. When the selected branch changes, SwiftUI
/// destroys the views of one branch and creates the views of the other. The destroyed views lose
/// their state, such as navigation state and focus, and SwiftUI cannot animate between the two
/// trees. At the root of `body` the loss includes every view inside the root.
///
/// Keep one stable root view and one modifier chain. Change only the values that the modifiers get,
/// with a ternary operator or a modifier that accepts an optional value:
///
/// ```swift
/// content.tint(isHighlighted ? .accentColor : nil)
/// ```
///
/// When only part of the content changes, put the condition inside the stable root.
///
/// An `if #available` check does not change while the app runs, so the swap never occurs. The rule
/// does not report it. In a `View` `body` , the rule also does not report an `if` without `else` or
/// branches whose root calls name the same view type, although these shapes also reset the identity
/// when the branch changes. The root of a branch is the view that its modifier chain starts from.
///
/// In a `ViewModifier` `body(content:)` , the rule reports every top-level `if` or `switch` on a
/// runtime condition, also one without `else` and one whose branches all start from `content` .
/// Each branch still gives `content` its own identity, so the modified view loses its state when
/// the condition changes.
///
/// When every branch is an `HStack`, `VStack`, `ZStack` or `Grid` that holds the same children,
/// only the layout changes. The message then names `AnyLayout`, which switches between
/// `HStackLayout`, `VStackLayout` and the other layouts and keeps the identity of the children.
///
/// Lint: The single top-level statement of a `View` `body` or a `ViewModifier` `body(content:)` is
/// an `if` / `else` or a `switch` whose branches build two or more different root view types. In a
/// `ViewModifier` `body(content:)` , any top-level `if` or `switch` on a runtime condition.
final class NoRootBranchSwapInBody: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }
    override class var guidance: GuidanceLevel { .shouldNot }

    /// The root of one branch: the name of its root view and the node that names it
    private struct Root {
        let name: String
        let node: Syntax
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        guard let binding = node.bindings.first,
              binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == "body",
              context.viewEntry(forMember: node) != nil else { return .visitChildren }

        switch binding.accessorBlock?.accessors {
            case let .getter(statements): check(statements)
            case let .accessors(list):
                if let getter = list.first(where: {
                    $0.accessorSpecifier.tokenKind == .keyword(.get)
                }),
                   let statements = getter.body?.statements { check(statements) }
            case nil: break
        }
        return .visitChildren
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        let labels = node.signature.parameterClause.parameters.map(\.firstName.text)

        if node.name.text == "body",
           labels == ["content"],
           context.viewEntry(forMember: node) != nil,
           let statements = node.body?.statements,
           !check(statements),
           // In `ViewModifier.body(content:)` , any runtime branch changes the identity of
           // `content` , also one that keeps the root or has no `else` .
           let statement = statements.firstAndOnly,
           let expression = statement.expression,
           let keyword = Self.runtimeBranchKeyword(expression) {
            diagnose(.modifierBranch, on: keyword)
        }
        return .visitChildren
    }

    /// Reports a swap of the root view, and returns whether it did
    @discardableResult
    private func check(_ statements: CodeBlockItemListSyntax) -> Bool {
        guard let statement = statements.firstAndOnly,
              let expression = statement.expression else { return false }
        let keyword: TokenSyntax
        let roots: [Root]

        if let ifExpr = expression.as(IfExprSyntax.self) {
            guard !Self.checksAvailability(ifExpr),
                  let branches = Self.branches(of: ifExpr) else { return false }
            keyword = ifExpr.ifKeyword
            roots = branches.map { Self.root(of: $0) }
        } else if let switchExpr = expression.as(SwitchExprSyntax.self) {
            let branches = switchExpr.cases.compactMap { $0.as(SwitchCaseSyntax.self)?.statements }
            guard branches.count > 1 else { return false }
            keyword = switchExpr.switchKeyword
            roots = branches.map { Self.root(of: $0) }
        } else {
            return false
        }

        var names: [String] = []
        for root in roots where !names.contains(root.name) { names.append(root.name) }
        guard names.count > 1 else { return false }

        let notes = roots.map { root in
            Finding.Note(
                message: .branchBuilds(root.name),
                location: Finding.Location(root.node.startLocation(
                    converter: context.sourceLocationConverter)),
                role: .branch
            )
        }
        let message: Finding.Message = Self.swapsLayoutOnly(roots)
            ? .layoutSwap(names)
            : .rootSwap(names)
        diagnose(message, on: keyword, notes: notes)
        return true
    }

    /// The keyword of a top-level `if` or `switch` that tests a runtime condition, or `nil`
    private static func runtimeBranchKeyword(_ expression: ExprSyntax) -> TokenSyntax? {
        if let ifExpr = expression.as(IfExprSyntax.self), !checksAvailability(ifExpr) {
            return ifExpr.ifKeyword
        }
        return expression.as(SwitchExprSyntax.self)?.switchKeyword
    }

    /// Stack views that have an `AnyLayout` counterpart
    private static let layoutStacks: Set<String> = ["HStack", "VStack", "ZStack", "Grid"]

    /// Whether every root is a layout stack and every stack holds the same children
    ///
    /// Two children match when their modifier chains start from the same name, so `form()` and
    /// `form().frame(maxWidth: .infinity)` match. `AnyLayout` can then switch the layout and keep
    /// the identity of the children.
    private static func swapsLayoutOnly(_ roots: [Root]) -> Bool {
        let children = roots.map { root -> [String]? in
            guard layoutStacks.contains(root.name),
                  let call = stackCall(of: root.node),
                  let content = call.trailingClosure else { return nil }
            return content.statements.map { item in
                item.expression.map(rootName(of:)) ?? item.trimmedDescription
            }
        }
        guard let first = children.first, let first, !first.isEmpty else { return false }
        return children.allSatisfy { $0 == first }
    }

    /// The call that builds the stack at the start of a modifier chain
    private static func stackCall(of node: Syntax) -> FunctionCallExprSyntax? {
        var current = node.as(ExprSyntax.self)

        while let expression = current {
            guard let call = expression.as(FunctionCallExprSyntax.self) else { return nil }

            if let member = call.calledExpression.as(MemberAccessExprSyntax.self) {
                current = member.base
            } else {
                return call
            }
        }
        return nil
    }

    /// The statement lists of every branch, or `nil` when the chain has no final `else`
    private static func branches(of ifExpr: IfExprSyntax) -> [CodeBlockItemListSyntax]? {
        switch ifExpr.elseBody {
            case nil: nil
            case let .codeBlock(block): [ifExpr.body.statements, block.statements]
            case let .ifExpr(next): branches(of: next).map { [ifExpr.body.statements] + $0 }
        }
    }

    /// Whether any `if` in the chain tests `#available` or `#unavailable`
    ///
    /// The result of an availability check never changes while the app runs, so the swap never
    /// happens.
    private static func checksAvailability(_ ifExpr: IfExprSyntax) -> Bool {
        if ifExpr.conditions.contains(where: { $0.condition.is(AvailabilityConditionSyntax.self) })
        { return true }
        if case let .ifExpr(next) = ifExpr.elseBody { return checksAvailability(next) }
        return false
    }

    /// The root view of one branch
    ///
    /// An empty branch builds `EmptyView` . A branch with several statements builds a `TupleView` .
    /// A nested `if` or `switch` builds a `_ConditionalContent` .
    private static func root(of statements: CodeBlockItemListSyntax) -> Root {
        guard let statement = statements.first else {
            return Root(name: "EmptyView", node: Syntax(statements))
        }
        guard statements.count == 1, let expression = statement.expression
        else { return Root(name: "TupleView", node: Syntax(statement)) }
        return expression.is(IfExprSyntax.self) || expression.is(SwitchExprSyntax.self)
            ? Root(name: "_ConditionalContent", node: Syntax(expression))
            : Root(name: rootName(of: expression), node: Syntax(expression))
    }

    /// The name that starts a modifier chain
    ///
    /// For `List { }.padding()` the name is `List` . For `content.background(.yellow)` the name is
    /// `content` .
    private static func rootName(of expression: ExprSyntax) -> String {
        var current = expression

        while true {
            if let call = current.as(FunctionCallExprSyntax.self) {
                current = call.calledExpression
            } else if let member = current.as(MemberAccessExprSyntax.self), let base = member.base {
                current = base
            } else if let generic = current.as(GenericSpecializationExprSyntax.self) {
                current = generic.expression
            } else if let reference = current.as(DeclReferenceExprSyntax.self) {
                return reference.baseName.text
            } else {
                return current.trimmedDescription
            }
        }
    }
}

fileprivate extension Finding.Message {
    static let modifierBranch: Finding.Message = """
        'body(content:)' branches on a runtime condition, so a change of the condition gives \
        'content' a new identity. Keep one modifier chain, and put the condition in a ternary or an \
        optional-aware modifier
        """

    static func rootSwap(_ names: [String]) -> Finding.Message {
        let list = names.map { "'\($0)'" }.joined(separator: ", ")
        return "'body' swaps its root view between \(list). Keep one stable root view and put the condition inside it"
    }

    static func layoutSwap(_ names: [String]) -> Finding.Message {
        let list = names.map { "'\($0)'" }.joined(separator: ", ")
        return "'body' swaps its root view between \(list), which hold the same children. Use 'AnyLayout' to change the layout and keep the identity of the children"
    }

    static func branchBuilds(_ name: String) -> Finding.Message { "this branch builds '\(name)'" }
}
