---
# rg3-tgc
title: 'Mirror swift-format #1211: move @_spi attributes to members in ExtensionAccessLevel'
status: completed
type: task
priority: normal
created_at: 2026-05-28T13:11:26Z
updated_at: 2026-05-28T13:23:22Z
sync:
    github:
        issue_number: "713"
        synced_at: "2026-05-28T13:43:08Z"
---

Upstream swift-format commit ed4d9917 (PR #1211, fixes #714) updates NoAccessLevelOnExtensionDeclaration so that when an explicit access level is moved off an extension down to its members, any @_spi(...) attributes on the extension are also moved down to each member (prepended alongside the access level).

Rationale: @_spi on an extension only takes effect when the extension also carries an explicit access level. Stripping the access level while leaving @_spi behind is inconsistent with the rule's purpose.

Behavior:
- @_spi attributes are collected from the extension and prepended to each member alongside the access level.
- @objc, @available, and other attributes that genuinely belong on the extension are left untouched.
- When the access level is the redundant 'internal' keyword, members are not modified and @_spi stays on the extension.

Example:

    @_spi(Something) public extension Foo {
      var bar: String { "" }
    }

becomes:

    extension Foo {
      @_spi(Something) public var bar: String { "" }
    }

## Tasks

- [x] Locate Swiftiomatic's ExtensionAccessLevel StructuralFormatRule
- [x] Add failing test reproducing the @_spi stranding bug
- [x] Port the fix from swift-format ed4d9917
- [x] Verify @objc/@available are preserved on the extension
- [x] Verify the internal-keyword case still leaves @_spi on the extension
- [x] Run filtered tests (full suite still pending)

## References

- swift-format commit: https://github.com/swiftlang/swift-format/commit/ed4d9917bd94ebbc092e8006144f159c8b307a8b
- Reference clone: ~/Developer/swiftiomatic-ref/swift-format/Sources/SwiftFormat/Rules/NoAccessLevelOnExtensionDeclaration.swift


## Summary of Changes

Ported swift-format PR #1211 into `Sources/SwiftiomaticKit/Rules/Access/HoistExtensionAccess.swift`:

- Extended the `State.insideExtension` case with `spiAttributes: [AttributeListSyntax.Element]`.
- In `visitOnDeclarations` (onMembers mode), collect `@_spi` attributes from the extension and pass them along in state. After splitting the access modifier, filter `@_spi` out of `result.attributes`, then move the extension's original leading trivia onto whichever token is now first (first remaining attribute, or the `extension` keyword).
- Added a private `prepending(_:to:)` helper that inserts the captured `@_spi` attributes at the front of each rewritten member's attribute list, moving the member's leading trivia onto the first inserted attribute so leading comments / newlines stay attached.
- Added a fileprivate `AttributeListSyntax.Element.isSPIAttribute` extension.

Tests: added 5 new `@Test` methods to `HoistExtensionAccessTests` covering single `@_spi`, multiple `@_spi`, `@objc` left on extension, placement before existing member attributes, and the redundant-`internal` case (where `@_spi` stays on the extension). All 26 tests in the suite pass.
