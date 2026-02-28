---
# 00o-mwe
title: Replace SourceKitten with direct sourcekitd XPC
status: completed
type: feature
priority: normal
created_at: 2026-02-28T03:08:16Z
updated_at: 2026-02-28T16:16:09Z
---

## Problem

SourceKitten (jpsim/SourceKitten v0.37.2) pulls in SWXMLHash as a transitive dep and bundles a lot of functionality we don't use (Clang support, code completion, documentation generation, symbol graphs). Our actual usage is narrow — we only need:

- **Request types**: cursorInfo, cursorInfoWithoutSymbolGraph, index, editorOpen, customRequest (expression types, Swift version)
- **Data types**: File, Module, SourceKittenDictionary, ByteCount, ByteRange, StringView, SyntaxKind, SwiftDeclarationKind, UID
- **Key use case**: Semantic type resolution + symbol indexing for lint rules

That's ~7 request types and ~8 data types out of a much larger library.

## Approach

Replace SourceKittenFramework with direct sourcekitd XPC communication:

- [ ] Audit all 154 import sites and ~862 .send() call sites to catalog exact API surface
- [ ] Implement thin sourcekitd XPC client (load dylib, build request dictionaries, parse responses)
- [ ] Implement replacement data types (File, ByteCount, ByteRange, StringView, etc.)
- [ ] Port Module to extract SPM compiler arguments directly
- [ ] Port SourceKittenDictionary response wrapper
- [ ] Port SyntaxKind / SwiftDeclarationKind enums (already partially bridged in SyntaxKind+SwiftLint.swift)
- [ ] Update SourceKittenResolver to use new client
- [ ] Update all lint rules importing SourceKittenFramework
- [ ] Remove SourceKitten + SWXMLHash from Package.swift
- [ ] Verify SWIFTLINT_DISABLE_SOURCEKIT / --disable-sourcekit still works

## Dependencies dropped

- `jpsim/SourceKitten` (0.37.2)
- `drmohundro/SWXMLHash` (7.0.2) — transitive, only needed by SourceKitten

## Remaining dependencies after

- swift-syntax (required, core)
- swift-argument-parser (required, CLI)
- Yams (required, YAML config parsing)

## Prior art

- [SourceKitD.swift in SwiftLint](https://github.com/realm/SwiftLint/blob/main/Source/SwiftLintFramework/Models/SourceKitD.swift) — SwiftLint itself started moving toward direct sourcekitd
- sourcekitd's C API is stable and ships with every Xcode toolchain at `$TOOLCHAIN/usr/lib/sourcekitd.framework`

## Notes

- All imports currently use `@preconcurrency import SourceKittenFramework` due to Sendability
- Direct XPC would let us make the client properly Sendable from the start
- Can be done incrementally: shim the existing API surface first, then slim down

## Summary of Changes

Replaced SourceKitten SPM dependency with a vendored ~24-file subset in Sources/Swiftiomatic/SourceKit/. Created SourceKitC C module target for sourcekitd.h types. Removed all SourceKitten naming throughout the codebase:

- SyntaxKind → SourceKitSyntaxKind (fixes SwiftSyntax collision)
- SourceKittenDictionary → SourceKitDictionary (~60 files)
- SourceKittenResolver → SourceKitResolver
- All methods, properties, comments, queue labels purged

Dependencies reduced to: swift-syntax, swift-argument-parser, yams (SourceKitten and SWXMLHash removed).
