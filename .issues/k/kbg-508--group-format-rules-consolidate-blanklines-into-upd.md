---
# kbg-508
title: 'Group format rules: consolidate BlankLines* into UpdateBlankLines, move Redundant/Wrap/Sort/Hoist into subdirectories'
status: in-progress
type: feature
created_at: 2026-04-17T23:17:55Z
updated_at: 2026-04-17T23:17:55Z
---

## Tasks

- [ ] Consolidate 7 BlankLines* rules into single UpdateBlankLines rule with per-location config
- [ ] Add UpdateBlankLinesConfiguration to Configuration.swift
- [ ] Wire config into ruleConfigDecoders, ruleConfigEncodable, schema generator
- [ ] Create UpdateBlankLinesTests consolidating 7 test files
- [ ] Move Redundant* (23), Wrap* (6), Sort* (4), Hoist* (2) into subdirectories
- [ ] Mirror test subdirectories
- [ ] Regenerate pipelines, update swiftiomatic.json
- [ ] Build and test
