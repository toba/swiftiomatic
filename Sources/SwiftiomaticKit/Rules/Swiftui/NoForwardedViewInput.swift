import SwiftSyntax

/// Flag a view input that the view stores only to pass it unchanged to a child view.
///
/// A forwarded input makes the parent depend on a value it never reads. Each change to the value
/// makes SwiftUI evaluate the parent's `body` as well as the child's. Build the child in the view
/// that owns the value and pass it in as content, or let the child read the value from its source.
///
/// A binding and a closure are exempt, because a child needs them to write back or to act. A
/// binding is an `@Binding` property or a stored `Binding<Value>` . An input that the view reads,
/// adapts or passes to two different children is exempt too. A built-in SwiftUI view
/// such as `Text` or `Image` renders the value, so passing it there counts as a read. A callee
/// that the file declares as a type that is not a `View` or a `ViewModifier` takes no content, so
/// passing the value there counts as a read. An input whose value an initializer also passes to a
/// property wrapper's storage, as in `_items = Fetch(..., since: start)` , is exempt. The target
/// must be `_name` or `self._name` , and the value must read the input as `name` or `self.name` .
///
/// Lint: Every use of a stored value input of a view type, outside its initializers, is an argument
/// of one call to an uppercase callee, passed as `name` or `self.name` .
final class NoForwardedViewInput: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }
    override class var guidance: GuidanceLevel { .should }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        guard node.attributes.firstAttributeName != "Binding",
              let entry = context.viewEntry(forMember: node),
              let viewName = TypeMemberIndex.enclosingTypeName(of: node) else { return .skipChildren }
        let regions = TypeMemberIndex.declarationRegions(ofMember: node, typeName: viewName)
        let types = context.typeMembers(around: node).types

        for input in node.viewInputs
        where input.type.functionType == nil && !Self.isBinding(input.type) {
            guard !Self.feedsWrapperStorage(input.name, regions: regions) else { continue }

            if let child = Self.forwardingChild(of: input.name, entry: entry, regions: regions),
               types[child].map(\.isView) ?? true {
                diagnose(.forwardedInput(input.name, child), on: node)
            }
        }
        return .skipChildren
    }

    /// The one child that receives every use of `name` unchanged, or `nil` for any other use
    private static func forwardingChild(
        of name: String,
        entry: TypeMemberIndex.TypeEntry,
        regions: [any DeclGroupSyntax]
    ) -> String? {
        var child: String?

        for region in regions {
            for item in region.memberBlock.members where !item.decl.is(InitializerDeclSyntax.self) {
                for reference in TypeMemberIndex.references(in: item.decl, of: entry)
                where reference.name == name {
                    guard reference.spelling == name,
                          let callee = forwardedCallee(reference.node),
                          child == nil || child == callee else { return nil }
                    child = callee
                }
            }
        }
        return child
    }

    /// Whether `type` is `Binding<Value>` or `SwiftUI.Binding<Value>` , optional or not
    private static func isBinding(_ type: TypeSyntax) -> Bool {
        let type = type.unwrappingOptional
        if let identifier = type.as(IdentifierTypeSyntax.self) {
            return identifier.name.text == "Binding"
        }
        return type.as(MemberTypeSyntax.self)?.name.text == "Binding"
    }

    /// Whether an initializer assigns wrapper storage, such as `_items` or `self._items` , from a
    /// value that reads `name`
    private static func feedsWrapperStorage(_ name: String, regions: [any DeclGroupSyntax]) -> Bool {
        for region in regions {
            for item in region.memberBlock.members {
                guard let initializer = item.decl.as(InitializerDeclSyntax.self),
                      let body = initializer.body else { continue }
                let writes = InfixOperatorExprSyntax.assignments(
                    in: body, compound: false, enteringClosures: true)

                if writes.contains(where: { write in
                    write.leftOperand.selfMemberReference?.baseName.text.hasPrefix("_") == true
                        && reads(name, in: write.rightOperand)
                }) { return true }
            }
        }
        return false
    }

    /// Whether `expression` reads `name` as a bare name or as `self.name`
    ///
    /// An argument label such as `filter:` is not a read, and neither is a member of another base,
    /// such as `other.name` or `$0.name` .
    private static func reads(_ name: String, in expression: ExprSyntax) -> Bool {
        expression.tokens(viewMode: .sourceAccurate).contains { token in
            guard token.tokenKind == .identifier(name),
                  let reference = token.parent?.as(DeclReferenceExprSyntax.self),
                  reference.baseName.id == token.id else { return false }
            guard let access = reference.parent?.as(MemberAccessExprSyntax.self),
                  access.declName.id == reference.id else { return true }
            return access.base?.as(DeclReferenceExprSyntax.self)?.baseName.tokenKind
                == .keyword(.self)
        }
    }

    /// The callee name when `reference` is a whole argument of a call to a custom view type
    private static func forwardedCallee(_ reference: DeclReferenceExprSyntax) -> String? {
        guard let labeled = reference.selfQualifiedUse.parent?.as(LabeledExprSyntax.self),
              let call = labeled.parent?.parent?.as(FunctionCallExprSyntax.self),
              let callee = call.constructedTypeName,
              SwiftUIBuiltInViews.isCustomViewName(callee) else { return nil }
        return callee
    }
}

fileprivate extension Finding.Message {
    static func forwardedInput(_ name: String, _ child: String) -> Finding.Message {
        "'\(name)' is stored only to pass it unchanged to '\(child)'. Build the child in the parent and pass it in as content, or let the child read the value itself"
    }
}
