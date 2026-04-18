# Lint Source Code (LintPlugin)

SPM command plugin that integrates `sm lint` into Swift Package Manager and Xcode.

## What It Does

Implements `CommandPlugin` and `XcodeCommandPlugin` with a custom `lint-source-code` verb. When invoked, it locates the `sm` binary and runs `sm lint` on the selected targets, reporting findings without modifying any files.

## Usage

- **SPM:** `swift package lint-source-code`
- **Xcode:** Right-click a target in the project navigator and select "Lint Source Code"

## Where It Fits

One of two SPM plugins (alongside `FormatPlugin`) that let users run Swiftiomatic from Xcode's UI or SPM commands without invoking the CLI directly. Unlike the format plugin, this is read-only and does not require write permissions.
