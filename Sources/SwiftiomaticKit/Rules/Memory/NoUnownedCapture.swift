import SwiftSyntax
import ConfigurationKit

/// An `unowned` capture in a closure capture list is a latent use-after-free: an `unowned`
/// reference does not keep its referent alive and does not degrade to `nil`. If the referent is
/// deallocated before the closure runs, accessing it crashes (`unowned` / `unowned(safe)`) or reads
/// freed memory (`unowned(unsafe)`). Prefer `[weak x]` plus a `guard let`, which recovers cleanly.
///
/// This mirrors SwiftLint's `unowned_variable_capture` rule.
///
/// Swift has three spellings, all reported by default:
/// - `unowned` — sugar for `unowned(safe)`; traps deterministically after deallocation.
/// - `unowned(safe)` — side-table bookkeeping; the same clean trap.
/// - `unowned(unsafe)` — a raw non-retaining pointer with no trap; accessing a dangling referent is
///   undefined behavior. It exists only as a hot-path escape hatch.
///
/// Set `allowExplicitUnsafeUnowned` to `true` to permit `unowned(unsafe)` captures: spelling the
/// `(unsafe)` in full is treated as a deliberate, acknowledged opt-in, so it is not reported. Bare
/// `unowned` and `unowned(safe)` are always reported regardless of the flag.
///
/// Lint: A closure capture-list entry using `unowned` (or `unowned(safe)`, or — unless
/// `allowExplicitUnsafeUnowned` is set — `unowned(unsafe)`) raises a warning.
final class NoUnownedCapture: LintSyntaxRule<NoUnownedCaptureConfiguration>,
    @unchecked Sendable
{
    override class var group: ConfigurationGroup? { .memory }

    override func visit(_ node: ClosureCaptureSpecifierSyntax) -> SyntaxVisitorContinueKind {
        guard node.specifier.tokenKind == .keyword(.unowned) else { return .visitChildren }
        // `node.detail` carries the parenthesized `safe` / `unsafe` refinement, if any.
        let isExplicitUnsafe = node.detail?.tokenKind == .keyword(.unsafe)
        if !isExplicitUnsafe || !ruleConfig.allowExplicitUnsafeUnowned {
            diagnose(.unownedCapture, on: node.specifier)
        }
        return .visitChildren
    }
}

fileprivate extension Finding.Message {
    static let unownedCapture: Finding.Message = """
        avoid `unowned` in a closure capture list; if the referent is deallocated before the \
        closure runs, access crashes (or reads freed memory with `unowned(unsafe)`) — prefer \
        `[weak …]` and guard the optional
        """
}

// MARK: - Configuration

package struct NoUnownedCaptureConfiguration: SyntaxRuleValue {
    /// Lint-only rule; rewriting is never performed.
    package var rewrite = false
    package var lint: Lint = .warn
    /// When `true`, an explicitly-spelled `[unowned(unsafe) x]` capture is treated as a deliberate
    /// opt-in and is not reported. Bare `unowned` and `unowned(safe)` are still reported.
    package var allowExplicitUnsafeUnowned = false

    package init() {}

    package init(from decoder: any Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let v = try c.decodeIfPresent(Lint.self, forKey: .lint) { lint = v }
        if let v = try c.decodeIfPresent(Bool.self, forKey: .allowExplicitUnsafeUnowned) {
            allowExplicitUnsafeUnowned = v
        }
    }

    private enum CodingKeys: String, CodingKey { case lint, allowExplicitUnsafeUnowned }
}
