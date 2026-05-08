---
# 87d-d0b
title: '`sm lint` with no arguments produces no output in project root'
status: ready
type: bug
priority: normal
created_at: 2026-05-08T16:14:43Z
updated_at: 2026-05-08T16:14:43Z
sync:
    github:
        issue_number: "661"
        synced_at: "2026-05-08T16:40:15Z"
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
