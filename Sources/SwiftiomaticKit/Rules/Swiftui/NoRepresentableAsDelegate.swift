import SwiftSyntax

/// Flag `.delegate = self` in a type that conforms to a SwiftUI representable protocol.
///
/// A `UIViewRepresentable` , `NSViewRepresentable` or `UIViewControllerRepresentable` is a value
/// that SwiftUI creates again on each update. `self` in `makeUIView(context:)` is a copy that
/// SwiftUI soon discards. A platform delegate that points to it sees stale state, and the platform
/// view keeps a copy that no update reaches.
///
/// Make the coordinator the delegate. Return it from `makeCoordinator()` and assign
/// `context.coordinator` .
///
/// The rule matches a property named `delegate` or with a name that ends in `Delegate` , such as
/// `navigationDelegate` . It reads the conformances of the enclosing type and of its extensions in
/// the same file. A nested coordinator class is a separate type, so the rule does not flag it.
///
/// Lint: A member of a representable type assigns `self` to a delegate property.
final class NoRepresentableAsDelegate: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }
    override class var guidance: GuidanceLevel { .mustNot }

    /// The suffixes of the SwiftUI protocols that bridge a platform view or controller
    private static let representableSuffixes = [
        "ViewRepresentable", "ViewControllerRepresentable", "GestureRecognizerRepresentable",
    ]

    override func visit(_ node: InfixOperatorExprSyntax) -> SyntaxVisitorContinueKind {
        guard node.operator.is(AssignmentExprSyntax.self),
              let target = node.leftOperand.as(MemberAccessExprSyntax.self),
              target.base != nil,
              Self.isDelegateName(target.declName.baseName.text),
              node.rightOperand.as(DeclReferenceExprSyntax.self)?.baseName.tokenKind
              == .keyword(.self),
              let typeName = TypeMemberIndex.enclosingTypeName(of: node),
              let entry = context.typeMembers(around: node).types[typeName],
              entry.conformances.contains(where: Self.isRepresentable) else {
            return .visitChildren
        }
        diagnose(
            .useCoordinator(property: target.declName.baseName.text, type: typeName), on: node)
        return .visitChildren
    }

    private static func isDelegateName(_ name: String) -> Bool {
        name == "delegate" || name.hasSuffix("Delegate")
    }

    private static func isRepresentable(_ name: String) -> Bool {
        representableSuffixes.contains { name.hasSuffix($0) }
    }
}

fileprivate extension Finding.Message {
    static func useCoordinator(property: String, type: String) -> Finding.Message {
        "assign 'context.coordinator' to '\(property)', not 'self'. SwiftUI recreates the value of '\(type)' on each update"
    }
}
