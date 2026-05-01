import SwiftSyntax
import ConfigurationKit

/// Types and functions should not be excessively nested.
///
/// Tracks nesting depth separately for types ( `class` , `struct` , `enum` , `actor` , `extension`
/// , `protocol` ) and functions/initializers/subscripts. Emits a finding each time a node opens at
/// a depth greater than the configured limit.
final class NestingDepth: LintSyntaxRule<NestingDepthConfiguration>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .metrics }

    private var typeDepth = 0
    private var functionDepth = 0

    private func enterType(anchor: Syntax) {
        typeDepth += 1

        if typeDepth > ruleConfig.typeLevel {
            diagnose(
                .typeNestedTooDeep(depth: typeDepth, limit: ruleConfig.typeLevel),
                on: anchor
            )
        }
    }

    private func leaveType() { typeDepth -= 1 }

    private func enterFunction(anchor: Syntax) {
        functionDepth += 1

        if functionDepth > ruleConfig.functionLevel {
            diagnose(
                .functionNestedTooDeep(
                    depth: functionDepth,
                    limit: ruleConfig.functionLevel
                ),
                on: anchor
            )
        }
    }

    private func leaveFunction() { functionDepth -= 1 }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        enterType(anchor: Syntax(node.classKeyword))
        return .visitChildren
    }
    override func visitPost(_: ClassDeclSyntax) { leaveType() }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        enterType(anchor: Syntax(node.structKeyword))
        return .visitChildren
    }
    override func visitPost(_: StructDeclSyntax) { leaveType() }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        enterType(anchor: Syntax(node.enumKeyword))
        return .visitChildren
    }
    override func visitPost(_: EnumDeclSyntax) { leaveType() }

    override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
        enterType(anchor: Syntax(node.actorKeyword))
        return .visitChildren
    }
    override func visitPost(_: ActorDeclSyntax) { leaveType() }

    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        enterType(anchor: Syntax(node.protocolKeyword))
        return .visitChildren
    }
    override func visitPost(_: ProtocolDeclSyntax) { leaveType() }

    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        enterType(anchor: Syntax(node.extensionKeyword))
        return .visitChildren
    }
    override func visitPost(_: ExtensionDeclSyntax) { leaveType() }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        enterFunction(anchor: Syntax(node.funcKeyword))
        return .visitChildren
    }
    override func visitPost(_: FunctionDeclSyntax) { leaveFunction() }

    override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        enterFunction(anchor: Syntax(node.initKeyword))
        return .visitChildren
    }
    override func visitPost(_: InitializerDeclSyntax) { leaveFunction() }

    override func visit(_ node: SubscriptDeclSyntax) -> SyntaxVisitorContinueKind {
        enterFunction(anchor: Syntax(node.subscriptKeyword))
        return .visitChildren
    }
    override func visitPost(_: SubscriptDeclSyntax) { leaveFunction() }
}

fileprivate extension Finding.Message {
    static func typeNestedTooDeep(depth: Int, limit: Int) -> Finding.Message {
        "type is nested \(depth) levels deep; limit is \(limit)"
    }
    static func functionNestedTooDeep(depth: Int, limit: Int) -> Finding.Message {
        "function is nested \(depth) levels deep; limit is \(limit)"
    }
}

// MARK: - Configuration

package struct NestingDepthConfiguration: SyntaxRuleValue {
    package var lint: Lint = .warn
    /// Maximum permitted nesting depth for type declarations (struct/class/enum/actor/protocol
    /// inside another type).
    package var typeLevel: Int = 1
    /// Maximum permitted nesting depth for nested function-like declarations ( `func` , `init` ,
    /// `subscript` ).
    package var functionLevel: Int = 2

    package var rewrite: Bool {
        get { false }
        set {}
    }

    package init() {}

    package init(from decoder: any Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let v = try c.decodeIfPresent(Lint.self, forKey: .lint) { lint = v }
        if let v = try c.decodeIfPresent(Int.self, forKey: .typeLevel) { typeLevel = v }
        if let v = try c.decodeIfPresent(Int.self, forKey: .functionLevel) { functionLevel = v }
    }

    private enum CodingKeys: String, CodingKey {
        case lint, typeLevel, functionLevel
    }
}
