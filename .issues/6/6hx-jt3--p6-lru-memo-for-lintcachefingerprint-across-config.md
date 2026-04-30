---
# 6hx-jt3
title: 'P6: LRU memo for LintCache.fingerprint across configs'
status: ready
type: task
priority: normal
created_at: 2026-04-30T15:57:41Z
updated_at: 2026-04-30T15:57:41Z
parent: 6xi-be2
sync:
    github:
        issue_number: "549"
        synced_at: "2026-04-30T16:27:55Z"
---

**Location:** `Sources/SwiftiomaticKit/Support/LintCache.swift:143`

`fingerprint(for:)` memoizes a single `(Configuration, fingerprint)` pair via `lastFingerprint`. When a project has multiple `.swift-format` overrides per directory, the memo thrashes — every file that switches configs triggers a full re-encode of the Configuration to sorted-keys JSON plus a SHA-256 hash.

## Potential performance benefit

For monorepos with N distinct configs, replaces N×files re-encodes with N total re-encodes (cache size = N). A configuration encode + sorted-keys JSON serialization + SHA-256 of multi-KB JSON is non-trivial; eliminating thrash matters for projects with several nested overrides.

## Reason deferred

Single-config projects (the common case) already hit the existing memo. Need to measure that monorepo overrides actually thrash in practice before adding LRU complexity. Reasonable approach: key by a cheap config hash (e.g. hash of `Configuration`'s memberwise comparison fields) and keep an LRU of last 4–8 configs.
