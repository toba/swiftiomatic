---
# 7oe-34h
title: Incorporate SwiftFormat
status: completed
type: task
priority: normal
created_at: 2026-02-27T21:46:04Z
updated_at: 2026-02-27T22:56:47Z
---

Add https://github.com/nicklockwood/SwiftFormat/tree/main as a /cite source and incporate its capabilities. Update license file and readme to give credit per /readme skill.

Configuration will be moved within a `format` section of the main .swiftiomatic.yaml file.



## Summary of Changes

Superseded by jjv-3ri. SwiftFormat engine (138 rules, v0.59.1) incorporated into Sources/Formatting/ target. format subcommand added with --check, --config, --enable, --disable, --list-rules. YAML config via .swiftiomatic.yaml. MIT license at LICENSES/SwiftFormat-MIT.txt. Citation added via jig cite.
