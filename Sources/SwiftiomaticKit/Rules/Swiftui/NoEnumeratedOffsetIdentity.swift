import SwiftSyntax

/// Flag a `ForEach` or `List` over `enumerated()` pairs that uses the offset as the row identity.
///
/// The offset of an `enumerated()` pair is a counter, not an identity. When an element is inserted,
/// removed or moved, the rows after it get new offsets. SwiftUI then treats them as other rows: it
/// moves their state to the wrong element and animates the wrong change.
///
/// Identify each row by the element, with `id: \.element.id` for an `Identifiable` element or
/// another stable key path, and keep the offset for display, such as a step number. Since Swift 6.2
/// (SE-0459) the enumerated sequence is a collection, so `ForEach(steps.enumerated(), ...)` needs
/// no `Array` around it.
///
/// Keep the offset only when the collection never changes and its order is fixed. The rule accepts
/// an array literal as such a collection. For other fixed data, such as positional labels, suppress
/// the finding.
///
/// Lint: A `ForEach` or `List` iterates `enumerated()` pairs with `id: \.offset`.
final class NoEnumeratedOffsetIdentity: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }
    override class var guidance: GuidanceLevel { .shouldNot }

    private static let containers: Set<String> = ["ForEach", "List"]

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let name = node.constructedTypeName,
              Self.containers.contains(name),
              let identity = node.arguments.first(where: { $0.label?.text == "id" }),
              Self.isOffsetKeyPath(identity.expression),
              let data = node.arguments.first(where: { $0.label == nil })?.expression,
              let base = Self.enumeratedBase(of: data),
              !base.is(ArrayExprSyntax.self) else { return .visitChildren }
        diagnose(.offsetIdentity, on: identity)
        return .visitChildren
    }

    /// Whether `expression` is the key path `\.offset`
    private static func isOffsetKeyPath(_ expression: ExprSyntax) -> Bool {
        guard let keyPath = expression.as(KeyPathExprSyntax.self),
              keyPath.root == nil,
              let only = keyPath.components.firstAndOnly,
              case let .property(property) = only.component else { return false }
        return property.declName.baseName.text == "offset"
    }

    /// The collection that `data` enumerates, for `x.enumerated()` and `Array(x.enumerated())`
    private static func enumeratedBase(of data: ExprSyntax) -> ExprSyntax? {
        if let call = data.as(FunctionCallExprSyntax.self),
           call.constructedTypeName == "Array",
           let only = call.arguments.firstAndOnly,
           only.label == nil { return enumeratedBase(of: only.expression) }
        guard let call = data.as(FunctionCallExprSyntax.self),
              call.arguments.isEmpty,
              call.trailingClosure == nil,
              let access = call.calledExpression.as(MemberAccessExprSyntax.self),
              access.declName.baseName.text == "enumerated" else { return nil }
        return access.base
    }
}

fileprivate extension Finding.Message {
    static let offsetIdentity: Finding.Message = """
        'id: \\.offset' ties each row to its position, so an insert, a removal or a move gives rows \
        the wrong identity and state. Use 'id: \\.element.id' and keep the offset for display
        """
}
