import SwiftSyntax

/// Flag a `Bool` `@State` flag that presents content which reads a separate optional `@State` .
///
/// A view that presents a sheet for a value often keeps two properties: a `Bool` that shows the
/// sheet and an optional that holds the value. The two properties can disagree. The flag can be
/// `true` while the value is `nil` , and then the sheet shows empty content. The `item:` form takes
/// one `Binding<T?>` . The sheet shows when the value is set, and the content gets the value
/// unwrapped. `.alert` and `.confirmationDialog` get the same fix from their `presenting:` form.
///
/// The rule reads only the view type in the same file. It reports when the `isPresented:` argument
/// is the projected binding of a `Bool` `@State` property, and a content closure of the modifier
/// reads an optional `@State` property of the same view.
///
/// Lint: A `.sheet` , `.alert` , `.confirmationDialog` , `.popover` or `.fullScreenCover` presents
/// with a `Bool` `@State` flag, and its content reads an optional `@State` property.
final class UseItemPresentation: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }
    override class var guidance: GuidanceLevel { .consider }

    /// The modifiers that present content, and the argument label of their data form
    private static let presenters: [String: String] = [
        "sheet": "item:", "popover": "item:", "fullScreenCover": "item:",
        "alert": "presenting:", "confirmationDialog": "presenting:",
    ]

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let modifier = node.modifierName,
              let fix = Self.presenters[modifier],
              !node.arguments.contains(where: { $0.label?.text == "presenting" }),
              let flagArgument = node.arguments.first(where: { $0.label?.text == "isPresented" }),
              let flagName = Self.projectedName(flagArgument.expression),
              let entry = context.typeMembers(around: node).enclosingType(of: node),
              entry.isView,
              let flag = Self.stateBinding(named: flagName, in: entry),
              Self.isBool(flag.binding) else { return .visitChildren }

        let optional = Self.readNames(in: Self.contentClosures(of: node), of: entry).lazy
            .compactMap { name -> (String, VariableDeclSyntax)? in
                guard name != flagName,
                      let value = Self.stateBinding(named: name, in: entry),
                      Self.isOptional(value.binding) else { return nil }
                return (name, value.declaration)
            }
            .first
        guard let (valueName, valueDecl) = optional else { return .visitChildren }

        diagnose(
            .useItemPresentation(modifier: modifier, flag: flagName, value: valueName, fix: fix),
            on: flagArgument,
            notes: [
                note(.presentingFlag(flagName), at: flag.declaration),
                note(.optionalValue(valueName), at: valueDecl),
            ]
        )
        return .visitChildren
    }

    private func note(_ message: Finding.Message, at node: some SyntaxProtocol) -> Finding.Note {
        Finding.Note(
            message: message,
            location: Finding.Location(node.startLocation(
                converter: context.sourceLocationConverter)),
            role: .member
        )
    }

    /// The member name in `$flag` or `self.$flag`
    private static func projectedName(_ expression: ExprSyntax) -> String? {
        let text = expression.as(DeclReferenceExprSyntax.self)?.baseName.text
            ?? expression.as(MemberAccessExprSyntax.self).flatMap { member in
                member.base?.as(DeclReferenceExprSyntax.self)?.baseName
                    .tokenKind
                    == .keyword(.self) ? member.declName.baseName.text : nil
            }
        guard let text, text.hasPrefix("$"), text.count > 1 else { return nil }
        return String(text.dropFirst())
    }

    /// The `@State` stored property named `name` , with its declaration and pattern binding
    private static func stateBinding(
        named name: String,
        in entry: TypeMemberIndex.TypeEntry
    ) -> (declaration: VariableDeclSyntax, binding: PatternBindingSyntax)? {
        guard entry.isStateProperty(name) else { return nil }

        for member in entry.members[name] ?? [] {
            guard let declaration = member.declaration.as(VariableDeclSyntax.self),
                let binding = declaration.bindings.first(where: {
                    $0.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == name
                }) else { continue }
            return (declaration, binding)
        }
        return nil
    }

    private static func isBool(_ binding: PatternBindingSyntax) -> Bool {
        if let type = binding.typeAnnotation?.type {
            return type.as(IdentifierTypeSyntax.self)?.name.text == "Bool"
        }
        return binding.initializer?.value.is(BooleanLiteralExprSyntax.self) == true
    }

    private static func isOptional(_ binding: PatternBindingSyntax) -> Bool {
        guard let type = binding.typeAnnotation?.type else { return false }

        if type.is(OptionalTypeSyntax.self) || type.is(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
            return true
        }
        return type.as(IdentifierTypeSyntax.self)?.name.text == "Optional"
    }

    /// The member names that `closures` read, in source order
    ///
    /// A shorthand `if let name` reads the member `name` , but the tree holds no reference
    /// expression for it. The rule counts it as a read.
    private static func readNames(
        in closures: [ClosureExprSyntax],
        of entry: TypeMemberIndex.TypeEntry
    ) -> [String] {
        closures.flatMap { closure in
            let finder = ShorthandBindingFinder(viewMode: .sourceAccurate)
            finder.walk(closure)
            return finder.names
                + TypeMemberIndex.references(in: closure, of: entry).map(\.name)
        }
    }

    private final class ShorthandBindingFinder: SyntaxVisitor {
        var names: [String] = []

        override func visit(_ node: OptionalBindingConditionSyntax) -> SyntaxVisitorContinueKind {
            if node.initializer == nil,
               let name = node.pattern.as(IdentifierPatternSyntax.self)?.identifier.text {
                names.append(name)
            }
            return .visitChildren
        }
    }

    /// Every closure the modifier call passes, trailing or as an argument
    private static func contentClosures(of node: FunctionCallExprSyntax) -> [ClosureExprSyntax] {
        var closures = node.arguments.compactMap { $0.expression.as(ClosureExprSyntax.self) }
        if let trailing = node.trailingClosure { closures.append(trailing) }
        closures += node.additionalTrailingClosures.map(\.closure)
        return closures
    }
}

fileprivate extension Finding.Message {
    static func useItemPresentation(
        modifier: String,
        flag: String,
        value: String,
        fix: String
    ) -> Finding.Message {
        """
        '.\(modifier)(isPresented: $\(flag))' pairs a Bool with the optional '\(value)', and the \
        two can disagree. Present with the '\(fix)' form and one 'Binding<T?>'
        """
    }

    static func presentingFlag(_ name: String) -> Finding.Message {
        "'\(name)' is the Bool that presents"
    }

    static func optionalValue(_ name: String) -> Finding.Message {
        "'\(name)' is the optional value the content reads"
    }
}
