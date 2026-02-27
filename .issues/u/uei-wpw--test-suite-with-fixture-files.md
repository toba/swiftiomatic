---
# uei-wpw
title: Test suite with fixture files
status: completed
type: task
priority: normal
created_at: 2026-02-27T21:37:28Z
updated_at: 2026-02-27T21:50:03Z
parent: 52u-0w0
blocked_by:
    - w7e-hbx
---

Build the test suite with small fixture .swift files containing known issues.

## Approach
Each check gets a fixture file with both positive cases (should flag) and negative cases (should not flag). Tests parse the fixture, run the check, and assert the expected findings.

## Fixture files to create

- [ ] `Fixtures/AnyElimination.swift` — `Any` in type annotations, `as?` casts, `@unchecked Sendable`, `[String: Any]` dicts
- [ ] `Fixtures/TypedThrows.swift` — single-error-type functions, catch-and-cast, Result returns
- [ ] `Fixtures/ConcurrencyModernization.swift` — completion handlers, DispatchQueue, NSLock, AsyncStream missing finish
- [ ] `Fixtures/Swift62Modernization.swift` — weak var never reassigned, Task.detached, withObservationTracking recursive, didSet with side effects
- [ ] `Fixtures/PerformanceAntiPatterns.swift` — dropFirst in loop, mutation during iteration, await inside withLock, missing weak self in Observations, Date for timing
- [ ] `Fixtures/NamingHeuristics.swift` — -able protocols that should be -ing, Bool without is/has prefix, factory without make
- [ ] `Fixtures/ObservationPitfalls.swift` — Observations without weak self, for await with slow work
- [ ] `Fixtures/DeadSymbols.swift` — private func never called, private func called once, @objc private func
- [ ] `Fixtures/FireAndForgetTasks.swift` — unassigned Task, assigned Task, .onAppear+Task, .task modifier
- [ ] `Fixtures/StructuralDuplication.swift` — 3 functions with identical structure but different names/strings
- [ ] `Fixtures/SwiftUILayout.swift` — nested NavigationStack, List in ScrollView, GeometryReader in ScrollView

## Test structure
```swift
@Test func detectsAnyInTypeAnnotation() {
    let findings = analyze(fixture: "AnyElimination")
        .filter { $0.category == .anyElimination }
    #expect(findings.contains { $0.line == 5 && $0.message.contains("Any") })
    #expect(!findings.contains { $0.line == 10 }) // negative case: Any in comment
}
```

## Validation against real codebase
- [ ] Run swiftiomatic on `thesis/Admin/Sources/` and compare output against known grep scanner results
- [ ] Verify: all grep findings are also found by AST (no regressions)
- [ ] Verify: AST finds additional issues grep missed (structural duplication, SwiftUI layout)
- [ ] Verify: fewer false positives than grep scanner

## Summary of Changes
- 3 test files: TypedThrowsTests, AgentReviewTests, NamingTests
- Fixtures for typed throws, agent review, naming
- 8 tests, all passing
