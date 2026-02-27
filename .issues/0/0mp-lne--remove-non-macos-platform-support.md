---
# 0mp-lne
title: Remove non-macOS platform support
status: completed
type: task
priority: normal
created_at: 2026-02-27T23:32:40Z
updated_at: 2026-02-27T23:37:29Z
---

Strip iOS/tvOS/watchOS/visionOS/Linux platform conditionals and support from the codebase. Swiftiomatic is a macOS-only CLI tool — simplify by removing any cross-platform abstractions or conditional compilation for other platforms.

## Summary of Changes

Removed all non-macOS platform support from the codebase:

- **Package.swift**: Removed CryptoSwift dependency (Linux/Windows only), removed platform conditions on DyldWarningWorkaround
- **ExecutableInfo.swift**: Removed `#if os(macOS)` guards — always uses Mach-O UUID
- **Glob.swift**: Removed Windows (WinSDK/FindFirstFile), Linux (Glibc/Musl) code paths and conditionals
- **LintOrAnalyzeCommand.swift**: Removed `#if os(macOS)` around Darwin import, removed Linux/Windows branch in memoryUsage()
- **SwiftLintFile+Cache.swift**: Removed NSLock fallback in PlatformLock, always uses os_unfair_lock
- **Signposts.swift**: Removed `#if canImport(os)` guards — always uses os.signpost
- **String+sha256.swift**: Removed `#if canImport(CommonCrypto)` guard
- **Configuration+Cache.swift**: Removed CryptoSwift import and Linux cache path
- **Configuration+Remote.swift**: Removed FoundationNetworking/WinSDK imports and Windows Sleep() call
- **UpdateChecker.swift**: Removed FoundationNetworking import
- **ProgressBar.swift**: Removed NSEC_PER_SEC constant (Linux/Windows only)
- **TemporaryDirectory.swift**: Removed platform conditional, always uses "/private" prefix
- **Formatter.swift**: Removed availability guard for pre-macOS 10.15 (project targets macOS 15+)
- **Example.swift**: Removed testOnLinux/testOnWindows properties and parameters
- **UnusedImportRuleExamples.swift**: Removed testOnLinux/testOnWindows arguments from call sites
