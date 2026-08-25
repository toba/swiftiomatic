import SwiftSyntax

/// Flag a checked or unsafe continuation in favour of the form added by SE-0528.
///
/// `withContinuation` yields a noncopyable `Continuation` . Consuming it on `resume` makes a second
/// resume a compile error rather than a runtime trap. A continuation the closure never resumes
/// traps at the point of failure instead of leaking the awaiting task forever.
///
/// A noncopyable value cannot be consumed from an escaping closure and cannot be stored in a
/// `Sendable` box, so the legacy shape that hands the continuation to a callback and resumes it
/// later has no conversion. The rule fires only when the closure resumes the continuation in place,
/// which is the shape `withContinuation` accepts.
///
/// Lint: A call to `withCheckedContinuation` , `withUnsafeContinuation` ,
/// `withCheckedThrowingContinuation` or `withUnsafeThrowingContinuation` whose closure resumes the
/// continuation in place raises a warning.
final class UseContinuationNotChecked: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .unsafety }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        // a member call names someone else's method, not the stdlib free function
        guard let reference = node.calledExpression.as(DeclReferenceExprSyntax.self),
            let form = SupersededForm(name: reference.baseName.text) else { return .visitChildren }
        guard let closure = node.continuationClosure, let binding = closure.continuationBinding
        else { return .visitChildren }

        let scan = ContinuationUseScan(binding: binding)
        scan.walk(closure.statements)
        guard scan.resumesInPlace else { return .visitChildren }

        diagnose(form.message, on: reference.baseName)
        return .visitChildren
    }
}

/// A continuation function SE-0528 supersedes, and the spelling that replaces it.
private enum SupersededForm {
    case plain
    case throwing

    init?(name: String) {
        switch name {
            case "withCheckedContinuation", "withUnsafeContinuation": self = .plain
            case "withCheckedThrowingContinuation", "withUnsafeThrowingContinuation":
                self = .throwing
            default: return nil
        }
    }

    var message: Finding.Message {
        switch self {
            case .plain: .useContinuation
            case .throwing: .useThrowingContinuation
        }
    }
}

/// Counts how a closure uses its continuation parameter.
///
/// A use the closure runs before it returns keeps the conversion open. A use that escapes into a
/// nested closure, or that hands the continuation to someone else, closes it, because a noncopyable
/// `Continuation` cannot be captured or stored.
private final class ContinuationUseScan: SyntaxVisitor {
    private let binding: String
    private var resumeCount = 0
    private var escapes = false

    var resumesInPlace: Bool { resumeCount > 0 && !escapes }

    init(binding: String) {
        self.binding = binding
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
        if node.tokens(viewMode: .sourceAccurate).contains(where: { $0.text == binding }) {
            escapes = true
        }
        return .skipChildren
    }

    override func visit(_ node: DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
        guard node.baseName.text == binding else { return .skipChildren }
        if node.isReceiverOfResume { resumeCount += 1 } else { escapes = true }
        return .skipChildren
    }
}

fileprivate extension FunctionCallExprSyntax {
    /// The closure literal the continuation is handed to, written trailing or in the argument list.
    var continuationClosure: ClosureExprSyntax? {
        trailingClosure ?? arguments.last?.expression.as(ClosureExprSyntax.self)
    }
}

fileprivate extension ClosureExprSyntax {
    /// The name the closure gives its continuation parameter.
    ///
    /// A closure with no signature names it `$0` .
    var continuationBinding: String? {
        guard let parameterClause = signature?.parameterClause else { return "$0" }
        switch parameterClause {
            case let .simpleInput(list): return list.first?.name.text
            case let .parameterClause(clause):
                guard let first = clause.parameters.first else { return nil }
                return (first.secondName ?? first.firstName).text
        }
    }
}

fileprivate extension DeclReferenceExprSyntax {
    /// Whether the reference is the receiver of a `resume` call, as in `continuation.resume(...)` .
    var isReceiverOfResume: Bool {
        guard let member = parent?.as(MemberAccessExprSyntax.self), member.base?.id == id
        else { return false }
        return member.declName.baseName.text == "resume"
    }
}

fileprivate extension Finding.Message {
    static let useContinuation: Finding.Message =
        "a checked continuation traps on a double resume and leaks the awaiting task on a missed one — use 'withContinuation' (SE-0528), whose noncopyable 'Continuation' makes the double resume a compile error"
    static let useThrowingContinuation: Finding.Message =
        "a checked continuation traps on a double resume and leaks the awaiting task on a missed one — use 'withContinuation(throwing: (any Error).self)' (SE-0528), whose noncopyable 'Continuation' makes the double resume a compile error"
}
