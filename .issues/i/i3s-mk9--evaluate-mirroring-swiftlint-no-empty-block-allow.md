---
# i3s-mk9
title: Evaluate mirroring SwiftLint no_empty_block 'allow_compact_empty_blocks' option
status: ready
type: task
priority: normal
created_at: 2026-07-29T03:10:21Z
updated_at: 2026-07-29T03:10:21Z
sync:
    github:
        issue_number: "756"
        synced_at: "2026-07-30T03:27:16Z"
---

SwiftLint added an `allow_compact_empty_blocks` config option to its `no_empty_block` rule (realm/SwiftLint fc5f99e60c52, 2026-07-27). When true, the rule ignores compact empty blocks where the braces have no whitespace/trivia between them (e.g. `func f() {}`, `willSet {}`) while still flagging spaced ones (`{ }`, multi-line `{\n}`).

Implementation (upstream): a bool `allowCompactEmptyBlocks` (default false) on NoEmptyBlockConfiguration; the visitor early-returns when `node.leftBrace.trailingTrivia.isEmpty && node.rightBrace.leadingTrivia.isEmpty`.

Context for us: Swiftiomatic currently has NO empty-block lint rule (grep for empty-block/EmptyBody found no equivalent under Sources/Swiftiomatic*/Rules). So this is not a one-line option-add — it is really two questions:
 1. Do we want a NoEmptyBlock-style lint rule at all? (upstream swift-format does not have one either.)
 2. If yes, port the rule and include `allowCompactEmptyBlocks` for parity.

Source: cite review 2026-07-28 (realm/SwiftLint main). Diff captured in that review.

## Todo
- [ ] Decide whether an empty-block lint rule fits Swiftiomatic's rule set
- [ ] If yes: port NoEmptyBlockRule (per-block-type config: function/initializer/statement/closure bodies)
- [ ] Include the `allowCompactEmptyBlocks` option (default false) with the trivia-based compact check
- [ ] Add tests (compact allowed vs spaced/multi-line triggering)
