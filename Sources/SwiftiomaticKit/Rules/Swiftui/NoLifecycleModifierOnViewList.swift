import SwiftSyntax

/// Flag a lifecycle or effect modifier that a list of views or conditional content receives.
///
/// `Group`, `ForEach`, a view whose `body` holds several views, and a `@ViewBuilder` member that
/// returns several views do not make one view. They make a list of views, and a modifier on the
/// list attaches to each view in it. `onAppear`, `onDisappear`, `task`, `onChange` and `onReceive`
/// therefore run once per view: each view starts and cancels its own task, and each one calls the
/// action for every change. On conditional content the modifier attaches to each branch. When the
/// condition changes, the new branch is a new view, so its `onAppear` and `task` run again and the
/// task of the old branch is cancelled.
///
/// Attach the modifier to one view that holds the content, such as a `VStack`, a `List` or a
/// `ScrollView`, or to the one view that owns the effect. When each element needs the work, such as
/// a row that loads its thumbnail, write the modifier inside the row. When the work belongs to the
/// branches of a conditional, write it on each branch, so that it is clear that both run it.
///
/// The rule follows the chain of modifiers down to its receiver. It reports the receiver when it is
/// a `Group` or a `ForEach`, a `@ViewBuilder` property or method of the same type, or a view that
/// this file declares, and its content is an `if`, a `switch`, a `ForEach` or more than one view. A
/// view that another file declares is not checked.
///
/// Lint: A lifecycle or effect modifier is attached to a list of views or to conditional content.
final class NoLifecycleModifierOnViewList: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }
    override class var guidance: GuidanceLevel { .shouldNot }

    private static let lifecycleModifiers: Set<String> = [
        "onAppear", "onDisappear", "task", "onChange", "onReceive",
    ]

    /// What a view builder produces, as far as a modifier on it is concerned
    private enum Content { case one, several, conditional }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let access = node.calledExpression.as(MemberAccessExprSyntax.self),
            let base = access.base,
            Self.lifecycleModifiers.contains(access.declName.baseName.text)
        else { return .visitChildren }

        let name = access.declName.baseName.text

        switch content(ofReceiver: base.modifierChainRoot, at: node) {
            case .conditional: diagnose(.conditionalContent(name), on: access.declName)
            case .several: diagnose(.viewList(name), on: access.declName)
            case .one, nil: break
        }
        return .visitChildren
    }

    /// The content of the view that a modifier chain starts from, or `nil` when it is not known
    private func content(ofReceiver root: ExprSyntax, at node: FunctionCallExprSyntax) -> Content? {
        let index = context.typeMembers(around: node)

        if let call = root.as(FunctionCallExprSyntax.self) {
            switch call.constructedTypeName {
                case "Group": return call.trailingClosure.map { Self.content(of: $0.statements) }
                case "ForEach": return .several
                case let name?:
                    guard let entry = index.types[name],
                          entry.isView,
                          let body = entry.members["body"]?.first?.body else { return nil }
                    return Self.statements(of: body).map(Self.content(of:))
                case nil:
                    guard let reference = call.calledExpression.as(DeclReferenceExprSyntax.self)
                    else { return nil }
                    return builderContent(named: reference.baseName.text, in: index, at: node)
            }
        }
        if let reference = root.as(DeclReferenceExprSyntax.self) {
            return builderContent(named: reference.baseName.text, in: index, at: node)
        }

        if let access = root.as(MemberAccessExprSyntax.self),
           access.base?.as(DeclReferenceExprSyntax.self)?.baseName.tokenKind == .keyword(.self) {
            return builderContent(named: access.declName.baseName.text, in: index, at: node)
        }
        return nil
    }

    /// The content of a `@ViewBuilder` member of the type around `node`
    private func builderContent(
        named name: String,
        in index: TypeMemberIndex,
        at node: FunctionCallExprSyntax
    ) -> Content? {
        guard let member = index.enclosingType(of: node)?.members[name]?.first,
              Self.hasResultBuilder(member.declaration),
              let body = member.body else { return nil }
        return Self.statements(of: body).map(Self.content(of:))
    }

    private static func hasResultBuilder(_ declaration: DeclSyntax) -> Bool {
        if let variable = declaration.as(VariableDeclSyntax.self) {
            return variable.attributes.hasResultBuilder
        }
        return declaration.as(FunctionDeclSyntax.self)?.attributes.hasResultBuilder == true
    }

    private static func statements(of body: Syntax) -> CodeBlockItemListSyntax? {
        body.as(CodeBlockItemListSyntax.self) ?? body.as(CodeBlockSyntax.self)?.statements
    }

    /// Classifies builder statements: a conditional, more than one view, a `ForEach`, or one view
    ///
    /// Declarations such as `let` do not produce views, so they do not count.
    private static func content(of statements: CodeBlockItemListSyntax) -> Content {
        var views: [ExprSyntax] = []

        for item in statements {
            guard let expression = item.expression else { continue }

            if expression.is(IfExprSyntax.self) || expression.is(SwitchExprSyntax.self) {
                return .conditional
            }
            views.append(expression)
        }
        if views.count > 1 { return .several }

        if let only = views.first?.modifierChainRoot.as(FunctionCallExprSyntax.self),
            only.constructedTypeName == "ForEach"
        {
            return .several
        }
        return .one
    }
}

fileprivate extension Finding.Message {
    static func conditionalContent(_ modifier: String) -> Finding.Message {
        """
        '.\(modifier)' on conditional content attaches to each branch, so it runs again when the \
        branch changes. Attach it to one container, such as a 'VStack', or write it on each branch
        """
    }

    static func viewList(_ modifier: String) -> Finding.Message {
        """
        '.\(modifier)' on a list of views attaches to each view and runs once per view. Attach it \
        to one container, such as a 'VStack', or move per-element work into the row
        """
    }
}
