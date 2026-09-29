import SwiftSyntax

/// Flag a `ForEach` whose data is a sequence of integer indices (`<expr>.indices`, `a..<b`, `a...b`
/// or `Range(...)`).
///
/// With indices as data, the identity of each row is its position. When you insert, remove or move
/// an element, the rows after it get the identity of other elements. SwiftUI then moves their
/// `@State` to the wrong element and animates the wrong change. A row that reads `items[index]` or
/// projects the binding `$items[index]` has a further problem. After a reorder or a removal, the
/// binding edits the wrong element, and a stale index can trap with "Index out of range".
///
/// Iterate the elements and give them a stable identity: `ForEach(items) { item in ... }` for
/// `Identifiable` elements. When a row edits its element, iterate the bindings of the collection:
/// `ForEach($items) { $item in TextField("Name", text: $item.name) }`. Do not change to
/// `enumerated()` when the row still reads `$items[index]`, because the binding stays positional.
///
/// Keep the indices only when the collection is a fixed `let` value that never changes. The rule
/// does not detect this case, so suppress the finding there.
///
/// This rule and `FlagForEachIDSelfInView` do not report the same `ForEach`. That rule checks the
/// `id:` argument. This rule checks only the data argument and ignores `id:`. The integer-indexed
/// case belongs to this rule.
///
/// When the rows hold `@State` or `@FocusState` , `FlagStatefulForEachOverIndices` reports the
/// `ForEach` instead of this rule, so a `// sm:ignore` directive for this rule does not hide it.
/// This rule defers only when the configuration enables `FlagStatefulForEachOverIndices` for lint.
/// When that rule is off, this rule reports the stateful case too.
///
/// The rule also reports a `ForEach` over `enumerated()` pairs with `id: \.offset` when the row
/// projects `$items[index]` with the offset. `NoEnumeratedOffsetIdentity` reports the identity of
/// that `ForEach`. This rule reports the positional binding. For elements that are not
/// `Identifiable`, give the bindings a key path: `ForEach($items, id: \.name) { $item in ... }`.
///
/// Lint: The first argument of a `ForEach` is `<expr>.indices`, a `..<` or `...` range, or a
/// `Range(...)` call. Or the `ForEach` iterates `enumerated()` pairs with `id: \.offset` and the
/// row subscripts a projected binding with the offset.
final class FlagForEachOverIndices: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }
    override class var guidance: GuidanceLevel { .shouldNot }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        if let receiver = Self.enumeratedOffsetBindingReceiver(of: node) {
            diagnose(.enumeratedOffsetBinding, on: receiver)
            return .visitChildren
        }
        guard let receiver = Self.integerIndexedReceiver(of: node) else { return .visitChildren }

        // `FlagStatefulForEachOverIndices` owns the case where the rows hold state
        if context.severity(of: FlagStatefulForEachOverIndices.self).isActive,
           FlagStatefulForEachOverIndices.rowState(of: node, context: context) != nil {
            return .visitChildren
        }
        diagnose(.indicesReceiver, on: receiver)
        return .visitChildren
    }

    /// The receiver of a `ForEach` call when it is an integer-index sequence
    static func integerIndexedReceiver(of node: FunctionCallExprSyntax) -> ExprSyntax? {
        guard let ident = node.calledExpression.as(DeclReferenceExprSyntax.self),
            ident.baseName.text == "ForEach",
            let firstArg = node.arguments.first,
            firstArg.label == nil,
            isIntegerIndexedReceiver(firstArg.expression) else { return nil }
        return firstArg.expression
    }

    /// The receiver of a `ForEach` over `enumerated()` pairs with `id: \.offset` whose row projects
    /// the binding `$items[index]` with the offset
    ///
    /// `NoEnumeratedOffsetIdentity` reports the `\.offset` identity. This check reports the
    /// positional binding, which stays wrong after the identity changes to `\.element.id`.
    private static func enumeratedOffsetBindingReceiver(of node: FunctionCallExprSyntax)
        -> ExprSyntax?
    {
        guard let ident = node.calledExpression.as(DeclReferenceExprSyntax.self),
              ident.baseName.text == "ForEach",
              let firstArg = node.arguments.first,
              firstArg.label == nil,
              NoEnumeratedOffsetIdentity.enumeratedBase(of: firstArg.expression) != nil,
              let identity = node.arguments.first(where: { $0.label?.text == "id" }),
              NoEnumeratedOffsetIdentity.isOffsetKeyPath(identity.expression),
              let closure = node.trailingClosure
                  ?? node.arguments.last?.expression.as(ClosureExprSyntax.self),
              let offset = offsetParameterName(of: closure) else { return nil }
        let finder = BindingSubscriptFinder(index: offset)
        finder.walk(closure.statements)
        return finder.found ? firstArg.expression : nil
    }

    /// The name of the first closure parameter, which holds the offset of the pair
    private static func offsetParameterName(of closure: ClosureExprSyntax) -> String? {
        let name: TokenSyntax? = switch closure.signature?.parameterClause {
            case let .simpleInput(list): list.first?.name
            case let .parameterClause(clause): clause.parameters.first?.firstName
            case nil: nil
        }
        guard let name, name.tokenKind != .wildcard else { return nil }
        return name.text
    }

    private static func isIntegerIndexedReceiver(_ expr: ExprSyntax) -> Bool {
        if let member = expr.as(MemberAccessExprSyntax.self),
           member.declName.baseName.text == "indices" { return true }

        if let infix = expr.as(InfixOperatorExprSyntax.self),
           let op = infix.operator.as(BinaryOperatorExprSyntax.self)
        {
            let text = op.operator.text
            if text == "..<" || text == "..." { return true }
        }
        if let seq = expr.as(SequenceExprSyntax.self) {
            for element in seq.elements {
                if let op = element.as(BinaryOperatorExprSyntax.self) {
                    let text = op.operator.text
                    if text == "..<" || text == "..." { return true }
                }
            }
        }
        if let call = expr.as(FunctionCallExprSyntax.self),
           let callee = call.calledExpression.as(DeclReferenceExprSyntax.self),
           callee.baseName.text == "Range" { return true }
        return false
    }
}

/// Finds a subscript on a projected binding, such as `$items[index]` or `$items[guarded: index]`,
/// whose arguments read the offset
private final class BindingSubscriptFinder: SyntaxVisitor {
    let index: String
    var found = false

    init(index: String) {
        self.index = index
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: SubscriptCallExprSyntax) -> SyntaxVisitorContinueKind {
        if found { return .skipChildren }
        if let base = node.calledExpression.as(DeclReferenceExprSyntax.self),
           case .identifier = base.baseName.tokenKind,
           base.baseName.text.hasPrefix("$"),
           node.arguments.contains(where: { argument in
               argument.expression.tokens(viewMode: .sourceAccurate)
                   .contains { $0.tokenKind == .identifier(index) }
           })
        {
            found = true
            return .skipChildren
        }
        return .visitChildren
    }
}

fileprivate extension Finding.Message {
    static let indicesReceiver: Finding.Message =
        "'ForEach' over indices gives each row a positional identity. Iterate the elements, or use 'ForEach($items) { $item in ... }' for bindings"

    static let enumeratedOffsetBinding: Finding.Message =
        "'$items[index]' from an 'enumerated()' offset is a positional binding, so a removal or a move makes the row edit another element. Use 'ForEach($items, id: ...) { $item in ... }'"
}
