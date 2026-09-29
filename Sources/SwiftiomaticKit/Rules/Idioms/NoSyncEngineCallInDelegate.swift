import SwiftSyntax

/// Flag a `fetchChanges` or `sendChanges` call inside a `CKSyncEngineDelegate` callback.
///
/// `CKSyncEngine` calls `handleEvent(_:syncEngine:)` and `nextRecordZoneChangeBatch(_:syncEngine:)`
/// while it fetches or sends changes. A call to `fetchChanges()` or `sendChanges()` from one of
/// these methods starts a new sync operation, which calls the delegate again. The result is an
/// infinite loop. The engine schedules its own fetches and sends, so the delegate does not start
/// them.
///
/// The rule checks the body of `handleEvent` when the method has a `syncEngine:` parameter, and the
/// body of `nextRecordZoneChangeBatch` . A closure in the body, such as a `Task` , counts as a part
/// of the body. A nested function does not.
///
/// Lint: `.fetchChanges(` or `.sendChanges(` appears inside `handleEvent(_:syncEngine:)` or
/// `nextRecordZoneChangeBatch` .
final class NoSyncEngineCallInDelegate: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }
    override class var guidance: GuidanceLevel { .mustNot }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let member = node.calledExpression.as(MemberAccessExprSyntax.self),
              member.base != nil else { return .visitChildren }
        let name = member.declName.baseName.text
        guard name == "fetchChanges" || name == "sendChanges",
              let method = Self.delegateMethod(enclosing: node) else { return .visitChildren }
        diagnose(.engineCallInDelegate(name, method), on: member.declName)
        return .visitChildren
    }

    /// The display name of the delegate callback that most closely holds `node` , or `nil`
    ///
    /// The search stops at the nearest function, initializer or accessor.
    private static func delegateMethod(enclosing node: some SyntaxProtocol) -> String? {
        var current = node.parent

        while let cur = current {
            if let function = cur.as(FunctionDeclSyntax.self) {
                let name = function.name.text
                if name == "nextRecordZoneChangeBatch" { return name }
                if name == "handleEvent",
                   function.signature.parameterClause.parameters.contains(where: {
                       $0.firstName.text == "syncEngine"
                   }) { return "handleEvent(_:syncEngine:)" }
                return nil
            }
            if cur.is(InitializerDeclSyntax.self) || cur.is(AccessorDeclSyntax.self)
                || cur.is(DeinitializerDeclSyntax.self) { return nil }
            current = cur.parent
        }
        return nil
    }
}

fileprivate extension Finding.Message {
    static func engineCallInDelegate(_ call: String, _ method: String) -> Finding.Message {
        "'\(call)()' inside '\(method)' makes the sync engine call its delegate again; let the engine schedule its own work"
    }
}
