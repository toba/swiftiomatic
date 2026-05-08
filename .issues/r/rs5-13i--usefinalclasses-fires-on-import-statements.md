---
# rs5-13i
title: '`useFinalClasses` fires on `import` statements'
status: completed
type: bug
priority: high
created_at: 2026-05-08T18:53:05Z
updated_at: 2026-05-08T20:11:50Z
sync:
    github:
        issue_number: "664"
        synced_at: "2026-05-08T20:13:58Z"
---

\`useFinalClasses\` reports \"prefer 'final class'\" on lines that contain only an \`import\` statement. \`import\` is not a class declaration, so this is a clear false positive.

## Repro

In \`thesis/Core/Tests/CustomDump/DumpTests.swift\` (where line 1 is \`import Testing\` and line 2 is \`import Foundation\`):

\`\`\`
DumpTests.swift:1:11: warning: [useFinalClasses] prefer 'final class' unless designed for subclassing
DumpTests.swift:1:11: warning: [useFinalClasses] prefer 'final class' unless designed for subclassing
DumpTests.swift:1:11: warning: [useFinalClasses] prefer 'final class' unless designed for subclassing
DumpTests.swift:1:11: warning: [useFinalClasses] prefer 'final class' unless designed for subclassing
DumpTests.swift:1:10: warning: [useFinalClasses] prefer 'final class' unless designed for subclassing
DumpTests.swift:1:10: warning: [useFinalClasses] prefer 'final class' unless designed for subclassing
DumpTests.swift:1:11: warning: [useFinalClasses] prefer 'final class' unless designed for subclassing
DumpTests.swift:1:10: warning: [useFinalClasses] prefer 'final class' unless designed for subclassing
\`\`\`

The same line is reported eight times. The actual classes in the file (private nested classes inside the test suite) are presumably what the rule meant to flag, but their **locations are being reported as \`line 1\`** (the import line).

## Likely two bugs

1. The rule's location-reporting pins findings to the wrong line (line 1 instead of the class's actual line).
2. The same class is reported 4–8 times (one per usage / per test method?), where it should be once.

Cosmetically this drowns out other findings and makes \`sm lint | sort | uniq -c\` counts misleading — \`useFinalClasses\` shows 31 in this project but a non-trivial fraction are duplicates of the same source location.



## Summary of Changes

Same `visited.classKeyword` location bug as `7dv-h5s`. The diagnose anchor used the post-rewrite (detached) node, so `startLocation` resolved against wrong offsets, collapsing every finding in the file to `line 1 col 10/11` (inside the first `import`).

The "8 duplicates" weren't duplicates: `DumpTests.swift` has exactly 8 distinct non-final, non-subclassed classes (Surgeon, Child, Parent, User, Object×2, DiffableObject×2). They all reported the same line because of the location bug.

### Fix

`Sources/SwiftiomaticKit/Rules/Access/UseFinalClasses.swift`: bind `original` in `transform(_:original:parent:context:)` and diagnose on `original.classKeyword` instead of `node.classKeyword`.

### Verification

`UseFinalClassesTests`: 30 passed, 0 failed.

Before (all 8 collapsed onto line 1):
```
DumpTests.swift:1:11: warning: [useFinalClasses] ...
DumpTests.swift:1:11: ...  (×8 total at line 1)
```

After:
```
DumpTests.swift:583:9: warning: [useFinalClasses] ...
DumpTests.swift:607:9: ...
DumpTests.swift:612:9: ...
DumpTests.swift:676:9: ...
DumpTests.swift:757:9: ...
DumpTests.swift:785:9: ...
DumpTests.swift:813:9: ...
DumpTests.swift:876:9: ...
```
Each finding now resolves to its actual class declaration.


## Reopened — still firing in sm 3.5.4

The wrong-location and duplication behavior persists in 3.5.4.

### What sm 3.5.4 actually reports

```
$ sm lint Core/Tests/CustomDump/DiffTests.swift
Core/Tests/CustomDump/DiffTests.swift:1:10: warning: [useFinalClasses] prefer 'final class' unless designed for subclassing
Core/Tests/CustomDump/DiffTests.swift:1:10: warning: [useFinalClasses] prefer 'final class' unless designed for subclassing
```

In DumpTests.swift — same single file — the rule emits this 8 times all pointing at line 1.

### What's actually on line 1

```swift
// DiffTests.swift
1: import Testing       ← warnings reported here at col 10
2: import Foundation
```

Line 1 col 10 is the 'g' of 'Testing'. Not a class definition.

### Where the rule is *probably* detecting non-final classes

```swift
// DumpTests.swift
549:        class Human {
555:        class Doctor: Human {
573:        class Human {
579:        class Doctor: Human {
583:        class Surgeon: Doctor {
602:        class Human {
607:        class Child: Human {
612:        class Parent: Human {
672:        class Human {
676:        class User: Human {
```

Multiple non-final nested classes inside @Test method bodies. Detection is correct; location is reported as line 1 (import) instead of these actual lines.

### Repro

Minimal:

```swift
// repro.swift
import Foundation

struct Suite {
    func use() {
        class Bag {}     // ← non-final, rule should target this
        _ = Bag()
    }
}
```

Expected: warning at `class Bag {}` line.
Actual: warning at line 1 col 10 (`import Foundation`'s 'F'/'o'/etc.), possibly emitted multiple times.

### Suggested fixes

1. Fix location reporting so the warning points at the actual `class …` token.
2. Deduplicate multiple emissions for the same class declaration.
3. Optionally: skip detection for classes nested inside `@Test` / `@Suite` method bodies (they're test fixtures specifically constructed to exercise behavior on subclass-able types like in DumpTests.swift).



## Reopen root cause — argv[0]-dependent cache fingerprint

The previous fix (`original.classKeyword` for the diagnose anchor) was correct but unrelated to the persistent symptom. The reopened report — `:1:10` findings on `import` lines after sm 3.5.4 was installed — was caused by stale entries in the lint cache.

`Sources/SwiftiomaticKit/Support/LintCache.swift:120` mixed the executable's size and mtime into the rule-set fingerprint via `CommandLine.arguments.first`. Invoking `sm` with a bare name (argv[0] = "sm") makes `attributesOfItem(atPath: "sm")` fail when cwd has no `sm` file, so size/mtime drop out of the digest. The fingerprint then stayed stable across rebuilds, and findings cached by the pre-fix binary kept being returned for the new binary.

Reproduction shape: `sm lint …` (bare) returned `:1:10`; `/opt/homebrew/bin/sm lint …` (absolute path) returned correct line numbers. Same MD5, same on-disk binary.

### Fix

Resolve the executable via `Bundle.main.executablePath` (with `CommandLine.arguments.first` as a fallback) so the size/mtime lookup always succeeds and the rebuild-invalidation behaviour works for every invocation form.
