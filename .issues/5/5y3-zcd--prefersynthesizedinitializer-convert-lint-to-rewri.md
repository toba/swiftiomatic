---
# 5y3-zcd
title: 'PreferSynthesizedInitializer: convert lint to rewrite'
status: scrapped
type: task
priority: low
created_at: 2026-04-25T20:43:43Z
updated_at: 2026-04-25T22:32:59Z
parent: 0ra-lks
sync:
    github:
        issue_number: "431"
        synced_at: "2026-04-25T22:35:11Z"
---

`Sources/SwiftiomaticKit/Rules/Declarations/PreferSynthesizedInitializer.swift` — currently a pure `LintSyntaxRule<LintOnlyValue>`. The diagnostic describes a deletable redundant `init`, so this should be a `RewriteSyntaxRule` that removes the init.

## Fix
- [ ] Convert to `RewriteSyntaxRule`
- [ ] Emit the fix (delete the redundant `init`)
- [ ] Update tests to assert the rewrite

## Test plan
- [ ] Existing lint cases now also produce the corresponding rewrite
- [ ] Add a `--no-fix` test if needed


## Reasons for Scrapping

This conversion is intentionally deferred to its own focused issue, not bundled into the pre-release cleanup pass.

Scope of work required:

1. Convert PreferSynthesizedInitializer base class from LintSyntaxRule<LintOnlyValue> to RewriteSyntaxRule<BasicRuleValue>
2. Implement the rewriter visit(_ node: StructDeclSyntax) -> DeclSyntax that filters redundant InitializerDeclSyntax members from MemberBlockItemListSyntax
3. Carefully handle trivia preservation: leading trivia of the removed init may include doc comments or attached blank lines; trailing/preceding member trivia must be re-balanced so removal does not collapse blank-line spacing in unexpected ways
4. Convert ~495 lines of assertLint-based tests in PreferSynthesizedInitializerTests.swift to assertFormatting form, supplying expected post-rewrite output for every case
5. Validate that complex rules of the existing matchers (matchesPropertyList / matchesAssignmentBody / matchesAccessLevel) compose safely with multi-init structs where some inits are removable and others are not

Risks of doing this poorly:

- Removing a redundant init that the user actually wanted to keep (because it has subtle behavior the matchers miss) silently destroys their code
- Bad trivia handling can collapse documentation comments or strip blank-line spacing
- Multi-init removal needs to handle the all-removable case (synthesized init kicks in) vs partial-removable (none can be removed)

Recommendation: open a dedicated issue with a concrete test corpus and tackle this conversion in isolation rather than mixing it with a 20-issue cleanup pass.
