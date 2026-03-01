---
# a2p-q6o
title: 'Output formatters: text and JSON'
status: completed
type: task
priority: normal
created_at: 2026-02-27T21:37:06Z
updated_at: 2026-02-27T21:49:56Z
parent: 52u-0w0
blocked_by:
    - w7e-hbx
sync:
    github:
        issue_number: "90"
        synced_at: "2026-03-01T01:01:46Z"
---

Implement output formatters for the analysis results.

## TextFormatter (`Output/TextFormatter.swift`)
- [ ] Match the existing `swift-review-scan.sh` output format exactly:
  - `## N. Category Name` section headers
  - `#### Label` subsection headers with findings listed as `file:line:col: message`
  - `⚡ Opportunity:` prefix for medium-confidence modernization suggestions
  - `🔍 Review:` prefix for low-confidence flags
  - `## Summary` with per-category counts and total
- [ ] Group findings by category, then by check within category
- [ ] Sort findings within each group by file path, then line number
- [ ] Support `--quiet` mode: summary counts only

## JSONFormatter (`Output/JSONFormatter.swift`)
- [ ] Output a JSON array of Finding objects (or a wrapper with metadata)
- [ ] Include `version` field for format stability
- [ ] Include `metadata` with: target path, timestamp, swiftiomatic version, swift-syntax version, categories run
- [ ] Each finding as per the contract in the epic description
- [ ] Support `--pretty` for human-readable JSON (default: compact)

## Compatibility
The text format must be a drop-in replacement for the grep scanner output so the swift-review SKILL.md workflow continues to work unchanged. The agent reads the output and verifies findings — it should not need to know whether grep or AST produced the results.

## Summary of Changes
- TextFormatter with § headers, confidence markers, and summary
- JSONFormatter with Codable encoding
