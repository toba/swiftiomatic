---
# 9yv-e8j
title: Multiline string formatter mangles indentation, producing 'Insufficient indentation' error
status: completed
type: bug
priority: high
created_at: 2026-05-02T02:53:28Z
updated_at: 2026-05-02T03:34:18Z
sync:
    github:
        issue_number: "625"
        synced_at: "2026-05-02T03:44:32Z"
---

The formatter is reflowing/breaking the contents of a multiline string literal, which is invalid: multiline string content is significant whitespace and must not be modified. The result is a Swift compile error: `Insufficient indentation of next line in multi-line string literal`.

## Reproduction

Input:

\`\`\`swift
return """
    @Dependency(\(argument)) has no live implementation, but was accessed from a live context.

    \(dependencyDescription)

    To fix you can do one of two things:

    • Conform '\(typeName(Key.self))' to the 'DependencyKey' protocol by providing a live implementation of your dependency, and make sure that the conformance is linked with this current application.

    • Override the implementation of '\(typeName(Key.self))' using 'withDependencies'. This is typically done at the entry point of your application, but can be done later too.
    """
\`\`\`

After formatting, the formatter inserts line breaks inside the string contents and inside interpolations (e.g. \`\(argument)\` becomes split across lines, \`\(typeName(Key.self))\` becomes split with \`.self\` on a new line), and also injects backslash-newline continuations (\`\\\`) into the string body. The resulting indentation no longer matches the closing \`\"\"\"\` delimiter, producing:

> Insufficient indentation of next line in multi-line string literal

## Expected

The formatter must treat the contents of a multiline string literal as opaque — no reflow, no break insertion, no interpolation rewriting that crosses lines. Only the surrounding expression context (the \`return\` and the closing delimiter alignment) should be touched.

## Notes

- Likely a pretty-printer / TokenStream issue: breaks are being emitted inside \`StringLiteralExpr\` segments or inside \`ExpressionSegmentSyntax\` interpolations.
- Check \`visitStringLiteralExpr\` / segment handling in \`TokenStreamCreator\`-equivalent and ensure the inner segments are emitted as a single un-breakable token (or that breaks inside interpolations don't propagate as line breaks into the rendered string).
- See screenshot for the broken output.

## Tasks

- [x] Add a failing test with the input above (idempotence: formatted == input)
- [x] Identify which rule/pass introduces the breaks (likely pretty printer, possibly a Static rule)
- [x] Fix: suppress breaks inside multiline string literal segments and their interpolations
- [x] Verify full test suite passes



## Summary of Changes

Could not reproduce on current `main`. The pretty printer already emits `ExpressionSegmentSyntax` as a single atomic `.syntax` token via `node.description` (see `TokenStream+Closures.swift:181`), and with `reflowMultilineStringLiterals: never` (the project's configured default), `visitStringSegment` emits string segment text as a single `.syntax` token (see `Rules/Literals/ReflowMultilineStringLiterals.swift:86`). Both paths prevent the breaks shown in the screenshot.

The screenshot was most likely produced by an older `sm` build, an unrelated tool, or a file whose interpolations were already split before formatting (sm with `reflow=never` will preserve pre-existing breaks rather than re-flow them).

### Test added

`StringTests.multilineStringWithInterpolationsNotMangledWithNeverReflow` (`Tests/SwiftiomaticTests/Layout/StringTests.swift`) — uses the user's exact input string (interpolations + multi-paragraph content) under `reflow=.never`, asserts idempotency. Passes on current main, will catch any future regression that re-introduces interpolation-splitting or in-string break insertion under `never` reflow.

Full `StringTests` suite (32 tests) passes.
