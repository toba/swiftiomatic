import Foundation
import SwiftSyntax

/// A Rule is a linting or formatting pass — type-level identity only.
///
/// Every rule conforms to `SyntaxRule` (directly or via a base class). Most compact-pipeline rules
/// conform via `StaticFormatRule` and never instantiate; rules whose findings are emitted from
/// instance traversal (lint rules and the structural-pass rewriters) conform via
/// `InstanceSyntaxRule` so the `LintPipeline` cache can construct them.
protocol SyntaxRule: Configurable, Sendable where Value: SyntaxRuleValue {
    /// How strong the advice of the rule is. Separate from the configured severity.
    static var guidance: GuidanceLevel { get }
}

/// A rule that owns a `Context` -bound instance — used by `LintSyntaxRule` and
/// `StructuralFormatRule` . Static-only rules conform to bare `SyntaxRule` instead.
protocol InstanceSyntaxRule: SyntaxRule {
    /// The context in which the rule is executed.
    var context: Context { get }

    /// The rule's dense index, or `nil` for a type the registry does not list. The base class
    /// reads it once per instance, so a finding does not look it up.
    var ruleIndex: Int? { get }

    /// Creates a new Rule in a given context.
    init(context: Context)
}

extension SyntaxRule {
    /// The rule's group sets the default guidance level.
    static var guidance: GuidanceLevel { group?.defaultGuidance ?? .should }

    /// Default value from the `SyntaxRuleValue` 's `init()` .
    static var defaultValue: Value { .init() }

    /// Whether this rule's `defaultValue` is active (rewrite or lint enabled). Reachable via
    /// existential dispatch from `any SyntaxRule.Type` , which preserves dynamic type binding when
    /// `StructuralFormatRule.visitAny` calls into `Context` for per-node gating. Generic dispatch
    /// via `<R: SyntaxRule>` does NOT preserve the dynamic type when the generic parameter is
    /// inferred from `type(of: self)` inside a non-final base class — see
    /// `Context.shouldFormat(ruleType:node:)` .
    static var defaultIsActive: Bool { Self.defaultValue.isActive }

    /// Whether this rule's `defaultValue` rewrites by default. Used by `Context` to build the
    /// `rewriteEnabledRules` set, which gates rewrite paths independently of lint emission.
    static var defaultRewriteActive: Bool { Self.defaultValue.isRewriteActive }

    /// Static counterpart to `diagnose(_:on:anchor:notes:)` . Used by combined-pipeline
    /// `static func transform(_:context:)` overloads (issue `iv7-r5g` / `ddi-wtv` ) so they don't
    /// need to instantiate the rule per node visit.
    ///
    /// The message and the notes are built only for a finding that survives the severity, mask and
    /// warning-control checks.
    static func diagnose<SyntaxType: SyntaxProtocol>(
        _ message: @autoclosure () -> Finding.Message,
        on node: SyntaxType?,
        context: Context,
        anchor: FindingAnchor = .start,
        notes: @autoclosure () -> [Finding.Note] = []
    ) {
        guard context.findingEmitter.isAttached else { return }
        let index = ConfigurationRegistry.ruleIndex(of: Self.self)
        let severity = index.map(context.severity(ruleAt:)) ?? context.configuration[Self.self].lint
        guard severity.isActive else { return }
        Self.emitFinding(
            message,
            on: node,
            severity: severity,
            anchor: anchor,
            notes: notes,
            ruleIndex: index,
            context: context
        )
    }

    fileprivate static func emitFinding<SyntaxType: SyntaxProtocol>(
        _ message: () -> Finding.Message,
        on node: SyntaxType?,
        severity: Lint,
        anchor: FindingAnchor,
        notes: () -> [Finding.Note],
        ruleIndex: Int?,
        context: Context
    ) {
        // A rule that follows a name into another file of the project reports in the linted file.
        // A node of a tree loaded from another file has no location here.
        if let node, context.isForeign(node) { return }

        let anchorPosition = node.map { anchorPosition(of: $0, anchor: anchor) }

        // Per-finding rule-mask gate: the pipeline gates rule dispatch at the *visited* node's
        // start, but rules that visit an enclosing node (e.g. `ClassDeclSyntax`) and emit on inner
        // members would otherwise bypass `// sm:ignore` directives placed on or above those
        // members. Re-checking here at the finding's anchor lets per-member directives suppress
        // findings emitted by class- or file-level rules. The offset needs no converter, so a
        // masked finding computes no location.
        if let anchorPosition {
            let state =
                if let ruleIndex {
                    context.ruleMask.ruleState(ruleIndex, atOffset: anchorPosition.utf8Offset)
                } else {
                    context.ruleMask.ruleState(
                        Self.key,
                        at: context.sourceLocationConverter.location(for: anchorPosition))
                }
            if state == .disabled { return }
        }

        // Honour Swift's `@warn(<group>, as: …)` attribute: if the finding's anchor falls inside a
        // region that names this rule's diagnostic group, that severity overrides the rule's
        // configured severity. Falls back to the passed-in `severity` (the caller's resolved value)
        // when no `@warn` region applies.
        let effectiveSeverity: Lint

        if let node,
           let override = context.warningControlSeverity(
               of: Self.self, ruleIndex: ruleIndex, at: node.position)
        {
            effectiveSeverity = override
        } else {
            effectiveSeverity = severity
        }
        guard effectiveSeverity.isActive else { return }

        let location = anchorPosition.map {
            Finding.Location(context.sourceLocationConverter.location(for: $0))
        }
        context.findingEmitter.emit(
            message(),
            category: SyntaxFindingCategory(ruleType: Self.self),
            severity: effectiveSeverity,
            location: location,
            notes: notes()
        )
    }

    /// The position a finding on `node` points at, the same position `startLocation(converter:)`
    /// and its trivia variants convert.
    private static func anchorPosition(
        of node: some SyntaxProtocol,
        anchor: FindingAnchor
    ) -> AbsolutePosition {
        switch anchor {
            case .start: node.positionAfterSkippingLeadingTrivia
            case let .leadingTrivia(index): node.position(ofLeadingTriviaAt: index)
            case let .trailingTrivia(index): node.position(ofTrailingTriviaAt: index)
        }
    }
}

extension InstanceSyntaxRule {
    /// This rule's configuration value, sugar for `context.configuration[Self.self]` .
    var ruleConfig: Value { context.configuration[Self.self] }

    /// Emits the given finding.
    ///
    /// - Parameters:
    ///   - message: The finding message to emit.
    ///   - node: The syntax node to which the finding should be attached. The finding's location
    ///     will be set to the start of the node (excluding leading trivia, unless
    ///     `leadingTriviaIndex` is provided).
    ///   - anchor: The part of the node where the finding should be anchored. Defaults to the start
    ///     of the node's content (after any leading trivia).
    ///   - notes: An array of notes that provide additional detail about the finding.
    func diagnose<SyntaxType: SyntaxProtocol>(
        _ message: @autoclosure () -> Finding.Message,
        on node: SyntaxType?,
        anchor: FindingAnchor = .start,
        notes: @autoclosure () -> [Finding.Note] = []
    ) {
        guard context.findingEmitter.isAttached else { return }
        let severity = configuredSeverity
        guard severity.isActive else { return }
        Self.emitFinding(
            message,
            on: node,
            severity: severity,
            anchor: anchor,
            notes: notes,
            ruleIndex: ruleIndex,
            context: context
        )
    }

    /// The rule's configured severity, read by index when the registry lists the rule.
    private var configuredSeverity: Lint {
        ruleIndex.map(context.severity(ruleAt:)) ?? context.severity(of: type(of: self))
    }

    /// Emits a finding at an explicit severity, overriding the rule's configured `lint` value. The
    /// rule's master setting still gates emission — if the rule is disabled ( `lint == .no` ),
    /// nothing is emitted regardless of the override.
    ///
    /// Used by metrics rules that emit at `.warn` over a warning threshold and `.error` over an
    /// error threshold within a single configured rule.
    func diagnose<SyntaxType: SyntaxProtocol>(
        _ message: @autoclosure () -> Finding.Message,
        on node: SyntaxType?,
        severity: Lint,
        anchor: FindingAnchor = .start,
        notes: @autoclosure () -> [Finding.Note] = []
    ) {
        guard context.findingEmitter.isAttached else { return }
        guard configuredSeverity.isActive, severity.isActive else { return }
        Self.emitFinding(
            message,
            on: node,
            severity: severity,
            anchor: anchor,
            notes: notes,
            ruleIndex: ruleIndex,
            context: context
        )
    }
}
