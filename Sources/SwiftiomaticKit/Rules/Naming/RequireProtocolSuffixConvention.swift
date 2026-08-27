import SwiftSyntax

/// A protocol name should carry the suffix the guidelines give its kind.
///
/// The API Design Guidelines name a capability with `able` or `ible` , and an ongoing action with
/// `ing` . Which one a protocol wants is a judgment about intent, and the syntax tree does not
/// carry intent. The rule therefore works from a table of stems whose conventional Swift spelling
/// is settled, and it reports only a name that ends in the wrong half of a pair.
///
/// `Hashing` becomes `Hashable` , because the conformer *can be* hashed. `ProgressReportable`
/// becomes `ProgressReporting` , because the conformer *does* report progress. A name outside the
/// table raises nothing, and neither does a `struct` , a `class` or an `enum` .
///
/// Ships off by default. The table encodes a convention, and a codebase may hold a name that reads
/// correctly against its own domain.
///
/// Lint: A protocol whose name ends in a tail the table lists raises a warning that names the
/// conventional spelling.
final class RequireProtocolSuffixConvention: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .naming }
    override class var defaultValue: LintOnlyValue { .init(lint: .no) }

    /// A tail whose conventional Swift spelling is the `able` capability form.
    private static let capabilityForm: [String: String] = [
        "Animating": "Animatable",
        "Caching": "Cacheable",
        "Comparing": "Comparable",
        "Configuring": "Configurable",
        "Copying": "Copyable",
        "Decoding": "Decodable",
        "Encoding": "Encodable",
        "Equating": "Equatable",
        "Hashing": "Hashable",
        "Identifying": "Identifiable",
        "Iterating": "Iterable",
        "Rendering": "Renderable",
        "Serializing": "Serializable",
        "Transferring": "Transferable",
        "Validating": "Validatable",
    ]

    /// A tail whose conventional Swift spelling is the `ing` ongoing-action form.
    private static let ongoingForm: [String: String] = [
        "Coordinatable": "Coordinating",
        "Loggable": "Logging",
        "Lockable": "Locking",
        "Monitorable": "Monitoring",
        "Presentable": "Presenting",
        "Reportable": "Reporting",
        "Routable": "Routing",
        "Schedulable": "Scheduling",
        "Trackable": "Tracking",
    ]

    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        let name = node.name.text

        if let suggested = suggestion(for: name, in: Self.capabilityForm) {
            diagnose(.useCapabilityForm(name: name, suggestion: suggested), on: node.name)
        } else if let suggested = suggestion(for: name, in: Self.ongoingForm) {
            diagnose(.useOngoingForm(name: name, suggestion: suggested), on: node.name)
        }
        return .visitChildren
    }

    /// The conventional spelling of `name` , or `nil` when no tail in the table matches. No two
    /// tails overlap, so at most one entry can match and the dictionary order does not matter.
    private func suggestion(for name: String, in table: [String: String]) -> String? {
        for (tail, replacement) in table where name.hasSuffix(tail) {
            return String(name.dropLast(tail.count)) + replacement
        }
        return nil
    }
}

fileprivate extension Finding.Message {
    static func useCapabilityForm(name: String, suggestion: String) -> Finding.Message {
        "the guidelines name a capability with 'able' — rename '\(name)' to '\(suggestion)'"
    }

    static func useOngoingForm(name: String, suggestion: String) -> Finding.Message {
        "the guidelines name an ongoing action with 'ing' — rename '\(name)' to '\(suggestion)'"
    }
}
