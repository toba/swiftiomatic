---
# 4u3-lsi
title: 'Add opt-in rule: remove redundant SwiftUI Group'
status: ready
type: feature
priority: normal
created_at: 2026-07-06T17:24:30Z
updated_at: 2026-07-06T17:24:30Z
sync:
    github:
        issue_number: "751"
        synced_at: "2026-07-06T17:37:58Z"
---

New opt-in rule to unwrap redundant SwiftUI `Group { }` wrappers, relying on @ViewBuilder implicit multi-view support. Fits project OS-26 SwiftUI direction. Cleanup only, not correctness.

Cases upstream (nicklockwood/SwiftFormat redundantSwiftUIGroup #2543/#2546) handles:
- Group { Text(a); Text(b) } directly inside a body / some View -> unwrap (already a ViewBuilder context)
- Same inside a non-body computed `var content: some View` -> unwrap AND inject @ViewBuilder
- Group { Text(x) }.padding(...) (single child + modifiers) -> unwrap, modifier moves to child
- Must NOT unwrap a Group with modifiers wrapping MULTIPLE children (modifier applies to the group as a whole)

Reference: ~/Developer/swiftiomatic-ref/SwiftFormat commits f977cec, f145467 (rule + tests). We have no Group rule under Sources/SwiftiomaticKit/Rules/Swiftui/.

- [ ] Decide base class (StructuralFormatRule likely — needs settled tree / ViewBuilder context)
- [ ] Implement unwrap + @ViewBuilder injection + multi-child-with-modifier safety guard
- [ ] Tests mirroring upstream cases
- [ ] Default: opt-in (rewrite:false)
