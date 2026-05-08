---
# rs5-13i
title: '`useFinalClasses` fires on `import` statements'
status: completed
type: bug
priority: high
created_at: 2026-05-08T18:53:05Z
updated_at: 2026-05-08T19:15:38Z
sync:
    github:
        issue_number: "664"
        synced_at: "2026-05-08T19:20:43Z"
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
