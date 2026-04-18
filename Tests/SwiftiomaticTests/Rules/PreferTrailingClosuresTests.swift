@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct TrailingClosuresTests: RuleTesting {

  // MARK: - Single Trailing Closure

  @Test func anonymousClosureArgumentMadeTrailing() {
    assertFormatting(PreferTrailingClosures.self,
      input: """
        1️⃣foo(foo: 5, { /* some code */ })
        """,
      expected: """
        foo(foo: 5) { /* some code */ }
        """,
      findings: [FindingSpec("1️⃣", message: "use trailing closure syntax")])
  }

  @Test func namedClosureArgumentNotMadeTrailing() {
    assertFormatting(PreferTrailingClosures.self,
      input: """
        foo(foo: 5, bar: { /* some code */ })
        """,
      expected: """
        foo(foo: 5, bar: { /* some code */ })
        """,
      findings: [])
  }

  @Test func closureArgumentInFunctionArgsNotMadeTrailing() {
    assertFormatting(PreferTrailingClosures.self,
      input: """
        foo(bar { /* some code */ })
        """,
      expected: """
        foo(bar { /* some code */ })
        """,
      findings: [])
  }

  @Test func closureWithOtherClosureArgsNotMadeTrailing() {
    assertFormatting(PreferTrailingClosures.self,
      input: """
        foo(foo: { /* some code */ }, { /* some code */ })
        """,
      expected: """
        foo(foo: { /* some code */ }, { /* some code */ })
        """,
      findings: [])
  }

  @Test func solitaryClosureArgumentMadeTrailing() {
    assertFormatting(PreferTrailingClosures.self,
      input: """
        1️⃣foo({ /* some code */ })
        """,
      expected: """
        foo { /* some code */ }
        """,
      findings: [FindingSpec("1️⃣", message: "use trailing closure syntax")])
  }

  @Test func namedSolitaryClosureNotMadeTrailing() {
    assertFormatting(PreferTrailingClosures.self,
      input: """
        foo(foo: { /* some code */ })
        """,
      expected: """
        foo(foo: { /* some code */ })
        """,
      findings: [])
  }

  @Test func closureInChainMadeTrailing() {
    assertFormatting(PreferTrailingClosures.self,
      input: """
        1️⃣foo.map({ $0.path }).joined()
        """,
      expected: """
        foo.map { $0.path }.joined()
        """,
      findings: [FindingSpec("1️⃣", message: "use trailing closure syntax")])
  }

  @Test func spaceNotInsertedBeforeOptionalChain() {
    assertFormatting(PreferTrailingClosures.self,
      input: """
        let foo = 1️⃣bar.map({ foo($0) })?.baz
        """,
      expected: """
        let foo = bar.map { foo($0) }?.baz
        """,
      findings: [FindingSpec("1️⃣", message: "use trailing closure syntax")])
  }

  @Test func spaceNotInsertedBeforeForceUnwrap() {
    assertFormatting(PreferTrailingClosures.self,
      input: """
        let foo = 1️⃣bar.map({ foo($0) })!.baz
        """,
      expected: """
        let foo = bar.map { foo($0) }!.baz
        """,
      findings: [FindingSpec("1️⃣", message: "use trailing closure syntax")])
  }

  @Test func numericTupleMember() {
    assertFormatting(PreferTrailingClosures.self,
      input: """
        1️⃣foo.1(5, { bar })
        """,
      expected: """
        foo.1(5) { bar }
        """,
      findings: [FindingSpec("1️⃣", message: "use trailing closure syntax")])
  }

  @Test func solitaryNumericTupleMember() {
    assertFormatting(PreferTrailingClosures.self,
      input: """
        1️⃣foo.1({ bar })
        """,
      expected: """
        foo.1 { bar }
        """,
      findings: [FindingSpec("1️⃣", message: "use trailing closure syntax")])
  }

  @Test func initClosureMadeTrailing() {
    assertFormatting(PreferTrailingClosures.self,
      input: """
        1️⃣Foo.init({ foo = bar })
        """,
      expected: """
        Foo.init { foo = bar }
        """,
      findings: [FindingSpec("1️⃣", message: "use trailing closure syntax")])
  }

  @Test func namedInitClosureNotMadeTrailing() {
    assertFormatting(PreferTrailingClosures.self,
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
    assertFormatting(PreferTrailingClosures.self,
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
    assertFormatting(PreferTrailingClosures.self,
      input: """
        if let foo = foo(foo: 5, { /* some code */ }) {}
        """,
      expected: """
        if let foo = foo(foo: 5, { /* some code */ }) {}
        """,
      findings: [])
  }

  @Test func closureInCompoundIfStatementNotMadeTrailing() {
    assertFormatting(PreferTrailingClosures.self,
      input: """
        if let foo = foo(foo: 5, { /* some code */ }), let bar = bar(bar: 2, { /* some code */ }) {}
        """,
      expected: """
        if let foo = foo(foo: 5, { /* some code */ }), let bar = bar(bar: 2, { /* some code */ }) {}
        """,
      findings: [])
  }

  @Test func closureAfterLinebreakInGuardNotMadeTrailing() {
    assertFormatting(PreferTrailingClosures.self,
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
    assertFormatting(PreferTrailingClosures.self,
      input: """
        for _ in bar?.map({ $0.baz }) ?? [] {}
        """,
      expected: """
        for _ in bar?.map({ $0.baz }) ?? [] {}
        """,
      findings: [])
  }

  @Test func closureInWhereClauseNotMadeTrailing() {
    assertFormatting(PreferTrailingClosures.self,
      input: """
        for _ in bar where baz.filter({ $0 == quux }).isEmpty {}
        """,
      expected: """
        for _ in bar where baz.filter({ $0 == quux }).isEmpty {}
        """,
      findings: [])
  }

  @Test func closureInSwitchNotMadeTrailing() {
    assertFormatting(PreferTrailingClosures.self,
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

  @Test func closureInGuardCaseLetNotMadeTrailing() {
    assertFormatting(PreferTrailingClosures.self,
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
    assertFormatting(PreferTrailingClosures.self,
      input: """
        1️⃣queue.async(execute: { /* some code */ })
        """,
      expected: """
        queue.async { /* some code */ }
        """,
      findings: [FindingSpec("1️⃣", message: "use trailing closure syntax")])
  }

  @Test func dispatchAsyncGroupClosureMadeTrailing() {
    assertFormatting(PreferTrailingClosures.self,
      input: """
        1️⃣queue.async(group: g, execute: { /* some code */ })
        """,
      expected: """
        queue.async(group: g) { /* some code */ }
        """,
      findings: [FindingSpec("1️⃣", message: "use trailing closure syntax")])
  }

  @Test func dispatchAsyncAfterClosureMadeTrailing() {
    assertFormatting(PreferTrailingClosures.self,
      input: """
        1️⃣queue.asyncAfter(deadline: t, execute: { /* some code */ })
        """,
      expected: """
        queue.asyncAfter(deadline: t) { /* some code */ }
        """,
      findings: [FindingSpec("1️⃣", message: "use trailing closure syntax")])
  }

  @Test func dispatchSyncClosureMadeTrailing() {
    assertFormatting(PreferTrailingClosures.self,
      input: """
        1️⃣queue.sync(execute: { /* some code */ })
        """,
      expected: """
        queue.sync { /* some code */ }
        """,
      findings: [FindingSpec("1️⃣", message: "use trailing closure syntax")])
  }

  @Test func dispatchSyncFlagsClosureMadeTrailing() {
    assertFormatting(PreferTrailingClosures.self,
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
    assertFormatting(PreferTrailingClosures.self,
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
    assertFormatting(PreferTrailingClosures.self,
      input: """
        collectionView.performBatchUpdates({ /* some code */ })
        """,
      expected: """
        collectionView.performBatchUpdates({ /* some code */ })
        """,
      findings: [])
  }

  @Test func nimbleExpectNotMadeTrailing() {
    assertFormatting(PreferTrailingClosures.self,
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
    assertFormatting(PreferTrailingClosures.self,
      input: """
        1️⃣myClosure?(foo: 5, { /* some code */ })
        """,
      expected: """
        myClosure?(foo: 5) { /* some code */ }
        """,
      findings: [FindingSpec("1️⃣", message: "use trailing closure syntax")])
  }

  @Test func optionalSolitaryClosureMadeTrailing() {
    assertFormatting(PreferTrailingClosures.self,
      input: """
        1️⃣myClosure?({ /* some code */ })
        """,
      expected: """
        myClosure? { /* some code */ }
        """,
      findings: [FindingSpec("1️⃣", message: "use trailing closure syntax")])
  }

  @Test func optionalClosureInChainMadeTrailing() {
    assertFormatting(PreferTrailingClosures.self,
      input: """
        1️⃣foo.myClosure?({ $0.path }).joined()
        """,
      expected: """
        foo.myClosure? { $0.path }.joined()
        """,
      findings: [FindingSpec("1️⃣", message: "use trailing closure syntax")])
  }

  @Test func optionalNamedClosureNotMadeTrailing() {
    assertFormatting(PreferTrailingClosures.self,
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
    assertFormatting(PreferTrailingClosures.self,
      input: """
        1️⃣withAnimation(.linear, { doAnimation() }, completion: { handleCompletion() })
        """,
      expected: """
        withAnimation(.linear) { doAnimation() } completion: { handleCompletion() }
        """,
      findings: [FindingSpec("1️⃣", message: "use trailing closure syntax")])
  }

  @Test func multipleTrailingClosuresFirstLabeledNotConverted() {
    assertFormatting(PreferTrailingClosures.self,
      input: """
        withAnimation(.linear, animation: { doAnimation() }, completion: { handleCompletion() })
        """,
      expected: """
        withAnimation(.linear, animation: { doAnimation() }, completion: { handleCompletion() })
        """,
      findings: [])
  }

  @Test func multipleTrailingClosuresThreeClosures() {
    assertFormatting(PreferTrailingClosures.self,
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
    assertFormatting(PreferTrailingClosures.self,
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
    assertFormatting(PreferTrailingClosures.self,
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
    assertFormatting(PreferTrailingClosures.self,
      input: """
        1️⃣withObservation({ observe() }, onChange: { handleChange() })
        """,
      expected: """
        withObservation { observe() } onChange: { handleChange() }
        """,
      findings: [FindingSpec("1️⃣", message: "use trailing closure syntax")])
  }
}
