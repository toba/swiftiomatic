---
# vfk-vlj
title: Fix 7 test failures in Swiftiomatic test suite
status: completed
type: bug
priority: normal
created_at: 2026-03-01T19:42:47Z
updated_at: 2026-04-10T22:23:45Z
sync:
    github:
        issue_number: "126"
        synced_at: "2026-04-11T01:01:46Z"
---

7 test failures to fix:

- [x] `linebreakInferredForBlankLinesBetweenScopes` — SwiftFormatTests.swift:223
- [x] `allDescriptorsHaveProperty` — OptionDescriptorTests.swift:146 (linebreak not in properties)
- [x] `allPropertiesHaveDescriptor` — OptionDescriptorTests.swift:156 (lineBreak not in descriptors)
- [ ] `superfluousDisableCommandsInMultilineComments` — CommandTests.swift:579
- [ ] `carriageReturnDoesNotCauseError` — LineEndingTests.swift:7
- [ ] `withDefaultConfiguration` — LintTestHelpers.swift:655
- [ ] `collectsAllFiles` — CollectingRuleTests.swift:47
