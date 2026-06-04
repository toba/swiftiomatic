---
# m3d-w0t
title: 'Consider more compile-time literal-validating macros (#HTTPField.Name, #HTTPCookie, #HTTPURLResponse, #AdminAPIKey, #Date)'
status: ready
type: feature
priority: normal
created_at: 2026-06-03T05:22:33Z
updated_at: 2026-06-03T05:22:33Z
sync:
    github:
        issue_number: "720"
        synced_at: "2026-06-04T16:53:16Z"
---

## Proposal

Working through `dyt-le8` (`toba/thesis`), I converted ~12 force-unwrap sites to use existing `#URL("…")` / `#UUID("…")` literal-validating macros from LiteralMacros. The macro pattern (compile-time-validated, no `try`, no runtime `!`) erased a whole class of `noForceUnwrap` warnings without any test/code-shape change — much nicer than `try #require(...)` at use sites and infinitely nicer than `// sm:ignore` directives on stored properties that can't host a throwing init.

The same shape recurs across the codebase for several other "validates a fixed string literal at init" types where I had to fall back to `// sm:ignore` because there's no macro yet. Worth considering a macro for each:

### Candidates

1. **`#HTTPField.Name("Last-Modified-Version")`** — `HTTPField.Name(String)` is failable on invalid HTTP tokens; literally every call site in tests + `OAuth1/Client.swift:242` is a well-known header name. Currently force-unwrapped under `sm:ignore`. Macro could validate the RFC 7230 token grammar at compile time.

2. **`#HTTPCookie(name:value:domain:path:)`** — `HTTPCookie(properties:)` returns optional because property dict can be malformed. Test fixtures hard-code the canonical `[.name, .value, .domain, .path]` shape — guaranteed to validate. Currently `sm:ignore`. Macro could take strongly-typed args and emit the dict-construction + force-unwrap behind the scenes.

3. **`#HTTPURLResponse(url:status:httpVersion:headers:)`** — `HTTPURLResponse(url:statusCode:httpVersion:headerFields:)` is failable on bad URL/status. Stub URL protocol fixtures always pass a known-good URL + 1xx-5xx int. Macro could constant-fold the status code range check.

4. **`#AdminAPIKey("kid:hex")`** — Ghost integration. `AdminAPIKey(rawValue: String)` is failable on bad `kid:hexsecret` format. Tests use `"kid:0011"` literally — validatable at compile time with a regex on the literal.

5. **`#Date(year: 2024, month: 1, day: 15)`** or `#DateComponents(...).date(in: .gregorian)` — `Calendar.date(from: DateComponents)` is optional. `GoalPaceTests.day(_:_:_:)` extracts a private helper specifically to absorb the force-unwrap. Macro could validate the Y/M/D triple at compile time and emit a `Date` directly.

### Common shape

Every one is: **failable init from a string/dict/component literal**, where the literal is fixed in source and a human can verify it's valid by reading. The runtime `!` adds noise without adding safety. Existing `#URL` and `#UUID` prove the approach.

### Suggested priorities

- High value, broadly applicable: `#HTTPField.Name` (also useful in production code, not just tests).
- Medium: `#HTTPURLResponse`, `#HTTPCookie` (test-fixture-heavy).
- Lower (project-specific): `#AdminAPIKey`, `#Date(y:m:d:)`.

Filing in `swiftiomatic` because the macros would live alongside `#URL` / `#UUID` in LiteralMacros (or wherever those are exported from). Cross-reference: toba/thesis `dyt-le8`.
