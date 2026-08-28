import Foundation
import SwiftParser
import SwiftSyntax

/// A rewrite hook a rule can declare.
package enum RewriteHookKind: String, CaseIterable, Sendable { case transform, willEnter, didExit }

/// Fails the generator when a rule declares a rewrite hook that nothing dispatches.
///
/// A rule joins the pipeline by declaring an overload, so an overload nothing runs is a silent
/// no-op rather than a compile error. `RewritePipelineGenerator` emits a call for every hook the
/// collector places, and two node kinds stay hand-written. This audit holds those two to the same
/// coverage, and it rejects a rule the generator had to drop for want of a `rewriteOrder` .
package enum RewriteDispatchAudit {
    /// A node kind whose dispatch a hand-written file owns.
    package struct ExternalDispatcher {
        /// The node kind the file dispatches.
        package let node: String

        /// The hook kinds the file owns. The generated pipeline still emits the rest.
        package let hooks: Set<RewriteHookKind>

        /// The file that has to name each participating rule.
        package let file: URL

        package init(node: String, hooks: Set<RewriteHookKind>, file: URL) {
            self.node = node
            self.hooks = hooks
            self.file = file
        }
    }

    /// The dispatch the generator does not emit.
    ///
    /// `rewriteSourceFile` runs the file-level transforms once over the settled tree, after the
    /// walk the generated pipeline drives. `rewriteToken` owns the token rule order outright,
    /// because the layout writer calls it as well as the pipeline.
    package static func handWrittenDispatchers(for paths: GeneratePaths) -> [ExternalDispatcher] {
        [
            ExternalDispatcher(
                node: "SourceFileSyntax", hooks: [.transform], file: paths.sourceFileRewriteFile),
            ExternalDispatcher(
                node: "TokenSyntax", hooks: Set(RewriteHookKind.allCases),
                file: paths.tokenRewriteFile),
        ]
    }

    /// Describes every declared hook that no dispatcher runs. An empty result means full coverage.
    ///
    /// - Parameters:
    ///   - collector: The collected hooks, already scanned from the rule tree.
    ///   - dispatchers: The node kinds whose dispatch lives outside the generated pipeline.
    /// - Returns: One sentence per gap, sorted, each naming the rule and the node kind.
    package static func gaps(
        in collector: RewriteHookCollector,
        dispatchers: [ExternalDispatcher]
    ) throws(ScanError) -> [String] {
        var calls: [String: Set<MemberReference>] = [:]

        for dispatcher in dispatchers where calls[dispatcher.file.path] == nil {
            calls[dispatcher.file.path] = try staticCalls(in: dispatcher.file)
        }
        var owners: [String: ExternalDispatcher] = [:]

        for dispatcher in dispatchers { owners[dispatcher.node] = dispatcher }
        var results: [String] = []

        let ordered = collector.hooksByNode.values.flatMap(\.self)

        for hook in ordered + collector.unorderedHooks {
            let owner = owners[hook.node]

            for kind in RewriteHookKind.allCases where hook.declares(kind) {
                if let owner, owner.hooks.contains(kind) {
                    let call = MemberReference(type: hook.rule, member: kind.rawValue)

                    if !(calls[owner.file.path]?.contains(call) ?? false) {
                        results.append(
                            "\(hook.rule) declares \(kind.rawValue)(_: \(hook.node)) but "
                                + "\(owner.file.lastPathComponent) never calls "
                                + "\(hook.rule).\(kind.rawValue). Add the call or drop the hook.")
                    }
                    continue
                }
                // Everything else is the generated pipeline's, which sorts by `rewriteOrder` .
                if collector.rulesMissingOrder.contains(hook.rule) {
                    results.append(
                        "\(hook.rule) declares \(kind.rawValue)(_: \(hook.node)) but no "
                            + "rewriteOrder, so the generated pipeline cannot place it. Add "
                            + "static let rewriteOrder to \(hook.rule).")
                }
            }
        }
        return results.sorted()
    }

    /// Every `Type.member` reference the file makes.
    ///
    /// A hand-written dispatcher calls each rule by name, so this is what proves the rule runs.
    private static func staticCalls(in file: URL) throws(ScanError) -> Set<MemberReference> {
        guard let source = try? String(contentsOf: file, encoding: .utf8) else {
            throw ScanError.unreadableFile(file)
        }
        let collector = MemberReferenceCollector(viewMode: .sourceAccurate)
        collector.walk(Parser.parse(source: source))
        return collector.references
    }
}

/// One `Type.member` reference a dispatcher makes.
private struct MemberReference: Hashable {
    let type: String
    let member: String
}

/// Gathers `Type.member` references so the audit can tell which rules a dispatcher names.
private final class MemberReferenceCollector: SyntaxVisitor {
    private(set) var references: Set<MemberReference> = []

    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        if let base = node.base?.as(DeclReferenceExprSyntax.self) {
            references.insert(MemberReference(
                type: base.baseName.text, member: node.declName.baseName.text))
        }
        return .visitChildren
    }
}

private extension RewriteHookCollector.Hook {
    func declares(_ kind: RewriteHookKind) -> Bool {
        switch kind {
            case .transform: hasTransform
            case .willEnter: hasWillEnter
            case .didExit: hasDidExit
        }
    }
}
