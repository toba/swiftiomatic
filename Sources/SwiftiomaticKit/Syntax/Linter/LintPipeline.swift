import SwiftSyntax

/// A syntax visitor that delegates to individual rules for linting.
///
/// The class and its `visit` overrides live in `Pipelines+Generated.swift` . Each override passes
/// the rule's dense index as a literal, so the helpers here hash nothing on the per-node path.
extension LintPipeline {
    /// The instance of the rule at `index` , when the rule should visit the node the gate
    /// describes.
    ///
    /// Returns `nil` when the rule is disabled, when a `// sm:ignore` directive masks it, or when
    /// it skips the children of an enclosing node.
    @inline(__always)
    func lintRule<R: InstanceSyntaxRule & AnyObject>(
        _: R.Type,
        _ index: Int,
        gate: Context.Gate
    ) -> R? {
        guard context.shouldFormat(index, gate: gate) else { return nil }
        if skipCount > 0, skipUntil[index] != nil { return nil }
        return rule(R.self, at: index)
    }

    /// Records the result of a lint rule's `visit` . A rule that answers `.skipChildren` skips
    /// every node below `node` .
    @inline(__always)
    func didVisit(_ index: Int, _ node: some SyntaxProtocol, _ kind: SyntaxVisitorContinueKind) {
        guard case .skipChildren = kind else { return }
        if skipUntil[index] == nil { skipCount += 1 }
        skipUntil[index] = node.id
    }

    /// Ends the skip of the rule at `index` when the walk leaves the node that started it.
    @inline(__always)
    func endSkip(_ index: Int, _ node: some SyntaxProtocol) {
        guard let skipNode = skipUntil[index], skipNode == node.id else { return }
        skipUntil[index] = nil
        skipCount -= 1
    }

    /// The instance of the rule at `index` , if the walk created one.
    ///
    /// `visitPost` goes to an existing instance only. Lint rules with stateful visitors rely on
    /// this to balance their `visit` and `visitPost` pairs.
    @inline(__always)
    func existingRule<R: InstanceSyntaxRule & AnyObject>(_: R.Type, _ index: Int) -> R? {
        rules[index].map { unsafe unsafeDowncast($0, to: R.self) }
    }

    /// The instance of the rule at `index` , created on first use.
    ///
    /// The generated code passes the index of `R` , so a slot only ever holds an `R` and the
    /// downcast is unchecked in release builds.
    @inline(__always)
    func rule<R: InstanceSyntaxRule & AnyObject>(_: R.Type, at index: Int) -> R {
        if let cached = rules[index] { return unsafe unsafeDowncast(cached, to: R.self) }
        let rule = R(context: context)
        rules[index] = rule
        return rule
    }

    /// The instance of `type` , created on first use. Looks the index up by type, for callers
    /// outside the generated code.
    func rule<R: InstanceSyntaxRule & AnyObject>(_ type: R.Type) -> R {
        guard let index = ConfigurationRegistry.ruleIndex(of: type) else {
            preconditionFailure("\(type) is not a registered rule")
        }
        return rule(type, at: index)
    }
}

extension LintPipeline {
    /// The rule instances the walk created, keyed by rule type.
    ///
    /// A copy built on each read, for tests and benchmarks. The walk itself reads `rules` .
    var ruleCache: [ObjectIdentifier: any SyntaxRule] {
        var cache: [ObjectIdentifier: any SyntaxRule] = [:]

        for case let object? in rules {
            if let rule = object as? any SyntaxRule { cache[ObjectIdentifier(type(of: rule))] = rule }
        }
        return cache
    }
}
