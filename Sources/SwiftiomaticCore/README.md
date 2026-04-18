# SwiftiomaticCore

Foundation types shared across every module in the project.

## What It Does

Defines the configuration schema primitives that all other targets depend on:

- **ConfigGroup** -- categorizes rules into groups (sort, wrap, hoist, forcing, comments, blank lines, line breaks, indentation, redundancies, capitalization) that determine where they appear in config JSON and documentation.
- **ConfigProperty** -- describes typed configuration properties (boolean, integer, etc.) with their defaults and human-readable descriptions.

## Where It Fits

This is the lowest-level target in the dependency graph. Both the main `Swiftiomatic` library and the `Generators` target depend on it for consistent configuration metadata without pulling in swift-syntax or other heavy dependencies.
