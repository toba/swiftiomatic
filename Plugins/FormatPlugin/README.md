# Format Source Code (FormatPlugin)

SPM command plugin that integrates `sm format` into Swift Package Manager and Xcode.

## What It Does

Implements `CommandPlugin` and `XcodeCommandPlugin` with a `.sourceCodeFormatting()` intent. When invoked, it locates the `sm` binary and runs `sm format --recursive --parallel --in-place` on the selected targets.

## Usage

- **SPM:** `swift package format-source-code`
- **Xcode:** Right-click a target in the project navigator and select "Format Source Code"

## Where It Fits

One of two SPM plugins (alongside `LintPlugin`) that let users run Swiftiomatic from Xcode's UI or SPM commands without invoking the CLI directly. Requires write permission to the package directory since it modifies source files in-place.
