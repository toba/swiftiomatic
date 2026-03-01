---
# 2ee-a41
title: 'Check: Structured concurrency / GCD modernization (§3)'
status: completed
type: task
priority: normal
created_at: 2026-02-27T21:33:39Z
updated_at: 2026-02-27T21:49:56Z
parent: 52u-0w0
blocked_by:
    - w7e-hbx
sync:
    github:
        issue_number: "92"
        synced_at: "2026-03-01T01:01:49Z"
---

SyntaxVisitor that detects callback-based and GCD patterns that can be modernized.

## What grep does today
- Matches `@escaping`, `completionHandler`, `completion:`
- Matches `DispatchQueue`, `DispatchGroup`, `OperationQueue`
- Matches `NSLock`, `os_unfair_lock`, `pthread_mutex`
- Matches `withCheckedContinuation`, `AsyncStream`
- Flags `NotificationCenter`, delegate protocols, `Timer` as opportunities

## What AST enables beyond grep
- [ ] **Detect completion handler signatures** — find `@escaping (Result<T, Error>) -> Void` as the last parameter (structured pattern, not just keyword matching)
- [ ] **Find callback hell** — count nesting depth of closure parameters containing other closures with `@escaping`
- [ ] **Detect serial DispatchQueue used for synchronization** — find `DispatchQueue(label:)` (serial) used with `.sync` for state protection → actor candidate
- [ ] **Verify AsyncStream has `finish()` and `onTermination`** — walk the closure body of `AsyncStream { continuation in ... }` to check both are called
- [ ] **Detect `withCheckedContinuation` wrapping a single async call** — the continuation wrapper is unnecessary if the underlying API is already async
- [ ] **Find `NSLock`/`os_unfair_lock` protecting state** — check if the locked region is short (Mutex candidate) or contains `await` (actor candidate)
- [ ] **Detect delegate protocols suitable for AsyncStream** — find `protocol *Delegate: AnyObject` with callback-style methods and verify single-consumer usage

## AST nodes to visit
- `FunctionParameterSyntax` — check for `@escaping` closure types
- `FunctionCallExprSyntax` — detect `DispatchQueue.async`, `.sync`, `DispatchGroup`, `NotificationCenter.addObserver`
- `ClosureExprSyntax` — measure nesting depth
- `ProtocolDeclSyntax` — find delegate patterns with `AnyObject` inheritance

## Confidence levels
- Completion handler as last param → high
- `DispatchQueue.sync` for state protection → high (actor or Mutex candidate)
- `NSLock` → high (Mutex candidate)  
- `NotificationCenter.addObserver` → medium (verify async context)
- Delegate → AsyncStream → medium (verify single consumer)
- `withCheckedContinuation` → medium (may bridge Obj-C API)

## Summary of Changes
- ConcurrencyModernizationCheck detects completion handlers, DispatchQueue.async, DispatchGroup, NSLock, @unchecked Sendable
