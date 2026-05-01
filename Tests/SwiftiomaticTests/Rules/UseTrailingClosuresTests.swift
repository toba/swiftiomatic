@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct TrailingClosuresTests: RuleTesting {

  // MARK: - Single Trailing Closure

  @Test func anonymousClosureArgumentMadeTrailing() {
    assertFormatting(UseTrailingClosures.self,
      input: """
        1️⃣foo(foo: 5, { /* some code */ })
        """,
      expected: """
        foo(foo: 5) { /* some code */ }
        """,
      findings: [FindingSpec("1️⃣", message: "use trailing closure syntax")])
  }

  @Test func namedClosureArgumentNotMadeTrailing() {
    assertFormatting(UseTrailingClosures.self,
      input: """
        foo(foo: 5, bar: { /* some code */ })
        """,
      expected: """
        foo(foo: 5, bar: { /* some code */ })
        """,
      findings: [])
  }

  @Test func closureArgumentInFunctionArgsNotMadeTrailing() {
    assertFormatting(UseTrailingClosures.self,
      input: """
        foo(bar { /* some code */ })
        """,
      expected: """
        foo(bar { /* some code */ })
        """,
      findings: [])
  }

  @Test func closureWithOtherClosureArgsNotMadeTrailing() {
    assertFormatting(UseTrailingClosures.self,
      input: """
        foo(foo: { /* some code */ }, { /* some code */ })
        """,
      expected: """
        foo(foo: { /* some code */ }, { /* some code */ })
        """,
      findings: [])
  }

  @Test func solitaryClosureArgumentMadeTrailing() {
    assertFormatting(UseTrailingClosures.self,
      input: """
        1️⃣foo({ /* some code */ })
        """,
      expected: """
        foo { /* some code */ }
        """,
      findings: [FindingSpec("1️⃣", message: "use trailing closure syntax")])
  }

  @Test func namedSolitaryClosureNotMadeTrailing() {
    assertFormatting(UseTrailingClosures.self,
      input: """
        foo(foo: { /* some code */ })
        """,
      expected: """
        foo(foo: { /* some code */ })
        """,
      findings: [])
  }

  @Test func closureInChainMadeTrailing() {
    assertFormatting(UseTrailingClosures.self,
      input: """
        1️⃣foo.map({ $0.path }).joined()
        """,
      expected: """
        foo.map { $0.path }.joined()
        """,
      findings: [FindingSpec("1️⃣", message: "use trailing closure syntax")])
  }

  @Test func spaceNotInsertedBeforeOptionalChain() {
    assertFormatting(UseTrailingClosures.self,
      input: """
        let foo = 1️⃣bar.map({ foo($0) })?.baz
        """,
      expected: """
        let foo = bar.map { foo($0) }?.baz
        """,
      findings: [FindingSpec("1️⃣", message: "use trailing closure syntax")])
  }

  @Test func spaceNotInsertedBeforeForceUnwrap() {
    assertFormatting(UseTrailingClosures.self,
      input: """
        let foo = 1️⃣bar.map({ foo($0) })!.baz
        """,
      expected: """
        let foo = bar.map { foo($0) }!.baz
        """,
      findings: [FindingSpec("1️⃣", message: "use trailing closure syntax")])
  }

  @Test func numericTupleMember() {
    assertFormatting(UseTrailingClosures.self,
      input: """
        1️⃣foo.1(5, { bar })
        """,
      expected: """
        foo.1(5) { bar }
        """,
      findings: [FindingSpec("1️⃣", message: "use trailing closure syntax")])
  }

  @Test func solitaryNumericTupleMember() {
    assertFormatting(UseTrailingClosures.self,
      input: """
        1️⃣foo.1({ bar })
        """,
      expected: """
        foo.1 { bar }
        """,
      findings: [FindingSpec("1️⃣", message: "use trailing closure syntax")])
  }

  @Test func initClosureMadeTrailing() {
    assertFormatting(UseTrailingClosures.self,
      input: """
        1️⃣Foo.init({ foo = bar })
        """,
      expected: """
        Foo.init { foo = bar }
        """,
      findings: [FindingSpec("1️⃣", message: "use trailing closure syntax")])
  }

  @Test func namedInitClosureNotMadeTrailing() {
    assertFormatting(UseTrailingClosures.self,
      input: """
        Foo.init(bar: { foo = bar })
        """,
      expected: """
        Foo.init(bar: { foo = bar })
        """,
      findings: [])
  }

  // MARK: - Already Has Trailing Closure

  @Test func noChangesWhenAlreadyTrailing() {
    assertFormatting(UseTrailingClosures.self,
      input: """
        foo({ bar }) { baz }
        """,
      expected: """
        foo({ bar }) { baz }
        """,
      findings: [])
  }

  // MARK: - Conditional Context

  @Test func closureInIfStatementNotMadeTrailing() {
    assertFormatting(UseTrailingClosures.self,
      input: """
        if let foo = foo(foo: 5, { /* some code */ }) {}
        """,
      expected: """
        if let foo = foo(foo: 5, { /* some code */ }) {}
        """,
      findings: [])
  }

  @Test func closureInCompoundIfStatementNotMadeTrailing() {
    assertFormatting(UseTrailingClosures.self,
      input: """
        if let foo = foo(foo: 5, { /* some code */ }), let bar = bar(bar: 2, { /* some code */ }) {}
        """,
      expected: """
        if let foo = foo(foo: 5, { /* some code */ }), let bar = bar(bar: 2, { /* some code */ }) {}
        """,
      findings: [])
  }

  @Test func closureAfterLinebreakInGuardNotMadeTrailing() {
    assertFormatting(UseTrailingClosures.self,
      input: """
        guard let foo =
            bar({ /* some code */ })
        else {
            return
        }
        """,
      expected: """
        guard let foo =
            bar({ /* some code */ })
        else {
            return
        }
        """,
      findings: [])
  }

  @Test func closureInForLoopNotMadeTrailing() {
    assertFormatting(UseTrailingClosures.self,
      input: """
        for _ in bar?.map({ $0.baz }) ?? [] {}
        """,
      expected: """
        for _ in bar?.map({ $0.baz }) ?? [] {}
        """,
      findings: [])
  }

  @Test func closureInWhereClauseNotMadeTrailing() {
    assertFormatting(UseTrailingClosures.self,
      input: """
        for _ in bar where baz.filter({ $0 == quux }).isEmpty {}
        """,
      expected: """
        for _ in bar where baz.filter({ $0 == quux }).isEmpty {}
        """,
      findings: [])
  }

  @Test func closureInSwitchNotMadeTrailing() {
    assertFormatting(UseTrailingClosures.self,
      input: """
        switch foo({ $0 == bar }).count {
        default: break
        }
        """,
      expected: """
        switch foo({ $0 == bar }).count {
        default: break
        }
        """,
      findings: [])
  }

  /// Regression test for wy7-t4q: bare `guard <call>({ ... }) else { ... }` was being made
  /// trailing because `isInConditionalContext` walked `Syntax(node).parent` post- `super.visit`
  /// (always nil after the rewriter detaches children). The fix routes the *original* parent
  /// captured before `super.visit` into `apply` , so the `ConditionElementSyntax` ancestor is
  /// detected and the rewrite is suppressed.
  @Test func closureInBareGuardConditionNotMadeTrailing() {
    assertFormatting(UseTrailingClosures.self,
      input: """
        guard arr.allSatisfy({ $0 > 0 }) else { return }
        """,
      expected: """
        guard arr.allSatisfy({ $0 > 0 }) else { return }
        """,
      findings: [])
  }

  @Test func closureInBareIfConditionNotMadeTrailing() {
    assertFormatting(UseTrailingClosures.self,
      input: """
        if arr.allSatisfy({ $0 > 0 }) {}
        """,
      expected: """
        if arr.allSatisfy({ $0 > 0 }) {}
        """,
      findings: [])
  }

  @Test func closureInGuardCaseLetNotMadeTrailing() {
    assertFormatting(UseTrailingClosures.self,
      input: """
        guard case let .foo(bar) = baz.filter({ $0 == quux }).isEmpty else {
            return
        }
        """,
      expected: """
        guard case let .foo(bar) = baz.filter({ $0 == quux }).isEmpty else {
            return
        }
        """,
      findings: [])
  }

  // MARK: - Dispatch Methods

  @Test func dispatchAsyncClosureMadeTrailing() {
    assertFormatting(UseTrailingClosures.self,
      input: """
        1️⃣queue.async(execute: { /* some code */ })
        """,
      expected: """
        queue.async { /* some code */ }
        """,
      findings: [FindingSpec("1️⃣", message: "use trailing closure syntax")])
  }

  @Test func dispatchAsyncGroupClosureMadeTrailing() {
    assertFormatting(UseTrailingClosures.self,
      input: """
        1️⃣queue.async(group: g, execute: { /* some code */ })
        """,
      expected: """
        queue.async(group: g) { /* some code */ }
        """,
      findings: [FindingSpec("1️⃣", message: "use trailing closure syntax")])
  }

  @Test func dispatchAsyncAfterClosureMadeTrailing() {
    assertFormatting(UseTrailingClosures.self,
      input: """
        1️⃣queue.asyncAfter(deadline: t, execute: { /* some code */ })
        """,
      expected: """
        queue.asyncAfter(deadline: t) { /* some code */ }
        """,
      findings: [FindingSpec("1️⃣", message: "use trailing closure syntax")])
  }

  @Test func dispatchSyncClosureMadeTrailing() {
    assertFormatting(UseTrailingClosures.self,
      input: """
        1️⃣queue.sync(execute: { /* some code */ })
        """,
      expected: """
        queue.sync { /* some code */ }
        """,
      findings: [FindingSpec("1️⃣", message: "use trailing closure syntax")])
  }

  @Test func dispatchSyncFlagsClosureMadeTrailing() {
    assertFormatting(UseTrailingClosures.self,
      input: """
        1️⃣queue.sync(flags: f, execute: { /* some code */ })
        """,
      expected: """
        queue.sync(flags: f) { /* some code */ }
        """,
      findings: [FindingSpec("1️⃣", message: "use trailing closure syntax")])
  }

  // MARK: - Autoreleasepool

  @Test func autoreleasepoolMadeTrailing() {
    assertFormatting(UseTrailingClosures.self,
      input: """
        1️⃣autoreleasepool(invoking: { /* some code */ })
        """,
      expected: """
        autoreleasepool { /* some code */ }
        """,
      findings: [FindingSpec("1️⃣", message: "use trailing closure syntax")])
  }

  // MARK: - Never Trailing

  @Test func performBatchUpdatesNotMadeTrailing() {
    assertFormatting(UseTrailingClosures.self,
      input: """
        collectionView.performBatchUpdates({ /* some code */ })
        """,
      expected: """
        collectionView.performBatchUpdates({ /* some code */ })
        """,
      findings: [])
  }

  @Test func nimbleExpectNotMadeTrailing() {
    assertFormatting(UseTrailingClosures.self,
      input: """
        expect({ bar }).to(beNil())
        """,
      expected: """
        expect({ bar }).to(beNil())
        """,
      findings: [])
  }

  // MARK: - Optional Chaining

  @Test func optionalClosureMadeTrailing() {
    assertFormatting(UseTrailingClosures.self,
      input: """
        1️⃣myClosure?(foo: 5, { /* some code */ })
        """,
      expected: """
        myClosure?(foo: 5) { /* some code */ }
        """,
      findings: [FindingSpec("1️⃣", message: "use trailing closure syntax")])
  }

  @Test func optionalSolitaryClosureMadeTrailing() {
    assertFormatting(UseTrailingClosures.self,
      input: """
        1️⃣myClosure?({ /* some code */ })
        """,
      expected: """
        myClosure? { /* some code */ }
        """,
      findings: [FindingSpec("1️⃣", message: "use trailing closure syntax")])
  }

  @Test func optionalClosureInChainMadeTrailing() {
    assertFormatting(UseTrailingClosures.self,
      input: """
        1️⃣foo.myClosure?({ $0.path }).joined()
        """,
      expected: """
        foo.myClosure? { $0.path }.joined()
        """,
      findings: [FindingSpec("1️⃣", message: "use trailing closure syntax")])
  }

  @Test func optionalNamedClosureNotMadeTrailing() {
    assertFormatting(UseTrailingClosures.self,
      input: """
        myClosure?(foo: 5, bar: { /* some code */ })
        """,
      expected: """
        myClosure?(foo: 5, bar: { /* some code */ })
        """,
      findings: [])
  }

  // MARK: - Multiple Trailing Closures

  @Test func multipleTrailingClosuresFirstUnlabeled() {
    assertFormatting(UseTrailingClosures.self,
      input: """
        1️⃣withAnimation(.linear, { doAnimation() }, completion: { handleCompletion() })
        """,
      expected: """
        withAnimation(.linear) { doAnimation() } completion: { handleCompletion() }
        """,
      findings: [FindingSpec("1️⃣", message: "use trailing closure syntax")])
  }

  @Test func multipleTrailingClosuresFirstLabeledNotConverted() {
    assertFormatting(UseTrailingClosures.self,
      input: """
        withAnimation(.linear, animation: { doAnimation() }, completion: { handleCompletion() })
        """,
      expected: """
        withAnimation(.linear, animation: { doAnimation() }, completion: { handleCompletion() })
        """,
      findings: [])
  }

  @Test func multipleTrailingClosuresThreeClosures() {
    assertFormatting(UseTrailingClosures.self,
      input: """
        1️⃣performTask(param: 1, {
            doFirst()
        }, onSuccess: {
            handleSuccess()
        }, onFailure: {
            handleFailure()
        })
        """,
      expected: """
        performTask(param: 1) {
            doFirst()
        } onSuccess: {
            handleSuccess()
        } onFailure: {
            handleFailure()
        }
        """,
      findings: [FindingSpec("1️⃣", message: "use trailing closure syntax")])
  }

  @Test func multipleUnlabeledClosuresNotTransformed() {
    assertFormatting(UseTrailingClosures.self,
      input: """
        let foo = bar(
            { baz },
            { quux }
        )
        """,
      expected: """
        let foo = bar(
            { baz },
            { quux }
        )
        """,
      findings: [])
  }

  @Test func multipleClosuresWithNonClosureInMiddle() {
    assertFormatting(UseTrailingClosures.self,
      input: """
        someFunc(
            { first() },
            middle: nil,
            last: { last() }
        )
        """,
      expected: """
        someFunc(
            { first() },
            middle: nil,
            last: { last() }
        )
        """,
      findings: [])
  }

  @Test func allClosureArgumentsMadeTrailing() {
    assertFormatting(UseTrailingClosures.self,
      input: """
        1️⃣withObservation({ observe() }, onChange: { handleChange() })
        """,
      expected: """
        withObservation { observe() } onChange: { handleChange() }
        """,
      findings: [FindingSpec("1️⃣", message: "use trailing closure syntax")])
  }
}
