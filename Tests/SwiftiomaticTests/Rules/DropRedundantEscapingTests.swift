import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct DropRedundantEscapingTests: RuleTesting {
    @Test func nonEscapingClosureFlagged() {
        assertFormatting(
            DropRedundantEscaping.self,
            input: """
                func run(_ body: 1️⃣@escaping () -> Void) {
                  body()
                }
                """,
            expected: """
                func run(_ body: () -> Void) {
                  body()
                }
                """,
            findings: [
                FindingSpec(
                    "1️⃣", message: "remove '@escaping' from 'body'; the closure does not escape")
            ]
        )
    }

    @Test func escapingClosureKept() {
        assertFormatting(
            DropRedundantEscaping.self,
            input: """
                var stored: (() -> Void)?
                func store(_ body: @escaping () -> Void) {
                  stored = body
                }
                """,
            expected: """
                var stored: (() -> Void)?
                func store(_ body: @escaping () -> Void) {
                  stored = body
                }
                """,
            findings: []
        )
    }

    @Test func returnedClosureKeepsEscaping() {
        assertFormatting(
            DropRedundantEscaping.self,
            input: """
                func make(_ body: @escaping () -> Void) -> () -> Void {
                  return body
                }
                """,
            expected: """
                func make(_ body: @escaping () -> Void) -> () -> Void {
                  return body
                }
                """,
            findings: []
        )
    }

    @Test func passedToFunctionKeepsEscaping() {
        assertFormatting(
            DropRedundantEscaping.self,
            input: """
                func dispatch(_ body: @escaping () -> Void) {
                  DispatchQueue.main.async(execute: body)
                }
                """,
            expected: """
                func dispatch(_ body: @escaping () -> Void) {
                  DispatchQueue.main.async(execute: body)
                }
                """,
            findings: []
        )
    }

    @Test func usedInNestedClosureKeepsEscaping() {
        assertFormatting(
            DropRedundantEscaping.self,
            input: """
                func wrap(_ body: @escaping () -> Void) {
                  DispatchQueue.main.async {
                    body()
                  }
                }
                """,
            expected: """
                func wrap(_ body: @escaping () -> Void) {
                  DispatchQueue.main.async {
                    body()
                  }
                }
                """,
            findings: []
        )
    }

    @Test func protocolMethodNotFlagged() {
        assertFormatting(
            DropRedundantEscaping.self,
            input: """
                protocol P {
                  func run(_ body: @escaping () -> Void)
                }
                """,
            expected: """
                protocol P {
                  func run(_ body: @escaping () -> Void)
                }
                """,
            findings: []
        )
    }

    // Tuple taint — closure passed inside a tuple to another function escapes.
    @Test func passedInsideTupleKeepsEscaping() {
        assertFormatting(
            DropRedundantEscaping.self,
            input: """
                func outer(closure: @escaping () -> String) {
                  inner(tuple: (closure, 42))
                }
                """,
            expected: """
                func outer(closure: @escaping () -> String) {
                  inner(tuple: (closure, 42))
                }
                """,
            findings: []
        )
    }

    // Tuple taint — destructuring binding from a tuple containing the closure taints the local,
    // which then escapes via assignment to a non-local.
    @Test func tupleDestructuringToNonLocalKeepsEscaping() {
        assertFormatting(
            DropRedundantEscaping.self,
            input: """
                func assignToLocal(completion: @escaping () -> Void) {
                  let (local, _) = (completion, 17)
                  self.local = local
                }
                """,
            expected: """
                func assignToLocal(completion: @escaping () -> Void) {
                  let (local, _) = (completion, 17)
                  self.local = local
                }
                """,
            findings: []
        )
    }

    // Tuple taint — whole-tuple binding then escape of the tuple.
    @Test func wholeTupleAssignedToNonLocalKeepsEscaping() {
        assertFormatting(
            DropRedundantEscaping.self,
            input: """
                func assignToLocal(completion: @escaping () -> Void) {
                  let local = (completion, 17)
                  self.local = local
                }
                """,
            expected: """
                func assignToLocal(completion: @escaping () -> Void) {
                  let local = (completion, 17)
                  self.local = local
                }
                """,
            findings: []
        )
    }

    // Tuple taint — chained: tainted tuple destructured into a local that escapes.
    @Test func chainedTupleDestructuringKeepsEscaping() {
        assertFormatting(
            DropRedundantEscaping.self,
            input: """
                func assignToLocal(completion: @escaping () -> Void) {
                  let local = (completion, 17)
                  let (c, n) = local
                  self.c = c
                }
                """,
            expected: """
                func assignToLocal(completion: @escaping () -> Void) {
                  let local = (completion, 17)
                  let (c, n) = local
                  self.c = c
                }
                """,
            findings: []
        )
    }

    // An async let initializer runs in a child task that outlives the call.
    @Test func asyncLetCaptureKeepsEscaping() {
        assertFormatting(
            DropRedundantEscaping.self,
            input: """
                func onBoth(_ body: @escaping (Int) async throws -> Void) async throws {
                  async let first: Void = body(1)
                  async let second: Void = body(2)
                  _ = try await (first, second)
                }
                """,
            expected: """
                func onBoth(_ body: @escaping (Int) async throws -> Void) async throws {
                  async let first: Void = body(1)
                  async let second: Void = body(2)
                  _ = try await (first, second)
                }
                """,
            findings: []
        )
    }

    @Test func taskCaptureKeepsEscaping() {
        assertFormatting(
            DropRedundantEscaping.self,
            input: """
                func spawn(_ body: @escaping () async -> Void) {
                  Task {
                    await body()
                  }
                }
                """,
            expected: """
                func spawn(_ body: @escaping () async -> Void) {
                  Task {
                    await body()
                  }
                }
                """,
            findings: []
        )
    }

    @Test func taskGroupCaptureKeepsEscaping() {
        assertFormatting(
            DropRedundantEscaping.self,
            input: """
                func fanOut(_ body: @escaping (Int) async -> Void) async {
                  await withTaskGroup(of: Void.self) { group in
                    group.addTask {
                      await body(1)
                    }
                  }
                }
                """,
            expected: """
                func fanOut(_ body: @escaping (Int) async -> Void) async {
                  await withTaskGroup(of: Void.self) { group in
                    group.addTask {
                      await body(1)
                    }
                  }
                }
                """,
            findings: []
        )
    }

    // A local func that captures the parameter can outlive the call, so the capture escapes.
    @Test func nestedFunctionCaptureKeepsEscaping() {
        assertFormatting(
            DropRedundantEscaping.self,
            input: """
                func wrap(_ body: @escaping () -> Void) {
                  func inner() {
                    body()
                  }
                  DispatchQueue.main.async(execute: inner)
                }
                """,
            expected: """
                func wrap(_ body: @escaping () -> Void) {
                  func inner() {
                    body()
                  }
                  DispatchQueue.main.async(execute: inner)
                }
                """,
            findings: []
        )
    }

    // A plain local let is not a child task, so the call still does not escape.
    @Test func plainLetInitializerStillFlagged() {
        assertFormatting(
            DropRedundantEscaping.self,
            input: """
                func run(_ body: 1️⃣@escaping () -> Int) {
                  let value = body()
                  print(value)
                }
                """,
            expected: """
                func run(_ body: () -> Int) {
                  let value = body()
                  print(value)
                }
                """,
            findings: [
                FindingSpec(
                    "1️⃣", message: "remove '@escaping' from 'body'; the closure does not escape")
            ]
        )
    }

    // A witness that drops the attribute no longer satisfies the requirement.
    @Test func sameFileProtocolWitnessKeepsEscaping() {
        assertFormatting(
            DropRedundantEscaping.self,
            input: """
                protocol Scheduler {
                  func schedule(_ action: @escaping @Sendable () -> Void)
                }

                struct InlineScheduler: Scheduler {
                  func schedule(_ action: @escaping @Sendable () -> Void) {
                    action()
                  }
                }
                """,
            expected: """
                protocol Scheduler {
                  func schedule(_ action: @escaping @Sendable () -> Void)
                }

                struct InlineScheduler: Scheduler {
                  func schedule(_ action: @escaping @Sendable () -> Void) {
                    action()
                  }
                }
                """,
            findings: []
        )
    }

    // The requirement lives in another file, so the witness cannot be checked.
    @Test func unknownConformanceKeepsEscaping() {
        assertFormatting(
            DropRedundantEscaping.self,
            input: """
                struct InlineScheduler: Scheduler {
                  func schedule(_ action: @escaping () -> Void) {
                    action()
                  }
                }
                """,
            expected: """
                struct InlineScheduler: Scheduler {
                  func schedule(_ action: @escaping () -> Void) {
                    action()
                  }
                }
                """,
            findings: []
        )
    }

    // An inherited protocol carries the requirement.
    @Test func inheritedRequirementKeepsEscaping() {
        assertFormatting(
            DropRedundantEscaping.self,
            input: """
                protocol Base {
                  func schedule(_ action: @escaping () -> Void)
                }

                protocol Scheduler: Base {}

                struct InlineScheduler: Scheduler {
                  func schedule(_ action: @escaping () -> Void) {
                    action()
                  }
                }
                """,
            expected: """
                protocol Base {
                  func schedule(_ action: @escaping () -> Void)
                }

                protocol Scheduler: Base {}

                struct InlineScheduler: Scheduler {
                  func schedule(_ action: @escaping () -> Void) {
                    action()
                  }
                }
                """,
            findings: []
        )
    }

    // An extension of the same file adds the conformance the witness answers.
    @Test func conformanceFromExtensionKeepsEscaping() {
        assertFormatting(
            DropRedundantEscaping.self,
            input: """
                protocol Scheduler {
                  func schedule(_ action: @escaping () -> Void)
                }

                struct InlineScheduler {
                  func schedule(_ action: @escaping () -> Void) {
                    action()
                  }
                }

                extension InlineScheduler: Scheduler {}
                """,
            expected: """
                protocol Scheduler {
                  func schedule(_ action: @escaping () -> Void)
                }

                struct InlineScheduler {
                  func schedule(_ action: @escaping () -> Void) {
                    action()
                  }
                }

                extension InlineScheduler: Scheduler {}
                """,
            findings: []
        )
    }

    // The extended type is declared in another file, so its conformances are invisible.
    @Test func extensionOfUnknownTypeKeepsEscaping() {
        assertFormatting(
            DropRedundantEscaping.self,
            input: """
                extension InlineScheduler {
                  func schedule(_ action: @escaping () -> Void) {
                    action()
                  }
                }
                """,
            expected: """
                extension InlineScheduler {
                  func schedule(_ action: @escaping () -> Void) {
                    action()
                  }
                }
                """,
            findings: []
        )
    }

    // An override answers a superclass signature that is not visible here.
    @Test func overrideKeepsEscaping() {
        assertFormatting(
            DropRedundantEscaping.self,
            input: """
                class InlineScheduler: BaseScheduler {
                  override func schedule(_ action: @escaping () -> Void) {
                    action()
                  }
                }
                """,
            expected: """
                class InlineScheduler: BaseScheduler {
                  override func schedule(_ action: @escaping () -> Void) {
                    action()
                  }
                }
                """,
            findings: []
        )
    }

    @Test func protocolInitializerWitnessKeepsEscaping() {
        assertFormatting(
            DropRedundantEscaping.self,
            input: """
                protocol Scheduler {
                  init(_ action: @escaping () -> Void)
                }

                struct InlineScheduler: Scheduler {
                  init(_ action: @escaping () -> Void) {
                    action()
                  }
                }
                """,
            expected: """
                protocol Scheduler {
                  init(_ action: @escaping () -> Void)
                }

                struct InlineScheduler: Scheduler {
                  init(_ action: @escaping () -> Void) {
                    action()
                  }
                }
                """,
            findings: []
        )
    }

    // A conformance whose requirements take no closure leaves the rule free to act.
    @Test func closureFreeConformanceStillFlagged() {
        assertFormatting(
            DropRedundantEscaping.self,
            input: """
                struct InlineScheduler: Sendable {
                  func schedule(_ action: 1️⃣@escaping () -> Void) {
                    action()
                  }
                }
                """,
            expected: """
                struct InlineScheduler: Sendable {
                  func schedule(_ action: () -> Void) {
                    action()
                  }
                }
                """,
            findings: [
                FindingSpec(
                    "1️⃣", message: "remove '@escaping' from 'action'; the closure does not escape")
            ]
        )
    }

    @Test func typeWithoutConformanceStillFlagged() {
        assertFormatting(
            DropRedundantEscaping.self,
            input: """
                struct InlineScheduler {
                  func schedule(_ action: 1️⃣@escaping () -> Void) {
                    action()
                  }
                }
                """,
            expected: """
                struct InlineScheduler {
                  func schedule(_ action: () -> Void) {
                    action()
                  }
                }
                """,
            findings: [
                FindingSpec(
                    "1️⃣", message: "remove '@escaping' from 'action'; the closure does not escape")
            ]
        )
    }

    // No requirement carries this name, so the method witnesses nothing.
    @Test func unmatchedRequirementNameStillFlagged() {
        assertFormatting(
            DropRedundantEscaping.self,
            input: """
                protocol Scheduler {
                  func enqueue(_ action: @escaping () -> Void)
                }

                struct InlineScheduler: Scheduler {
                  func enqueue(_ action: @escaping () -> Void) {
                    store(action)
                  }

                  func schedule(_ action: 1️⃣@escaping () -> Void) {
                    action()
                  }
                }
                """,
            expected: """
                protocol Scheduler {
                  func enqueue(_ action: @escaping () -> Void)
                }

                struct InlineScheduler: Scheduler {
                  func enqueue(_ action: @escaping () -> Void) {
                    store(action)
                  }

                  func schedule(_ action: () -> Void) {
                    action()
                  }
                }
                """,
            findings: [
                FindingSpec(
                    "1️⃣", message: "remove '@escaping' from 'action'; the closure does not escape")
            ]
        )
    }

    @Test func multipleAttributesPreservesAutoclosure() {
        assertFormatting(
            DropRedundantEscaping.self,
            input: """
                func run(_ body: @autoclosure 1️⃣@escaping () -> Void) {
                  body()
                }
                """,
            expected: """
                func run(_ body: @autoclosure () -> Void) {
                  body()
                }
                """,
            findings: [
                FindingSpec(
                    "1️⃣", message: "remove '@escaping' from 'body'; the closure does not escape")
            ]
        )
    }
}
