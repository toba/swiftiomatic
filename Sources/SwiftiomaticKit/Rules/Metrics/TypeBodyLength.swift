import SwiftSyntax
import ConfigurationKit

/// Type bodies (class, struct, enum, actor, protocol, extension) should not exceed a configurable
/// line length.
final class TypeBodyLength: LintSyntaxRule<TypeBodyLengthConfiguration>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .metrics }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        check(node.memberBlock, on: Syntax(node.classKeyword))
        return .visitChildren
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        check(node.memberBlock, on: Syntax(node.structKeyword))
        return .visitChildren
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        check(node.memberBlock, on: Syntax(node.enumKeyword))
        return .visitChildren
    }

    override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
        check(node.memberBlock, on: Syntax(node.actorKeyword))
        return .visitChildren
    }

    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        check(node.memberBlock, on: Syntax(node.protocolKeyword))
        return .visitChildren
    }

    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        check(node.memberBlock, on: Syntax(node.extensionKeyword))
        return .visitChildren
    }

    private func check(_ memberBlock: MemberBlockSyntax, on anchor: Syntax) {
        let count = bodyLineCount(of: memberBlock, in: context.sourceLocationConverter)
        guard let severity = metricSeverity(
            value: count,
            warning: ruleConfig.warning,
            error: ruleConfig.error
        ) else { return }
        diagnose(
            .typeBodyTooLong(
                lines: count,
                limit: severity == .error ? ruleConfig.error : ruleConfig.warning
            ),
            on: anchor,
            severity: severity
        )
    }
}

fileprivate extension Finding.Message {
    static func typeBodyTooLong(lines: Int, limit: Int) -> Finding.Message {
        "type body has \(lines) lines; limit is \(limit)"
    }
}

// MARK: - Configuration

package struct TypeBodyLengthConfiguration: ThresholdRuleValue {
    package var enabled = true
    /// Type bodies (struct/class/enum/actor) longer than this many lines emit a warning-severity
    /// finding.
    package var warning: Int = 250
    /// Type bodies longer than this many lines emit an error-severity finding.
    package var error: Int = 350

    package init() {}

    package init(from decoder: any Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let v = try c.decodeIfPresent(Bool.self, forKey: .enabled) { enabled = v }
        if let v = try c.decodeIfPresent(Int.self, forKey: .warning) { warning = v }
        if let v = try c.decodeIfPresent(Int.self, forKey: .error) { error = v }
    }

    private enum CodingKeys: String, CodingKey {
        case enabled, warning, error
    }
}
