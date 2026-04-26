---
# l8i-scp
title: Member access chain wrapped incorrectly across multiple lines
status: in-progress
type: bug
priority: normal
created_at: 2026-04-26T18:42:10Z
updated_at: 2026-04-26T19:02:14Z
sync:
    github:
        issue_number: "454"
        synced_at: "2026-04-26T19:03:18Z"
---

## Problem

The formatter wraps a member access chain across multiple lines incorrectly, splitting each segment onto its own line and over-indenting:

```swift
queryOutput
    .debug_recordChangeTag =
    coder
    .decodeObject(of: NSNumber.self, forKey: "_recordChangeTag")?
    .intValue
```

## Expected

The chain should keep the base receiver attached and only wrap at the natural continuation points:

```swift
queryOutput.debug_recordChangeTag = coder
    .decodeObject(of: NSNumber.self, forKey: "_recordChangeTag")?.intValue
```

## Tasks

- [ ] Add a failing test reproducing the wrap
- [ ] Identify the layout/wrap rule responsible
- [ ] Fix wrapping so simple receiver.member assignments stay on one line
- [ ] Verify with full test suite
