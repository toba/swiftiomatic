---
# lhe-lqu
title: 'NamedDeclVisitor codegen: eliminate 289 boilerplate visit overrides across 53 rules'
status: draft
type: feature
priority: normal
created_at: 2026-04-17T21:56:55Z
updated_at: 2026-04-17T22:11:43Z
sync:
    github:
        issue_number: "322"
        synced_at: "2026-04-17T22:17:15Z"
---

53 rules have fan-out visit() overrides (289 total across 17 declaration types) where each override is 3-6 lines calling the same helper. ~1,135 lines of pure mechanical boilerplate.

## Approach

Extend `generate-swiftiomatic` to emit fan-out dispatchers, consistent with existing codegen architecture (Pipelines+Generated, RuleRegistry+Generated, RuleNameCache+Generated).

### Pattern categories

- **Pattern A** (~60%): Simple dispatch — `visit(FunctionDeclSyntax)` → `processNamedDecl(node)`
- **Pattern B** (~15%): State management — push/pop scope + `super.visit()`
- **Pattern C** (~25%): KeyPath-based — `collapseModifierLines(of: node, keywordKeyPath: \.funcKeyword)`

### Top targets by override count

- ModifiersOnSameLine: 15 overrides
- WrapMultilineStatementBraces: 15 overrides
- NoLeadingUnderscores: 14 overrides
- RedundantSelf: 13 overrides
- RedundantAccessControl: 12 overrides

### Tasks

- [ ] Survey all 53 rules to classify which pattern each uses
- [ ] Design codegen annotation (comment marker or protocol conformance) for rules to declare their dispatch style
- [ ] Extend `generate-swiftiomatic` to scan for annotations and emit visit overrides
- [ ] Update rules to use annotations, remove manual overrides
- [ ] Verify build + tests pass



## Architecture Analysis

The initial estimate of ~1,135 lines was optimistic. Three hard constraints limit practical reduction:

### Constraint 1: No `override` in extensions
Swift prohibits `override` in class extensions. Visit overrides MUST live in the class body, so external codegen can't inject them.

### Constraint 2: Dual pipeline dispatch
Format rules' visit overrides serve TWO pipelines:
- **FormatPipeline**: SyntaxRewriter dispatch (transform nodes)
- **LintPipeline**: `visitIfEnabled(Rule.visit, for: node)` calls the override by method reference for diagnostic side effects

Removing visit overrides breaks LintPipeline dispatch for format rules.

### Constraint 3: RuleCollector detection
The code generator scans for `visit(_: XxxSyntax)` methods to build the LintPipeline dispatch table. Rules without explicit visit methods are excluded.

### Viable approaches

1. **MemberMacro** (`@DeclVisitor`): generates visit overrides at compile time. Clean, type-safe, works with both pipelines. Requires adding macro infrastructure (new targets, compiler plugin). Best long-term solution.

2. **Inline codegen**: `generate-swiftiomatic` modifies source files, injecting visit overrides between markers. Messy but uses existing infrastructure.

3. **Accept the boilerplate**: The overrides are 2-4 lines each, tested, clear. The pain is in writing new rules (10+ overrides per rule).

### Recommendation
Defer to when macro infrastructure is needed for another purpose (amortize setup cost). The boilerplate is annoying but not a correctness or maintainability risk.
