---
# dfh-7ta
title: 'Suggest rule: Foundation modernization (AttributedString, typed notifications)'
status: completed
type: task
priority: normal
created_at: 2026-04-12T02:27:03Z
updated_at: 2026-04-12T02:37:46Z
parent: ogh-b3l
sync:
    github:
        issue_number: "215"
        synced_at: "2026-04-12T03:13:34Z"
---

## Overview

Create a suggest-scope rule detecting Foundation types superseded by modern Swift alternatives.

## Patterns to detect

- [ ] `NSAttributedString` / `NSMutableAttributedString` → `AttributedString` (value type, Sendable)
- [ ] `NSParagraphStyle` / `NSMutableParagraphStyle` → `AttributedString` paragraph attributes
- [ ] `Notification.Name` definitions → `NotificationCenter.Message` structs (SE-0011 typed notifications)
- [ ] `post(name:object:userInfo:)` with userInfo dictionaries → typed `MainActorMessage`/`AsyncMessage`
- [ ] `Result<T, E>` return types where the caller immediately switches/maps → typed throws

## Notes

- Exception for NSAttributedString: TextKit 2 layout pipeline internals may still need NS types
- All suggest scope — migration involves structural changes
- Single rule file: `FoundationModernizationRule.swift` in `Rules/Frameworks/Foundation/`
