import SwiftSyntax

/// Computed properties and subscripts that declare both `get` and `set`
/// accessors should list them in a consistent order. The default order is
/// `get` then `set`, matching common Swift style.
///
/// Configure via `accessorOrder.order`:
///   - `"get_set"` (default): emit a finding when the setter precedes the getter.
///   - `"set_get"`: emit a finding when the getter precedes the setter.
///
/// Lint-only: this rule does not auto-fix because reordering accessors with
/// non-trivial bodies risks misplacing trailing comments and trivia.
final class AccessorOrder: LintSyntaxRule<AccessorOrderConfiguration>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .declarations }

    override func visit(_ node: AccessorBlockSyntax) -> SyntaxVisitorContinueKind {
        guard let actualOrder = order(of: node), actualOrder != ruleConfig.order else {
            return .visitChildren
        }
        guard case .accessors(let accessors) = node.accessors,
            let firstAccessor = accessors.first
        else {
            return .visitChildren
        }
        let isSubscript = node.parent?.as(SubscriptDeclSyntax.self) != nil
        diagnose(.accessorOrder(expected: ruleConfig.order, isSubscript: isSubscript), on: firstAccessor)
        return .visitChildren
    }

    private func order(of node: AccessorBlockSyntax) -> AccessorOrderConfiguration.Order? {
        guard case .accessors(let accessors) = node.accessors,
            accessors.count == 2,
            accessors.allSatisfy({ $0.body != nil })
        else {
            return nil
        }
        let kinds = accessors.map(\.accessorSpecifier.tokenKind)
        if kinds == [.keyword(.get), .keyword(.set)] { return .getSet }
        if kinds == [.keyword(.set), .keyword(.get)] { return .setGet }
        return nil
    }
}

extension Finding.Message {
    fileprivate static func accessorOrder(
        expected: AccessorOrderConfiguration.Order,
        isSubscript: Bool
    ) -> Finding.Message {
        let kind = isSubscript ? "subscripts" : "computed properties"
        let order: String
        switch expected {
        case .getSet: order = "getter and then the setter"
        case .setGet: order = "setter and then the getter"
        }
        return "\(kind) should declare the \(order)"
    }
}

// MARK: - Configuration

package struct AccessorOrderConfiguration: SyntaxRuleValue {
    package enum Order: String, Codable, Sendable {
        case getSet = "get_set"
        case setGet = "set_get"
    }

    package var rewrite = false
    package var lint: Lint = .warn
    /// Required ordering for `get`/`set` accessors in computed properties and subscripts.
    package var order: Order = .getSet

    package init() {}

    package init(from decoder: any Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let lint = try container.decodeIfPresent(Lint.self, forKey: .lint) { self.lint = lint }
        self.order = try container.decodeIfPresent(Order.self, forKey: .order) ?? .getSet
    }
}
