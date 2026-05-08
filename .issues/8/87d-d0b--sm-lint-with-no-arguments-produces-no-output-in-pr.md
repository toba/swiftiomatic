---
# 87d-d0b
title: '`sm lint` with no arguments produces no output in project root'
status: completed
type: bug
priority: normal
created_at: 2026-05-08T16:14:43Z
updated_at: 2026-05-08T19:20:04Z
sync:
    github:
        issue_number: "661"
        synced_at: "2026-05-08T19:20:43Z"
---

Running `sm lint` (or `sm format`) with no path arguments in a Swift project root produces no output and exits 0, instead of linting the current directory.

```
$ cd ~/Developer/toba/thesis
$ sm lint
$ echo $?
0
$ sm lint .
… 659 lines of warnings …
```

`sm format` similarly errors:

```
$ sm format .
Error: '--in-place' is required when formatting a directory ('.').
```

Expected: `sm lint` (no args) should default to `sm lint .` and lint the current directory recursively, like `swift-format`, `swiftlint`, etc.

Workaround: pass `.` explicitly, but this is unintuitive.



## Summary of Changes

Already fixed in commit 01dc70e8 ("default sm lint and sm format to recursive directory walks"). When invoked with no path argument and a TTY stdin, `sm` now recurses from the current working directory; explicit directory arguments no longer require `--recursive`. Stdin-piped invocations still read stdin.

`sm format` without `--in-place` errors with a helpful message: "'--in-place' is required when formatting a directory tree." plus remediation hints. `sm format -i` (no args) correctly recurses cwd and rewrites in place.

Verified against a fresh debug build with all four scenarios:
- `sm lint` (no args, TTY) → recurses cwd ✔
- `sm format` (no args, TTY) → helpful `--in-place` error ✔
- `sm format -i` (no args, TTY) → recurses cwd and rewrites ✔
- `sm lint < file.swift` (piped) → reads stdin ✔

Covered by `Tests/SwiftiomaticTests/Utilities/InputResolutionTests.swift`.
