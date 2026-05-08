---
# ywq-mgm
title: '`requireAsyncStreamFinish` flags `AsyncStream(unfolding:)` which has no `finish()` API'
status: completed
type: bug
priority: high
created_at: 2026-05-08T19:10:06Z
updated_at: 2026-05-08T19:16:58Z
sync:
    github:
        issue_number: "668"
        synced_at: "2026-05-08T19:20:44Z"
---

\`requireAsyncStreamFinish\` warns about \`AsyncStream\` initializers that yield without calling \`finish()\` or providing \`onTermination\`. It also fires on \`AsyncStream(unfolding:)\`, but that initializer is **pull-based**: there is no continuation, no \`finish()\` to call, and the stream ends naturally when the unfolding closure returns \`nil\`.

## Repro

\`\`\`swift
return AsyncStream(unfolding: {
    return isDone ? nil : value  // returning nil terminates the stream
})
\`\`\`

\`sm lint\`:

\`\`\`
DependencyEscapingTests.swift:221:17: warning: [requireAsyncStreamFinish] 'AsyncStream' yields without 'finish()' or 'onTermination' — consumer cancellation will leak the producer
\`\`\`

The warning's message and remediation suggestion don't apply to this initializer.

## Expected

The rule should:
- Skip \`AsyncStream(unfolding:)\` and \`AsyncStream(unfolding:onCancel:)\` (and the \`AsyncThrowingStream\` equivalents) — there is no continuation to call \`finish()\` on.
- Apply only to the \`AsyncStream { continuation in … }\` and \`AsyncStream.makeStream()\` shapes where \`continuation.finish()\` / \`onTermination\` is meaningful.



## Summary of Changes

- `RequireAsyncStreamFinish` now skips `AsyncStream` / `AsyncThrowingStream` calls whose first argument label is `unfolding:` — these pull-based initializers have no continuation and terminate by returning `nil`, so the diagnostic does not apply.
- Added two tests covering `AsyncStream(unfolding:)` and `AsyncThrowingStream(unfolding:onCancel:)`.

### Files

- `Sources/SwiftiomaticKit/Rules/Unsafety/RequireAsyncStreamFinish.swift`
- `Tests/SwiftiomaticTests/Rules/RequireAsyncStreamFinishTests.swift`
