import SwiftSyntax

/// Flag collection work in a computed property or method that a view's `body` reads.
///
/// A computed property is not stored. It runs again on every `body` evaluation, and so does every
/// method `body` calls. A `.filter` , `.sorted` , `.map` or loop there walks the whole collection
/// on each update, even when the collection did not change. Store the derived value and update it
/// when its inputs change.
///
/// The rule follows `body` into same-type computed properties and methods, and from those into
/// further members. Closures that run later, such as a `Button` action or a `.task` body, are not
/// followed.
///
/// Lint: A same-type member that `body` reaches calls `filter` , `sorted` , `map` , `compactMap` ,
/// `flatMap` or `reduce` , or holds a `for` , `while` or `repeat` loop.
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

        while !pending.isEmpty {
            let (name, member) = pending.removeFirst()
            guard let body = member.body, visited.insert(member.declaration.id).inserted
            else { continue }
            reportWork(in: body, member: name)
            pending += Self.reachedMembers(from: body, entry: entry)
        }
        return .visitChildren
    }

    private func reportWork(in body: Syntax, member: String) {
        let finder = WorkFinder(methods: Self.collectionMethods, skipping: Self.isDeferred)
        finder.walk(body)

        for (message, anchor) in finder.matches {
            switch message {
                case let .call(method): diagnose(.collectionCall(method, member), on: anchor)
                case let .loop(keyword): diagnose(.collectionLoop(keyword, member), on: anchor)
            }
        }
    }

    /// The computed properties and methods a region reads, in source order
    private static func reachedMembers(
        from region: some SyntaxProtocol,
        entry: TypeMemberIndex.TypeEntry
    ) -> [(String, TypeMemberIndex.Member)] {
        TypeMemberIndex.references(in: region, of: entry, skipping: isDeferred)
            .filter { !$0.spelling.hasPrefix("$") }
            .flatMap { reference in
                // follow every overload, because a syntax-only rule cannot pick the one called
                reference.members.filter { $0.kind != .storedProperty }.map { (reference.name, $0) }
            }
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

        let methods: Set<String>
        let skipping: (ClosureExprSyntax) -> Bool
        var matches: [(Work, Syntax)] = []

        init(methods: Set<String>, skipping: @escaping (ClosureExprSyntax) -> Bool) {
            self.methods = methods
            self.skipping = skipping
            super.init(viewMode: .sourceAccurate)
        }

        override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
            skipping(node) ? .skipChildren : .visitChildren
        }

        override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
            if let member = node.calledExpression.as(MemberAccessExprSyntax.self),
                member.base != nil,
                methods.contains(member.declName.baseName.text)
            {
                matches.append((.call(member.declName.baseName.text), Syntax(member.declName)))
            }
            return .visitChildren
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

    static func collectionLoop(_ keyword: String, _ member: String) -> Finding.Message {
        "'\(keyword)' loop in '\(member)' runs on every 'body' evaluation. Store the derived value and update it when its inputs change"
    }
}
