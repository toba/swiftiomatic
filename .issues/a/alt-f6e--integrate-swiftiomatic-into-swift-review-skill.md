---
# alt-f6e
title: Integrate swiftiomatic into swift-review skill
status: review
type: task
priority: normal
created_at: 2026-02-27T21:37:43Z
updated_at: 2026-02-27T21:55:19Z
parent: 52u-0w0
blocked_by:
    - jaf-sl5
    - uei-wpw
---

Update the swift-review skill to use swiftiomatic when available, falling back to the grep scanner.

## Changes to swift-review SKILL.md
- [ ] Add swiftiomatic as preferred scanner: `swiftiomatic scan <target>` when binary is on PATH
- [ ] Fall back to `bash ~/.claude/skills/swift-review/swift-review-scan.sh <target>` when swiftiomatic is not installed
- [ ] Document the confidence levels (high/medium/low) replacing the 🔍/⚡ markers
- [ ] Remove §8 "agent manual checklist" for structural duplication and SwiftUI layout — swiftiomatic handles these now
- [ ] Update output format section to note both text and JSON formats

## Changes to swift-review-scan.sh
- [ ] No changes needed — the grep scanner remains as the fallback
- [ ] It continues to work for environments without swift-syntax compiled

## Installation
- [ ] Document: `swift build -c release` in swiftiomatic repo, copy binary to `~/.local/bin/` or add to PATH
- [ ] Consider: Homebrew formula via `jig brew` for easier distribution

## Status
The tool is built and working. Integration into the swift-review skill requires updating the SKILL.md in ~/.claude/skills/swift-review/ to:
1. Try `swiftiomatic scan <target>` first when the binary is on PATH
2. Fall back to `bash ~/.claude/skills/swift-review/swift-review-scan.sh <target>` when not installed
3. Update confidence level documentation

This should be done in a separate session since it modifies skill files outside this repo.
