---
# 5ki-90l
title: Get Xcode Source Editor Extension building and working as plugin
status: completed
type: task
priority: high
created_at: 2026-04-11T15:35:38Z
updated_at: 2026-04-11T16:09:25Z
sync:
    github:
        issue_number: "174"
        synced_at: "2026-04-11T16:40:44Z"
---

Get the Swiftiomatic Xcode Source Editor Extension to build with proper signing and load as a plugin in Xcode (Editor > Swiftiomatic menu).

## Context
Previous agent work got the extension code written but the signing/build learnings were never recorded. Starting fresh.

## Tasks
- [x] Audit current Xcode project state (targets, signing, entitlements, build settings)
- [x] Get the Xcode project building cleanly
- [x] Get code signing working for both host app and extension
- [x] Verify extension loads in Xcode (Editor > Swiftiomatic menu appears)
- [x] Record all findings and learnings in this issue

## Findings

### Finding 1: Extension appears in System Settings > Extensions but is GREYED OUT
- SwiftFormat (reference working extension) shows white/enabled
- Swiftiomatic shows grey/disabled — cannot be toggled on
- This means: the extension registers (Info.plist is correct) but macOS won't activate it
- Typical causes: code signing issues, sandbox entitlement problems, or the host app not being in a trusted location


### Finding 1: Extension appears in System Settings > Extensions but is GREYED OUT
- SwiftFormat (reference working extension) shows white/enabled
- Swiftiomatic shows grey/disabled — cannot be toggled on
- This means: the extension registers (Info.plist is correct) but macOS won't activate it

### Finding 2: ROOT CAUSE — XcodeKit.framework has broken code signature
- `codesign --verify --deep --strict` on the .app bundle fails:
  ```
  a sealed resource is missing or invalid
  In subcomponent: .../SwiftiomaticExtension.appex/Contents/Frameworks/XcodeKit.framework
  ```
- Verbose check reveals: Headers and Modules directories are stripped during copy but the framework's code seal still references them
- Missing files: XCSourceTextRange.h, XCSourceEditorCommand.h, XCSourceTextBuffer.h, XcodeKitDefines.h, XcodeKit.h, XCSourceTextPosition.h, module.modulemap, XCSourceEditorExtension.h

### Finding 3: FIX — Add CodeSignOnCopy + RemoveHeadersOnCopy attributes
- The "Embed Frameworks" copy phase for XcodeKit.framework had NO attributes in the PBXBuildFile entry
- xc-mcp add_framework/add_to_copy_files_phase was not setting these attributes (bug filed as xc-mcp 66d-i7n)
- Fix: set `settings = {ATTRIBUTES = (CodeSignOnCopy, RemoveHeadersOnCopy, ); }` on the build file
- This tells Xcode: strip headers (saves space) but RE-SIGN the framework after stripping
- After fix + clean build: `codesign --verify --deep --strict` passes clean
- Workaround used: remove entire "Embed Frameworks" phase, recreate it, re-add XcodeKit with correct attributes

### Finding 4: SwiftFormat reference comparison
- SwiftFormat for Xcode.app also embeds XcodeKit.framework with headers stripped
- But SwiftFormat's copy passes codesign verification — it was properly re-signed after strip
- Structure is identical: Versions/A/{XcodeKit, Resources/, _CodeSignature/} (no Headers/ or Modules/)

### Finding 5: Xcode project structure (for reference)
- Host app: SwiftiomaticApp (bundle ID: app.toba.swiftiomatic)
- Extension: SwiftiomaticExtension (bundle ID: app.toba.swiftiomatic.extension)
- Both targets: DEVELOPMENT_TEAM = D6GX9PC3SR, CODE_SIGN_STYLE = Automatic, CODE_SIGN_IDENTITY = Apple Development
- Both have App Group entitlement: group.com.toba.swiftiomatic
- Both have App Sandbox enabled
- Extension is embedded via "Embed App Extensions" copy phase in the host app
- SPM dependency: local package ".." providing SwiftiomaticLib product

### Pending: Does the extension actually load after the signing fix?
- App launched from DerivedData — awaiting user verification in System Settings and Xcode Editor menu


### Finding 6: CONFIRMED WORKING
- Extension toggle is blue/enabled in System Settings > Extensions > Xcode Source Editor
- Swiftiomatic appears alongside SwiftFormat for Xcode
- Two duplicate entries visible in Login Items list (from old DerivedData builds) — cosmetic only
- The CodeSignOnCopy fix was the sole blocker

### Root Cause Summary
The entire problem was ONE missing attribute in the pbxproj. The "Embed Frameworks" copy phase for XcodeKit.framework needed `CodeSignOnCopy` and `RemoveHeadersOnCopy` attributes. Without `CodeSignOnCopy`, Xcode strips headers from the framework but doesn't re-sign it, breaking the code seal. macOS then refuses to load the extension (greyed out in System Settings).


### Finding 7: Duplicate registration in /Applications poisoned ALL extensions
- Old broken copy at `/Applications/Swiftiomatic.app` had the same bundle ID `app.toba.swiftiomatic.extension`
- This copy had the broken XcodeKit signature (pre-fix)
- Having TWO registrations for the same bundle ID confused Xcode — it disabled ALL source editor extensions (including SwiftFormat!)
- Fix: deleted `/Applications/Swiftiomatic.app`, leaving only the DerivedData build registered
- `pluginkit -mDvvv -p com.apple.dt.Xcode.extension.source-editor` is the command to inspect registered extensions
- **Critical lesson: never have two copies of the same extension bundle ID installed**


### Finding 8: Location in /Applications doesn't help
- Copied fixed build to `/Applications/Swiftiomatic.app` — codesign passes clean
- Launched from /Applications, pluginkit registered it
- Removed DerivedData registration with `pluginkit -r` to avoid duplicates
- Xcode restarted — Swiftiomatic STILL greyed out in Editor menu
- SwiftFormat works fine from /Applications, so location alone isn't the issue

### Finding 9: What has been tried and what helped vs didn't

**HELPED:**
1. Adding `CodeSignOnCopy` + `RemoveHeadersOnCopy` attributes to XcodeKit.framework embed phase — fixed `codesign --verify --deep --strict` failure
2. Deleting old broken `/Applications/Swiftiomatic.app` — restored SwiftFormat (which had been disabled by the conflicting broken registration)
3. `pluginkit -r <path>` — successfully removes stale extension registrations

**DID NOT HELP:**
1. Copying app to `/Applications/` — extension still greyed out in Xcode Editor menu
2. Launching the app — extension appears in System Settings toggle (enabled/blue) but Xcode won't load it
3. Restarting Xcode multiple times — no change

**CURRENT STATE:**
- `codesign --verify --deep --strict /Applications/Swiftiomatic.app` — PASSES (no errors)
- System Settings > Extensions > Xcode Source Editor — Swiftiomatic toggle is ON (blue)
- `pluginkit -mDvvv` — shows Swiftiomatic registered from /Applications
- Xcode Editor menu — Swiftiomatic is GREYED OUT (not clickable)
- SwiftFormat — works fine in same Xcode
- No crash reports from today's builds
- No log messages about Swiftiomatic in system log

**KEY DIFFERENCES vs SwiftFormat (working reference):**
- SwiftFormat parent app: `/Applications/SwiftFormat for Xcode.app`
- Swiftiomatic parent app: `/Applications/Swiftiomatic.app`
- Both show as registered in pluginkit
- Both enabled in System Settings
- Only SwiftFormat loads in Xcode Editor menu

**STILL TO INVESTIGATE:**
- Does the extension binary actually link and load? (check `otool -L` on the appex binary)
- Is there a dylib/framework loading issue at runtime? (the old crash had `no LC_RPATH's found` but that was Release config)
- Does the `import Swiftiomatic` (the SPM library) work inside the appex sandbox?
- Compare the appex binary structure and entitlements with SwiftFormat's appex
- Check if the embedded SwiftiomaticLib frameworks are present and signed
- Try running the extension under `pluginkit -e use` to force-load and see errors


### Finding 10: PRODUCT TYPE WAS THE FINAL BLOCKER
- Changing `com.apple.product-type.app-extension` → `com.apple.product-type.xcode-extension` in pbxproj made the extension appear enabled in Xcode's Editor menu
- This is the most insidious issue: zero errors, zero crashes, zero log output — Xcode just silently ignores extensions with the wrong product type
- xc-mcp `add_target` created it as a generic app-extension; Xcode Source Editor Extensions require the xcode-extension product type
- Filed as xc-mcp issue `1hi-ara`

### Complete Fix Summary (both issues required)

**Issue 1: Broken code signature on embedded XcodeKit.framework**
- Symptom: Extension greyed out in System Settings
- Root cause: "Embed Frameworks" copy phase stripped headers but didn't re-sign
- Fix: Add `CodeSignOnCopy` + `RemoveHeadersOnCopy` attributes to XcodeKit.framework PBXBuildFile
- xc-mcp bug: `66d-i7n`

**Issue 2: Wrong product type for Xcode extension target**
- Symptom: Extension enabled in System Settings but greyed out in Xcode Editor menu
- Root cause: `com.apple.product-type.app-extension` instead of `com.apple.product-type.xcode-extension`
- Fix: Change product type in pbxproj line 244
- xc-mcp bug: `1hi-ara`

### Working Configuration Reference
- Host app: `/Applications/Swiftiomatic.app`, bundle ID `app.toba.swiftiomatic`
- Extension: embedded appex, bundle ID `app.toba.swiftiomatic.extension`
- Product type: `com.apple.product-type.xcode-extension`
- Both targets: Automatic signing, team D6GX9PC3SR, App Sandbox, App Group `group.com.toba.swiftiomatic`
- XcodeKit.framework: embedded in extension with `CodeSignOnCopy` + `RemoveHeadersOnCopy`
- SwiftiomaticLib: statically linked via local SPM package dependency
- Extension binary: ~51MB (includes swift-syntax, all rules)
- Deployment target: macOS 26.0

### Diagnostic Commands Cheat Sheet
- `codesign --verify --deep --strict /path/to/App.app` — verify entire bundle signature chain
- `codesign --verify --strict --verbose=4 /path/to/framework` — find specific missing sealed resources
- `pluginkit -mDvvv -p com.apple.dt.Xcode.extension.source-editor` — list registered Xcode source editor extensions
- `pluginkit -r /path/to/Extension.appex` — remove stale extension registration
- `pluginkit -e use -i <bundle-id>` — force-exercise an extension
- `otool -L /path/to/binary` — check dynamic library dependencies
- `codesign -d --entitlements - /path/to/binary` — dump entitlements
