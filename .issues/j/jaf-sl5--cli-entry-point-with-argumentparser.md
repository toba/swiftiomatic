---
# jaf-sl5
title: CLI entry point with ArgumentParser
status: completed
type: task
priority: normal
created_at: 2026-02-27T21:32:46Z
updated_at: 2026-02-27T21:49:56Z
parent: 52u-0w0
blocked_by:
    - w7e-hbx
---

Build the CLI interface using swift-argument-parser.

- [ ] `@main struct Swiftiomatic: AsyncParsableCommand` in `Sources/Swiftiomatic/`
- [ ] Subcommands:
  - `scan <path>` — run all checks on a directory or file
  - `check <category> <path>` — run a single category (e.g. `check typed-throws Sources/`)
  - `list-checks` — print available categories and their descriptions
- [ ] Flags:
  - `--format text|json` (default: text) — output format
  - `--category <name>` (repeatable) — limit to specific categories
  - `--exclude <glob>` (repeatable) — additional exclusion patterns
  - `--min-confidence high|medium|low` (default: low) — filter by confidence
  - `--min-severity high|medium|low` (default: low) — filter by severity
  - `--quiet` — summary counts only, no individual findings
- [ ] Text output format matches the existing `swift-review-scan.sh` output:
  - `## N. Category Name` headers
  - `#### Label` subheaders with file:line results
  - `## Summary` with per-category hit counts and total
- [ ] Exit code: 0 if no findings, 1 if findings found (useful for CI)

## Summary of Changes
- Scan subcommand with path args, --format, --category, --exclude, --min-confidence, --min-severity, --quiet flags
- list-checks subcommand
- Exit code 1 when findings found
- Text output matches swift-review scan format
