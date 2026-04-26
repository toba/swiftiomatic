import SwiftSyntax

// Pass classification — taxonomy used by the multi-pass `RewritePipeline` to decide
// which format rules can share one combined `SyntaxRewriter` walk.
//
// Background: the existing pipeline runs each of ~137 rules as a separate full-tree
// `SyntaxRewriter` walk. The combined cost dominates `sm format` wall-clock. The
// multi-pass design (issue `qm5-qyp`) replaces this with ~10 passes; rules that share
// a pass run interleaved per node. See `.issues/q/qm5-qyp` and `.issues/6/66v-to6`.
//
// This file lands the *markers* only — empty protocols and a small enum. Behavior is
// unchanged. The `Generator` (issue `ain-794`) reads conformances to compute pass
// membership, and a future static analyzer can refuse rule bodies that violate the
// declared contract. Until then, conformance is an honor-system claim that the rule
// author owes the reader; the golden-corpus harness (`m82-uu9`) is the safety net.
//
// Two orthogonal axes plus optional markers:
//
// - **Read locality** — what surface of the tree the rule may inspect.
// - **Write surface** — what surface of a node the rule may mutate.
// - **Markers** — properties the planner can exploit when grouping rules.
//
// Co-walk eligibility: same read-locality bucket + disjoint write surfaces +
// (disjoint visited node kinds OR no ordering hazard).
//
// All markers are empty `protocol`s with no requirements (per the issue). Adding a
// requirement here is a load-bearing change that forces every rule update — only do
// it if every conforming rule must literally implement the same hook.

// MARK: - Read locality

/// A rule that reads only the visited token plus its trivia. No structural context —
/// no parent, no siblings, no enclosing decl.
///
/// Examples: trailing-semicolon strip, identifier/keyword text rewrites that don't
/// depend on what surrounds the token.
///
/// Co-walk eligibility: any pair of `TokenLocalFormatRule`s can share a pass provided
/// their write surfaces are disjoint (see write-surface markers below).
protocol TokenLocalFormatRule {}

/// A rule that reads the visited node and its descendants, plus the rule's
/// `Context.configuration`. Must not read `.parent`, `.previousToken`, or
/// `.nextToken` — siblings and ancestors are unattached during a combined walk.
///
/// Examples: `EmptyCollectionLiteral`, `CollapseSimpleIfElse`, `ExplicitNilCheck` —
/// rules whose decision is fully local to one expression or statement subtree.
protocol NodeLocalFormatRule {}

/// A rule that needs the enclosing declaration's modifiers, attributes, or accessor
/// list, but no information beyond the declaration boundary.
///
/// Examples: `ModifierOrder`, `AccessorOrder`, `RedundantAccessControl` — they reorder
/// or strip pieces of a single decl after looking at the decl's own structure.
///
/// Implementation note: when migrated, these rules should visit at the declaration
/// level (e.g. `visit(_ node: VariableDeclSyntax)`), not at descendant tokens, so
/// that the enclosing-decl context is the visited node itself.
protocol DeclLocalFormatRule {}

/// A rule that needs to inspect siblings within an enclosing statement or member
/// block — but does not reach across the file or up multiple ancestors.
///
/// Examples: `BlankLinesBetweenScopes`, `ConsistentSwitchCaseSpacing` — they reshape
/// trivia between members of the same block based on what's adjacent.
protocol BlockLocalFormatRule {}

/// A rule that may inspect the entire file. The catch-all bucket; runs as a solo pass
/// (one-rule-per-walk, today's behavior).
///
/// Examples: `SortImports`, `ExtensionAccessLevel` — anything that needs a fully
/// attached parent or that reorders siblings across the whole file.
///
/// New rules default here. Migrate to a tighter bucket only when the rule's actual
/// read surface is narrow enough.
protocol FileGlobalFormatRule {}

// MARK: - Write surface

/// The trivia channel a `TriviaOnlyFormatRule` is allowed to mutate.
///
/// Channels carve up the trivia surface so two rules touching different channels can
/// safely share a pass. Two rules touching the *same* channel cannot, unless both are
/// `MonotonicWrite` and agree on direction.
package enum TriviaChannel: Sendable, Hashable {
    /// Blank-line trivia between top-level / member declarations. Used by the
    /// `BlankLines*` rules and `EnsureLineBreakAtEOF`.
    case blankLines

    /// Single-line `//` comments. Used by rules that strip or rewrite line comments.
    case lineComments

    /// Doc comments (`///` and `/** */`). Used by `ConvertRegularCommentToDocC`,
    /// `DocCommentsPrecedeModifiers`, and similar.
    case docComments

    /// `// sm:ignore` directive trivia. Reserved for tooling that rewrites the
    /// directives themselves; user rules should not target this channel.
    case ignoreDirectives
}

/// A rule that writes only the named trivia channel — never the token text, never the
/// node structure, and never any other channel.
///
/// Encoded as a typed marker: the `channel` static property lets the planner check
/// disjointness without parsing rule bodies. Two `TriviaOnlyFormatRule`s with
/// different `channel` values can share a pass; with the same channel, they cannot
/// unless both are also `MonotonicWriteFormatRule` agreeing on direction.
protocol TriviaOnlyFormatRule {
    static var channel: TriviaChannel { get }
}

/// A rule that mutates token text or token kind in place. Does not change the node
/// structure around the token. Compatible with `TriviaOnlyFormatRule` (different
/// surface) and with other `TokenTextFormatRule`s if they target disjoint token kinds.
///
/// Examples: `CapitalizeTypeNames`, identifier renames, the `self` token-strip
/// branch of `RedundantSelf`.
protocol TokenTextFormatRule {}

/// A rule that replaces an expression with another expression in the same syntactic
/// slot. Must not change the surrounding declaration or statement.
///
/// Examples: `PreferShorthandTypeNames`, `EmptyCollectionLiteral`.
protocol ExpressionRewriteFormatRule {}

/// A rule that rewrites pieces of a declaration's signature, body, or accessors.
///
/// Examples: `WrapSingleLineBodies`, `WrapMultilineStatementBraces`.
protocol DeclRewriteFormatRule {}

/// A rule that inserts or removes elements of a specific syntactic collection
/// (e.g. `CodeBlockItemListSyntax`, `ImportDeclSyntax` list at file scope). The
/// `CollectionKind` associated type lets the planner check that two list-reshaping
/// rules don't both edit the same collection in one pass.
///
/// Examples: `EmptyExtensions`, `SortImports`.
protocol ListReshapingFormatRule {
    associatedtype CollectionKind: SyntaxCollection
}

// MARK: - Markers (optional, planner hints)

/// `R(R(x)) == R(x)`. Lets the planner re-run the rule after a sibling rule's edits
/// without worrying about oscillation or cumulative drift.
protocol IdempotentFormatRule {}

/// The rule only ever *adds* to its declared trivia channel, or only ever *removes* —
/// never both. Two monotonic-add rules on the same channel can co-walk; their effects
/// compose by union.
///
/// Direction is part of the conformance: `monotonicDirection` returns `.add` or
/// `.remove`. Two monotonic rules on the same channel can co-walk only if their
/// directions agree.
protocol MonotonicWriteFormatRule {
    static var monotonicChannel: TriviaChannel { get }
    static var monotonicDirection: MonotonicDirection { get }
}

/// Direction of a `MonotonicWriteFormatRule` — only adds, or only removes.
package enum MonotonicDirection: Sendable, Hashable {
    case add
    case remove
}

/// Forces an ordering edge: this rule's pass must run after `Other`'s pass.
///
/// Use sparingly — every conformance is a code-review trigger. The planner falls
/// back to topological sort when this is set.
protocol MustRunAfterFormatRule {
    associatedtype Other
}

/// Refuses to share a pass with `Other`. Use when analysis can't prove a hazard but
/// the author has manual evidence one exists.
protocol MustNotShareWithFormatRule {
    associatedtype Other
}
