---
# ev6-2i7
title: Agents push broken releases in a loop, each "fix" introducing new failures
status: completed
type: bug
priority: high
created_at: 2026-04-11T23:57:59Z
updated_at: 2026-04-12T01:32:54Z
sync:
    github:
        issue_number: "204"
        synced_at: "2026-04-12T03:13:32Z"
---

Agents repeatedly push tagged releases that fail CI, then claim to have "fixed" the issue by pushing another broken tag. Ten consecutive release failures between v0.18.4 and v0.22.3.

## Actual failure log

| Release | Error | Root cause |
|---------|-------|-----------|
| v0.18.4 | `package is using Swift tools version 6.3.0 but installed version is 6.2.4` | Workflow selected Xcode_26.3 (Swift 6.2.4) instead of Xcode_26.4 (Swift 6.3) |
| v0.19.0 | Same Swift version mismatch | Same — agent didn't fix the workflow YAML |
| v0.20.0 | Same | Same |
| v0.21.1 (1st) | Same | Same |
| v0.21.0 | Same | Same |
| v0.21.1 (2nd) | `error: fatalError` — SourceKit abort | Xcode version fixed, but code has SourceKit guard that calls fatalError in CI |
| v0.22.0 | `'statement_position' is a SyntaxOnlyRule and should not be making requests to SourceKit` — fatalError at Request+SafeSend.swift:29 | Rule incorrectly uses SourceKit; guard kills the process |
| v0.22.1 | `A severity must be provided` — fatalError at SwiftSyntaxRule.swift:79 | Agent's "fix" for SourceKit issue introduced a new bug: rules missing severity |
| v0.22.2 | Same severity error + `emojiIdentifierName()` unexpected violation | Agent's "fix" for severity issue broke identifier name validation |
| v0.22.3 | `enableAllFile()` assertion failure + same severity fatalError | Agent's "fix" for emoji test broke disable/enable-all logic; severity still unfixed |

## The pattern

1. Agent pushes a tag without verifying tests pass locally first
2. CI fails
3. Agent reads the error (or doesn't), makes a narrow fix, pushes another tag
4. The fix either doesn't address the real cause or introduces a new bug
5. Repeat

Five of ten failures were the **same wrong Xcode version** — the agent kept pushing code releases instead of fixing the workflow YAML. Once the YAML was fixed, each subsequent "fix" for a test failure introduced a new test failure.

## Why this keeps happening

- [ ] Agents push tags before running tests locally (CLAUDE.md says to batch and verify, but agents don't follow it)
- [ ] Agents don't read CI error logs carefully — five identical "wrong Swift version" failures in a row proves this
- [ ] Each "fix" is a narrow patch without running the full test suite, so it introduces regressions
- [ ] No gate prevents tagging when the previous release already failed

## Mitigations to consider

- [ ] Add a pre-push hook or nope rule that blocks `git tag` / `git push --tags` unless tests pass locally
- [ ] Add a CLAUDE.md rule: "Never push a release tag. Run tests locally with xc-mcp first. If CI is failing, read the **actual error** from `gh run view --log-failed` before attempting a fix."
- [ ] Consider a `jig release` command that enforces local test + build before tagging

## Environment notes (from investigation)

These are not the cause of the CI failures but worth noting:

- `gh` CLI auth works via `GITHUB_TOKEN` env var only (no `~/.config/gh/hosts.yml` fallback). Fragile but functional.
- `GITHUB_TOKEN` is in `.zshrc` not `.zshenv` — could fail in non-interactive shells, though agent subprocesses currently inherit it fine.
- `jig brew doctor` expects `swiftiomatic-{tag}-arm64.tar.gz` but release.yml creates `sm-{tag}-arm64.tar.gz` — naming mismatch.
- 5 projects have homebrew in release workflows: jig, musup, sqlite-lsp, swiftiomatic, xc-mcp.
