---
# jpp-2gl
title: Fix JSON schema code issues from review
status: completed
type: task
priority: normal
created_at: 2026-04-23T05:16:59Z
updated_at: 2026-04-23T05:22:58Z
sync:
    github:
        issue_number: "338"
        synced_at: "2026-04-23T05:30:24Z"
---

Fix all issues found in the Swift review of the JSON schema code:

- [x] High: Force-cast crash in `validateEnum` — eliminated entirely by rewriting validator on `JSONValue`
- [x] Medium: Missing `items` array element validation in SchemaValidator
- [x] Low: `try!` in generated schema code — replaced with `JSONDecoder` + proper error handling
- [x] Low: Rename `jsonObject` → `schema` on ConfigurationSchema


## Summary of Changes

Rewrote `SchemaValidator` to operate on `JSONValue` (a proper Swift enum) instead of `[String: Any]` with NSObject/NSNumber/CFBooleanGetTypeID bridging. Eliminated all ObjC-bridged Foundation types from the validation path. Consolidated duplicate `JSONValue` definitions (was in both SchemaValidator and Configuration) into a single `package` type. Updated `ConfigurationSchema+Generated` to decode into `JSONValue` instead of `[String: Any]`. Removed `parseJSON5` helper (no longer needed). Added `items` array element validation.
