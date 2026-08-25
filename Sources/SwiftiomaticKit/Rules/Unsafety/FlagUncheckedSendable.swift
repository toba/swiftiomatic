import SwiftSyntax
import ConfigurationKit

/// Flag `@unchecked Sendable` conformances. The `@unchecked` opts out of compiler-enforced
/// data-race safety — the type might still be safe (e.g. all storage is protected by a lock), but
/// the conformance bypasses verification and warrants human review. SE-0470's `sending`,
/// metatype-aware `Sendable`, or refactoring to actor isolation often eliminates the need.
///
/// Flag-only — choosing the correct fix needs type information this rule doesn't have.
///
/// A subclass of a `Sendable` class cannot drop the conformance. The compiler answers a bare
/// subclass with `must restate inherited '@unchecked Sendable' conformance`, so a warning there
/// asks for a change that does not build. Name those superclasses in `sendableSuperclasses` and the
/// rule leaves their subclasses alone.
final class FlagUncheckedSendable: LintSyntaxRule<FlagUncheckedSendableConfiguration>,
    @unchecked Sendable
{
    override class var group: ConfigurationGroup? { .unsafety }

    override func visit(_ node: InheritedTypeSyntax) -> SyntaxVisitorContinueKind {
        guard let attributed = node.type.as(AttributedTypeSyntax.self) else {
            return .visitChildren
        }

        let hasUnchecked = attributed.attributes.contains { element in
            guard case let .attribute(attr) = element,
                  let ident = attr.attributeName.as(IdentifierTypeSyntax.self) else { return false }
            return ident.name.text == "unchecked"
        }
        guard hasUnchecked else { return .visitChildren }

        let baseName = attributed.baseType.trimmedDescription
        guard baseName == "Sendable" || baseName.hasSuffix(".Sendable") else {
            return .visitChildren
        }
        guard !inheritsConformance(node) else { return .visitChildren }

        diagnose(.uncheckedSendable, on: node.type)
        return .visitChildren
    }

    /// Whether the enclosing class names an exempt superclass, which makes the restatement
    /// mandatory rather than a choice.
    ///
    /// Only a `class` inherits a conformance, so an extension never qualifies. A superclass leads
    /// the inheritance clause, so the check reads the first entry alone.
    private func inheritsConformance(_ node: InheritedTypeSyntax) -> Bool {
        guard !ruleConfig.sendableSuperclasses.isEmpty,
              let list = node.parent?.as(InheritedTypeListSyntax.self),
              let clause = list.parent?.as(InheritanceClauseSyntax.self),
              clause.parent?.is(ClassDeclSyntax.self) == true,
              let first = list.first,
              first.id != node.id else { return false }

        // `StaticFormatRule<BasicRuleValue>` is exempted by the bare name
        let superclass = first.type.as(IdentifierTypeSyntax.self)?.name.text
            ?? first.type.trimmedDescription
        return ruleConfig.sendableSuperclasses.contains(superclass)
    }
}

package struct FlagUncheckedSendableConfiguration: SyntaxRuleValue {
    package var lint: Lint = .warn
    /// Classes whose subclasses must restate `@unchecked Sendable` , written without any generic
    /// argument list.
    package var sendableSuperclasses: [String] = []

    package var rewrite = false

    package init() {}

    package init(from decoder: any Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let v = try c.decodeIfPresent(Lint.self, forKey: .lint) { lint = v }
        if let v = try c.decodeIfPresent([String].self, forKey: .sendableSuperclasses) {
            sendableSuperclasses = v
        }
    }

    private enum CodingKeys: String, CodingKey { case lint, sendableSuperclasses }
}

fileprivate extension Finding.Message {
    static let uncheckedSendable: Finding.Message =
        "'@unchecked Sendable' bypasses data-race verification — review whether actor isolation, 'Mutex', or 'sending' would let the compiler check it"
}
