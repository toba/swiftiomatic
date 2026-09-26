import SwiftSyntax

/// Flag collection work in a view's `body` , or in a computed property or method that `body` reads.
///
/// A computed property is not stored. It runs again on every `body` evaluation, and so does every
/// method `body` calls. A `.filter` , `.sorted` , `.map` or loop there walks the whole collection
/// on each update, even when the collection did not change. Store the derived value and update it
/// when its inputs change.
///
/// The rule checks `body` itself, and follows it into same-type computed properties and the
/// methods it calls, and from those into further members. Closures that run later, such as a
/// `Button` action or a `.task` body, are not followed. A method named without a call, such as a
/// function reference passed to a drop delegate, runs later too, so the rule does not follow it.
///
/// A reached member can call a static function on another type, such as `Row.rows(projects:)` .
/// When the file declares that type, the rule follows the call into the function body. When the
/// type is declared in another file, the rule cannot see the body. It then reports the call when an
/// argument passes a stored collection of the view, because the function most likely walks it.
///
/// Lint: `body` , a same-type member that `body` reaches, or a same-file static function it calls,
/// calls `filter` , `sorted` , `map` , `compactMap` , `flatMap` or `reduce` , or holds a `for` ,
/// `while` or `repeat` loop. `body` or a reached member passes a stored collection of the view to
/// a static function declared in another file.
final class NoCollectionWorkReachableFromBody: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }

    private static let collectionMethods: Set<String> = [
        "filter", "sorted", "map", "compactMap", "flatMap", "reduce",
    ]

    /// Calls whose closures run in response to an event rather than during `body`
    private static let deferredClosureCalls: Set<String> = [
        "Task", "immediate", "detached", "immediateDetached", "onTapGesture", "onLongPressGesture",
        "onAppear", "onDisappear", "task",
        "onChange", "onSubmit", "onReceive", "refreshable", "onHover", "onContinuousHover",
        "onEnded", "onChanged", "onDelete", "onMove", "onInsert", "onDrop", "onKeyPress",
        "onOpenURL", "onCommand", "onExitCommand", "onScrollGeometryChange", "onGeometryChange",
        "dropDestination", "draggable", "onPreferenceChange",
    ]

    /// Whether a call named `name` runs its closures later. Any call whose name ends in `Button`
    /// counts, so a custom button type is covered too.
    private static func defersClosures(_ name: String) -> Bool {
        name.hasSuffix("Button") || deferredClosureCalls.contains(name)
    }

    /// Argument labels that pass a closure to run later
    private static let deferredClosureLabels: Set<String> = ["action", "perform", "set"]

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        guard node.parent?.is(MemberBlockItemSyntax.self) == true,
              let binding = node.bindings.first,
              binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == "body",
              let accessor = binding.accessorBlock,
              let entry = context.typeMembers(around: node).enclosingType(of: node),
              entry.isView else { return .visitChildren }

        var visited: Set<SyntaxIdentifier> = [node.id]
        var pending = Self.reachedMembers(from: accessor, entry: entry)
        let types = context.typeMembers(around: node).types
        let viewName = TypeMemberIndex.enclosingTypeName(of: node) ?? ""

        for call in reportWork(in: Syntax(accessor), member: "body") {
            reportStaticCall(
                call, selfType: viewName, view: entry, types: types, visited: &visited)
        }

        while !pending.isEmpty {
            let (name, member) = pending.removeFirst()
            guard let body = member.body, visited.insert(member.declaration.id).inserted
            else { continue }

            for call in reportWork(in: body, member: name) {
                reportStaticCall(
                    call, selfType: viewName, view: entry, types: types, visited: &visited)
            }
            pending += Self.reachedMembers(from: body, entry: entry)
        }
        return .visitChildren
    }

    /// Reports the collection work in `body` and returns the static calls on other types it makes
    private func reportWork(in body: Syntax, member: String) -> [WorkFinder.StaticCall] {
        let finder = WorkFinder(methods: Self.collectionMethods, skipping: Self.isDeferred)
        finder.walk(body)

        for (message, anchor) in finder.matches {
            switch message {
                case let .call(method): diagnose(.collectionCall(method, member), on: anchor)
                case let .loop(keyword): diagnose(.collectionLoop(keyword, member), on: anchor)
            }
        }
        return finder.staticCalls
    }

    /// Follows a static call into a same-file type, or reports it when it passes a stored
    /// collection of the view to a type declared elsewhere
    ///
    /// The rule follows the static calls a followed function makes too. `visited` stops a cycle.
    ///
    /// - Parameter selfType: The type that `Self` names at the call site.
    private func reportStaticCall(
        _ call: WorkFinder.StaticCall,
        selfType: String,
        view: TypeMemberIndex.TypeEntry,
        types: [String: TypeMemberIndex.TypeEntry],
        visited: inout Set<SyntaxIdentifier>
    ) {
        let typeName = call.typeName == "Self" ? selfType : call.typeName
        let function = "\(typeName).\(call.method.baseName.text)"

        guard let owner = types[typeName] else {
            if let collection = call.node.arguments.lazy
                .compactMap({ Self.storedCollectionName($0.expression, in: view) }).first
            {
                diagnose(.opaqueStaticCall(function, collection), on: call.method)
            }
            return
        }

        for member in owner.members[call.method.baseName.text] ?? [] where member.isStatic {
            guard let body = member.body, visited.insert(member.declaration.id).inserted
            else { continue }

            for nested in reportWork(in: body, member: function) {
                reportStaticCall(
                    nested, selfType: typeName, view: view, types: types, visited: &visited)
            }
        }
    }

    /// The name of the view's stored collection property that `expression` reads, if any
    private static func storedCollectionName(
        _ expression: ExprSyntax,
        in view: TypeMemberIndex.TypeEntry
    ) -> String? {
        guard let name = expression.selfMemberReference?.baseName.text else { return nil }

        for member in view.members[name] ?? [] where member.kind == .storedProperty {
            let binding = member.declaration.as(VariableDeclSyntax.self)?.bindings.first {
                $0.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == name
            }
            if let type = binding?.typeAnnotation?.type, isCollectionType(type) { return name }
        }
        return nil
    }

    private static func isCollectionType(_ type: TypeSyntax) -> Bool {
        let type = type.unwrappingOptional
        if type.is(ArrayTypeSyntax.self) || type.is(DictionaryTypeSyntax.self) { return true }
        return ["Array", "Set", "Dictionary", "ContiguousArray", "OrderedSet", "OrderedDictionary"]
            .contains(type.as(IdentifierTypeSyntax.self)?.name.text ?? "")
    }

    /// The computed properties and methods a region reads, in source order
    private static func reachedMembers(
        from region: some SyntaxProtocol,
        entry: TypeMemberIndex.TypeEntry
    ) -> [(String, TypeMemberIndex.Member)] {
        TypeMemberIndex.references(in: region, of: entry, skipping: isDeferred)
            .filter { !$0.spelling.hasPrefix("$") }
            .flatMap { reference in
                // follow every overload, because a syntax-only rule cannot pick the one called.
                // A method named without a call, such as `canDrop: canDrop` , passes a function
                // reference that runs later, so the rule does not follow it.
                let called = isCalled(reference.node)
                return reference.members
                    .filter { $0.kind == .computedProperty || ($0.kind == .method && called) }
                    .map { (reference.name, $0) }
            }
    }

    /// Whether `reference` is the callee of a call, as `name(...)` or `self.name(...)`
    private static func isCalled(_ reference: DeclReferenceExprSyntax) -> Bool {
        var callee = Syntax(reference)
        if let access = reference.parent?.as(MemberAccessExprSyntax.self),
           access.declName.id == reference.id
        {
            callee = Syntax(access)
        }
        return callee.parent?.as(FunctionCallExprSyntax.self)?.calledExpression.id == callee.id
    }

    /// Whether a closure runs later than the `body` evaluation that builds it
    private static func isDeferred(_ closure: ClosureExprSyntax) -> Bool {
        guard let call = closure.owningCall, let name = call.calleeBaseName else { return false }

        if let label = closure.parent?.as(LabeledExprSyntax.self)?.label?.text {
            return deferredClosureLabels.contains(label) || defersClosures(name)
        }
        // `Button(action:label:)` takes its label as the trailing closure
        if name.hasSuffix("Button"), call.arguments.contains(where: { $0.label?.text == "action" })
        { return false }
        return defersClosures(name)
    }

    private final class WorkFinder: SyntaxVisitor {
        enum Work {
            case call(String)
            case loop(String)
        }

        /// A call such as `Row.rows(projects:)` on a type other than `Self`
        struct StaticCall {
            let typeName: String
            let method: DeclReferenceExprSyntax
            let node: FunctionCallExprSyntax
        }

        let methods: Set<String>
        let skipping: (ClosureExprSyntax) -> Bool
        var matches: [(Work, Syntax)] = []
        var staticCalls: [StaticCall] = []

        init(methods: Set<String>, skipping: @escaping (ClosureExprSyntax) -> Bool) {
            self.methods = methods
            self.skipping = skipping
            super.init(viewMode: .sourceAccurate)
        }

        override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
            skipping(node) ? .skipChildren : .visitChildren
        }

        override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
            guard let member = node.calledExpression.as(MemberAccessExprSyntax.self),
                  let base = member.base else { return .visitChildren }

            // `Grouping.sorted(x)` calls a static function, not the collection method
            if let reference = base.as(DeclReferenceExprSyntax.self),
               let typeName = Self.staticCallBase(reference.baseName)
            {
                staticCalls.append(StaticCall(typeName: typeName, method: member.declName, node: node))
            } else if methods.contains(member.declName.baseName.text) {
                matches.append((.call(member.declName.baseName.text), Syntax(member.declName)))
            }
            return .visitChildren
        }

        /// The type a static call names: an uppercase identifier, or `Self`
        private static func staticCallBase(_ token: TokenSyntax) -> String? {
            switch token.tokenKind {
                case .keyword(.Self): "Self"
                case let .identifier(name) where name.first?.isUppercase == true: name
                default: nil
            }
        }

        override func visit(_ node: ForStmtSyntax) -> SyntaxVisitorContinueKind {
            matches.append((.loop("for"), Syntax(node.forKeyword)))
            return .visitChildren
        }

        override func visit(_ node: WhileStmtSyntax) -> SyntaxVisitorContinueKind {
            matches.append((.loop("while"), Syntax(node.whileKeyword)))
            return .visitChildren
        }

        override func visit(_ node: RepeatStmtSyntax) -> SyntaxVisitorContinueKind {
            matches.append((.loop("repeat"), Syntax(node.repeatKeyword)))
            return .visitChildren
        }
    }
}

fileprivate extension Finding.Message {
    static func collectionCall(_ method: String, _ member: String) -> Finding.Message {
        "'.\(method)' in '\(member)' runs on every 'body' evaluation. Store the derived value and update it when its inputs change"
    }

    static func opaqueStaticCall(_ function: String, _ collection: String) -> Finding.Message {
        "'\(function)' takes the collection '\(collection)' and runs on every 'body' evaluation. Store the derived value and update it when its inputs change"
    }

    static func collectionLoop(_ keyword: String, _ member: String) -> Finding.Message {
        "'\(keyword)' loop in '\(member)' runs on every 'body' evaluation. Store the derived value and update it when its inputs change"
    }
}
