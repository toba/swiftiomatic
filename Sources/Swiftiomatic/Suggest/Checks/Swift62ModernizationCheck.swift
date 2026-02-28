import SwiftSyntax

/// §4: Finds code that can benefit from Swift 6.2 features.
public final class Swift62ModernizationCheck: BaseCheck {

    // MARK: - Task.detached → @concurrent

    override public func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        let callee = node.calledExpression.trimmedDescription

        if callee == "Task.detached" {
            addFinding(
                at: node,
                category: .swift62Modernization,
                severity: .medium,
                message: "Task.detached may be replaceable with @concurrent",
                suggestion: "Use @concurrent on an async function instead — but note @concurrent inherits @TaskLocal values while Task.detached drops them",
                confidence: .low
            )
        }

        // withObservationTracking → Observations
        if callee == "withObservationTracking" {
            addFinding(
                at: node,
                category: .swift62Modernization,
                severity: .medium,
                message: "withObservationTracking can be replaced with Observations AsyncSequence in Swift 6.2",
                suggestion: "for await value in Observations { ... }",
                confidence: .medium
            )
        }

        return .visitChildren
    }

    // MARK: - weak var that could be weak let

    override public func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        let hasWeak = node.modifiers.contains { $0.name.text == "weak" }
        guard hasWeak else { return .visitChildren }

        // weak var → potentially weak let
        if node.bindingSpecifier.tokenKind == .keyword(.var) {
            let bindingName = node.bindings.first?.pattern.trimmedDescription ?? "unknown"
            addFinding(
                at: node,
                category: .swift62Modernization,
                severity: .low,
                message: "weak var '\(bindingName)' — if never reassigned after init, use weak let (SE-0481)",
                confidence: .low
            )
        }

        return .visitChildren
    }

    // MARK: - UnsafeBufferPointer → Span candidates

    override public func visit(_ node: TypeAnnotationSyntax) -> SyntaxVisitorContinueKind {
        let typeStr = node.type.trimmedDescription

        if typeStr.contains("UnsafeRawBufferPointer")
            || typeStr.contains("UnsafeBufferPointer")
            || typeStr.contains("UnsafeMutableRawBufferPointer")
            || typeStr.contains("UnsafeMutableBufferPointer")
        {
            addFinding(
                at: node,
                category: .swift62Modernization,
                severity: .low,
                message: "Unsafe buffer pointer — consider Span/RawSpan (macOS 26.0+)",
                suggestion: "Use Span<T> or RawSpan for safe, non-owning buffer access",
                confidence: .low
            )
        }

        return .visitChildren
    }

    // MARK: - didSet/willSet with side effects

    override public func visit(_ node: AccessorDeclSyntax) -> SyntaxVisitorContinueKind {
        let accessorKind = node.accessorSpecifier.text
        guard accessorKind == "didSet" || accessorKind == "willSet" else {
            return .visitChildren
        }

        // Check if body has non-trivial logic (more than 1 statement)
        if let body = node.body, body.statements.count > 1 {
            addFinding(
                at: node,
                category: .swift62Modernization,
                severity: .low,
                message: "\(accessorKind) with side-effect logic — consider Observations framework if on an @Observable type",
                confidence: .low
            )
        }

        return .visitChildren
    }
}
