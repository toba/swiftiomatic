import SwiftSyntax

/// Flag collection work in a view's `body` , or in a computed property or method that `body` reads.
///
/// A computed property is not stored. It runs again on every `body` evaluation, and so does every
/// method `body` calls. A `.filter` , `.sorted` , `.map` or loop there walks the whole collection
/// on each update, even when the collection did not change. Store the derived value and update it
/// when its inputs change.
///
/// The rule checks `body` itself, and follows it into same-type computed properties and the methods
/// it calls, and from those into further members. Closures that run later, such as a `Button`
/// action or a `.task` body, are not followed. A method named without a call, such as a function
/// reference passed to a drop delegate, runs later too, so the rule does not follow it.
///
/// A reached member can call a static function on another type, such as `Row.rows(projects:)` .
/// When the file declares that type, the rule follows the call into the function body. When the
/// type is declared in another file, the rule cannot see the body. It then reports the call when an
/// argument passes a stored collection of the view, because the function most likely walks it.
///
/// The rule also reports the view type itself, and each member name that `body` reads when that
/// member leads to work. When `body` reaches work through such a member, the rule also reports the
/// `body` declaration. These findings mark where the repeated evaluation starts. A small
/// transform over an array or dictionary literal costs little, so the rule allows it.
///
/// Lint: `body` , a same-type member that `body` reaches, or a same-file static function it calls,
/// calls `filter` , `sorted` , `map` , `compactMap` , `flatMap` or `reduce` , or holds a `for` ,
/// `while` or `repeat` loop. `body` or a reached member passes a stored collection of the view to a
/// static function declared in another file. The view type reaches any of this work. `body` reads a
/// member that leads to any of this work, which the rule reports at the read and at `body` .
final class NoCollectionWorkReachableFromBody: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }

    private static let collectionMethods: Set<String> = [
        "filter", "sorted", "map", "compactMap", "flatMap", "reduce",
    ]

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        guard let binding = node.bindings.first,
              binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == "body",
              let accessor = binding.accessorBlock,
              let entry = context.viewEntry(forMember: node) else { return .visitChildren }

        var visited: Set<SyntaxIdentifier> = [node.id]
        let bodyReferences = Self.reachedMembers(from: accessor, entry: entry)
        var pending = bodyReferences
        let types = context.typeMembers(around: node).types
        let viewName = TypeMemberIndex.enclosingTypeName(of: node) ?? ""

        // The member declarations that hold work, and the members each one reads
        var holdsWork: Set<SyntaxIdentifier> = []
        var reads: [SyntaxIdentifier: [SyntaxIdentifier]] = [:]

        var bodyHoldsWork = reportWorkAndCalls(
            in: Syntax(accessor), member: "body", selfType: viewName, view: entry, types: types,
            visited: &visited)

        while !pending.isEmpty {
            let (name, member, _) = pending.removeFirst()
            guard let body = member.body, visited.insert(member.declaration.id).inserted
            else { continue }

            if reportWorkAndCalls(
                in: body, member: name, selfType: viewName, view: entry, types: types,
                visited: &visited) { holdsWork.insert(member.declaration.id) }
            let next = Self.reachedMembers(from: body, entry: entry)
            reads[member.declaration.id] = next.map(\.1.declaration.id)
            pending += next
        }

        // Report the first read in `body` of each member that leads to work
        var reported: Set<String> = []

        for (name, member, reference) in bodyReferences where !reported.contains(name) {
            guard Self.leadsToWork(member.declaration.id, holdsWork: holdsWork, reads: reads) else {
                continue
            }
            reported.insert(name)
            bodyHoldsWork = true
            diagnose(.bodyReadsWork(name), on: reference)
        }

        // A member moves the work out of sight but not out of `body` , so mark `body` itself
        if !reported.isEmpty { diagnose(.bodyReachesWorkThroughMember, on: binding.pattern) }

        if bodyHoldsWork, let owner = TypeMemberIndex.owningDeclaration(of: node) {
            diagnose(.ownerReachesWork(viewName), on: Self.nameAnchor(of: owner))
        }
        return .visitChildren
    }

    /// Whether the member declared by `start` holds work, or reads a member that leads to work
    private static func leadsToWork(
        _ start: SyntaxIdentifier,
        holdsWork: Set<SyntaxIdentifier>,
        reads: [SyntaxIdentifier: [SyntaxIdentifier]]
    ) -> Bool {
        var seen: Set<SyntaxIdentifier> = []
        var stack = [start]

        while let id = stack.popLast() {
            guard seen.insert(id).inserted else { continue }
            if holdsWork.contains(id) { return true }
            stack += reads[id] ?? []
        }
        return false
    }

    /// The name of the type that `declaration` declares or extends
    ///
    /// An extension of a type that the file does not declare gives its extended type.
    private static func nameAnchor(of declaration: Syntax) -> Syntax {
        if let name = TypeMemberIndex.typeNameToken(of: declaration) { return Syntax(name) }
        if let ext = declaration.as(ExtensionDeclSyntax.self) { return Syntax(ext.extendedType) }
        return declaration
    }

    /// Reports the work in `body` and follows its static calls, and returns whether it reported
    /// anything
    private func reportWorkAndCalls(
        in body: Syntax,
        member: String,
        selfType: String,
        view: TypeMemberIndex.TypeEntry,
        types: [String: TypeMemberIndex.TypeEntry],
        visited: inout Set<SyntaxIdentifier>
    ) -> Bool {
        let (reported, calls) = reportWork(in: body, member: member)
        var found = reported

        for call in calls
            where reportStaticCall(
                call, selfType: selfType, view: view, types: types, visited: &visited)
        { found = true }
        return found
    }

    /// Reports the collection work in `body` . Returns whether it reported anything, and the static
    /// calls on other types that `body` makes.
    private func reportWork(
        in body: Syntax,
        member: String
    ) -> (reported: Bool, calls: [WorkFinder.StaticCall]) {
        let finder = WorkFinder(methods: Self.collectionMethods, skipping: { $0.runsAfterBody })
        finder.walk(body)

        for (message, anchor) in finder.matches {
            switch message {
                case let .call(method): diagnose(.collectionCall(method, member), on: anchor)
                case let .loop(keyword): diagnose(.collectionLoop(keyword, member), on: anchor)
            }
        }
        return (!finder.matches.isEmpty, finder.staticCalls)
    }

    /// Follows a static call into a same-file type, or reports it when it passes a stored
    /// collection of the view to a type declared elsewhere
    ///
    /// The rule follows the static calls a followed function makes too. `visited` stops a cycle.
    ///
    /// - Parameter selfType: The type that `Self` names at the call site.
    /// - Returns: Whether the call, or a function it reaches, has work to report.
    @discardableResult
    private func reportStaticCall(
        _ call: WorkFinder.StaticCall,
        selfType: String,
        view: TypeMemberIndex.TypeEntry,
        types: [String: TypeMemberIndex.TypeEntry],
        visited: inout Set<SyntaxIdentifier>
    ) -> Bool {
        let typeName = call.typeName == "Self" ? selfType : call.typeName
        let function = "\(typeName).\(call.method.baseName.text)"

        guard let owner = types[typeName] else {
            if let collection = call.node.arguments.lazy
                .compactMap({ Self.storedCollectionName($0.expression, in: view) }).first
            {
                diagnose(.opaqueStaticCall(function, collection), on: call.method)
                return true
            }
            return false
        }
        var found = false

        for member in owner.members[call.method.baseName.text] ?? [] where member.isStatic {
            guard let body = member.body, visited.insert(member.declaration.id).inserted
            else { continue }

            if reportWorkAndCalls(
                in: body, member: function, selfType: typeName, view: view, types: types,
                visited: &visited) { found = true }
        }
        return found
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
            if let type = binding?.typeAnnotation?.type, type.isCollectionType { return name }
        }
        return nil
    }

    /// The computed properties and methods a region reads, in source order
    private static func reachedMembers(
        from region: some SyntaxProtocol,
        entry: TypeMemberIndex.TypeEntry
    ) -> [(String, TypeMemberIndex.Member, DeclReferenceExprSyntax)] {
        TypeMemberIndex.references(in: region, of: entry, skipping: { $0.runsAfterBody })
            .filter { !$0.spelling.hasPrefix("$") }
            .flatMap { reference in
                // follow every overload, because a syntax-only rule cannot pick the one called. A
                // method named without a call, such as `canDrop: canDrop` , passes a function
                // reference that runs later, so the rule does not follow it.
                let called = isCalled(reference.node)
                return reference.members
                    .filter { $0.kind == .computedProperty || ($0.kind == .method && called) }
                    .map { (reference.name, $0, reference.node) }
            }
    }

    /// Whether `reference` is the callee of a call, as `name(...)` or `self.name(...)`
    private static func isCalled(_ reference: DeclReferenceExprSyntax) -> Bool {
        var callee = Syntax(reference)

        if let access = reference.parent?.as(MemberAccessExprSyntax.self),
           access.declName.id == reference.id { callee = Syntax(access) }
        return callee.parent?.as(FunctionCallExprSyntax.self)?.calledExpression.id == callee.id
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
                staticCalls.append(StaticCall(
                    typeName: typeName, method: member.declName, node: node))
            } else if methods.contains(member.declName.baseName.text),
               !Self.isLiteralCollection(base) {
                matches.append((.call(member.declName.baseName.text), Syntax(member.declName)))
            }
            return .visitChildren
        }

        /// Whether `expression` is an array or dictionary literal. A small transform over a fixed
        /// literal costs little, so the rule allows it.
        private static func isLiteralCollection(_ expression: ExprSyntax) -> Bool {
            expression.is(ArrayExprSyntax.self) || expression.is(DictionaryExprSyntax.self)
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
            if Self.isLiteralCollection(node.sequence) { return .visitChildren }
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

    static func ownerReachesWork(_ type: String) -> Finding.Message {
        "'\(type)' reaches collection work from 'body'. SwiftUI repeats the work on each update of the view. Store the derived value, or move the work behind a child view"
    }

    static let bodyReachesWorkThroughMember: Finding.Message =
        "'body' reaches collection work through a member it reads. SwiftUI repeats that work on each evaluation of 'body'. Store the derived value, or move the work behind a child view"

    static func bodyReadsWork(_ member: String) -> Finding.Message {
        "'body' reads '\(member)', which walks a collection on every 'body' evaluation. Store the derived value and update it when its inputs change"
    }

    static func opaqueStaticCall(_ function: String, _ collection: String) -> Finding.Message {
        "'\(function)' takes the collection '\(collection)' and runs on every 'body' evaluation. Store the derived value and update it when its inputs change"
    }

    static func collectionLoop(_ keyword: String, _ member: String) -> Finding.Message {
        "'\(keyword)' loop in '\(member)' runs on every 'body' evaluation. Store the derived value and update it when its inputs change"
    }
}
