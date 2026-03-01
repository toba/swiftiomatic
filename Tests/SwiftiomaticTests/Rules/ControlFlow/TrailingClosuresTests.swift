import Testing

@testable import Swiftiomatic

@Suite struct TrailingClosuresTests {
  @Test func anonymousClosureArgumentMadeTrailing() {
    let input = """
      foo(foo: 5, { /* some code */ })
      """
    let output = """
      foo(foo: 5) { /* some code */ }
      """
    testFormatting(for: input, output, rule: .trailingClosures)
  }

  @Test func namedClosureArgumentNotMadeTrailing() {
    let input = """
      foo(foo: 5, bar: { /* some code */ })
      """
    testFormatting(for: input, rule: .trailingClosures)
  }

  @Test func closureArgumentPassedToFunctionInArgumentsNotMadeTrailing() {
    let input = """
      foo(bar { /* some code */ })
      """
    testFormatting(for: input, rule: .trailingClosures)
  }

  @Test func closureArgumentInFunctionWithOtherClosureArgumentsNotMadeTrailing() {
    let input = """
      foo(foo: { /* some code */ }, { /* some code */ })
      """
    testFormatting(for: input, rule: .trailingClosures)
  }

  @Test func closureArgumentInIfStatementNotMadeTrailing() {
    let input = """
      if let foo = foo(foo: 5, { /* some code */ }) {}
      """
    testFormatting(for: input, rule: .trailingClosures)
  }

  @Test func closureArgumentInCompoundIfStatementNotMadeTrailing() {
    let input = """
      if let foo = foo(foo: 5, { /* some code */ }), let bar = bar(bar: 2, { /* some code */ }) {}
      """
    testFormatting(for: input, rule: .trailingClosures)
  }

  @Test func closureArgumentAfterLinebreakInGuardNotMadeTrailing() {
    let input = """
      guard let foo =
          bar({ /* some code */ })
      else { return }
      """
    testFormatting(
      for: input, rule: .trailingClosures,
      exclude: [.wrapConditionalBodies],
    )
  }

  @Test func closureMadeTrailingForNumericTupleMember() {
    let input = """
      foo.1(5, { bar })
      """
    let output = """
      foo.1(5) { bar }
      """
    testFormatting(for: input, output, rule: .trailingClosures)
  }

  @Test func anonymousInitClosureArgumentMadeTrailing() {
    let input = """
      Foo.init({ foo = bar })
      """
    let output = """
      Foo.init { foo = bar }
      """
    testFormatting(for: input, output, rule: .trailingClosures)
  }

  @Test func namedInitClosureArgumentNotMadeTrailing() {
    let input = """
      Foo.init(bar: { foo = bar })
      """
    testFormatting(for: input, rule: .trailingClosures)
  }

  @Test func noRemoveParensAroundClosureFollowedByOpeningBrace() {
    let input = """
      foo({ bar }) { baz }
      """
    testFormatting(for: input, rule: .trailingClosures)
  }

  @Test func removeParensAroundClosureWithInnerSpacesFollowedByUnwrapOperator() {
    let input = """
      foo( { bar } )?.baz
      """
    let output = """
      foo { bar }?.baz
      """
    testFormatting(for: input, output, rule: .trailingClosures)
  }

  // solitary argument

  @Test func parensAroundSolitaryClosureArgumentRemoved() {
    let input = """
      foo({ /* some code */ })
      """
    let output = """
      foo { /* some code */ }
      """
    testFormatting(for: input, output, rule: .trailingClosures)
  }

  @Test func parensAroundNamedSolitaryClosureArgumentNotRemoved() {
    let input = """
      foo(foo: { /* some code */ })
      """
    testFormatting(for: input, rule: .trailingClosures)
  }

  @Test func parensAroundSolitaryClosureArgumentInExpressionNotRemoved() {
    let input = """
      if let foo = foo({ /* some code */ }) {}
      """
    testFormatting(for: input, rule: .trailingClosures)
  }

  @Test func parensAroundSolitaryClosureArgumentInCompoundExpressionNotRemoved() {
    let input = """
      if let foo = foo({ /* some code */ }), let bar = bar({ /* some code */ }) {}
      """
    testFormatting(for: input, rule: .trailingClosures)
  }

  @Test func parensAroundOptionalTrailingClosureInForLoopNotRemoved() {
    let input = """
      for foo in bar?.map({ $0.baz }) ?? [] {}
      """
    testFormatting(for: input, rule: .trailingClosures)
  }

  @Test func parensAroundTrailingClosureInGuardCaseLetNotRemoved() {
    let input = """
      guard case let .foo(bar) = baz.filter({ $0 == quux }).isEmpty else {}
      """
    testFormatting(
      for: input, rule: .trailingClosures,
      exclude: [.wrapConditionalBodies],
    )
  }

  @Test func parensAroundTrailingClosureInWhereClauseLetNotRemoved() {
    let input = """
      for foo in bar where baz.filter({ $0 == quux }).isEmpty {}
      """
    testFormatting(for: input, rule: .trailingClosures)
  }

  @Test func parensAroundTrailingClosureInSwitchNotRemoved() {
    let input = """
      switch foo({ $0 == bar }).count {}
      """
    testFormatting(for: input, rule: .trailingClosures)
  }

  @Test func solitaryClosureMadeTrailingInChain() {
    let input = """
      foo.map({ $0.path }).joined()
      """
    let output = """
      foo.map { $0.path }.joined()
      """
    testFormatting(for: input, output, rule: .trailingClosures)
  }

  @Test func spaceNotInsertedAfterClosureBeforeUnwrap() {
    let input = """
      let foo = bar.map({ foo($0) })?.baz
      """
    let output = """
      let foo = bar.map { foo($0) }?.baz
      """
    testFormatting(for: input, output, rule: .trailingClosures)
  }

  @Test func spaceNotInsertedAfterClosureBeforeForceUnwrap() {
    let input = """
      let foo = bar.map({ foo($0) })!.baz
      """
    let output = """
      let foo = bar.map { foo($0) }!.baz
      """
    testFormatting(for: input, output, rule: .trailingClosures)
  }

  @Test func solitaryClosureMadeTrailingForNumericTupleMember() {
    let input = """
      foo.1({ bar })
      """
    let output = """
      foo.1 { bar }
      """
    testFormatting(for: input, output, rule: .trailingClosures)
  }

  // dispatch methods

  @Test func dispatchAsyncClosureArgumentMadeTrailing() {
    let input = """
      queue.async(execute: { /* some code */ })
      """
    let output = """
      queue.async { /* some code */ }
      """
    testFormatting(for: input, output, rule: .trailingClosures)
  }

  @Test func dispatchAsyncGroupClosureArgumentMadeTrailing() {
    // TODO: async(group: , qos: , flags: , execute: )
    let input = """
      queue.async(group: g, execute: { /* some code */ })
      """
    let output = """
      queue.async(group: g) { /* some code */ }
      """
    testFormatting(for: input, output, rule: .trailingClosures)
  }

  @Test func dispatchAsyncAfterClosureArgumentMadeTrailing() {
    let input = """
      queue.asyncAfter(deadline: t, execute: { /* some code */ })
      """
    let output = """
      queue.asyncAfter(deadline: t) { /* some code */ }
      """
    testFormatting(for: input, output, rule: .trailingClosures)
  }

  @Test func dispatchAsyncAfterWallClosureArgumentMadeTrailing() {
    let input = """
      queue.asyncAfter(wallDeadline: t, execute: { /* some code */ })
      """
    let output = """
      queue.asyncAfter(wallDeadline: t) { /* some code */ }
      """
    testFormatting(for: input, output, rule: .trailingClosures)
  }

  @Test func dispatchSyncClosureArgumentMadeTrailing() {
    let input = """
      queue.sync(execute: { /* some code */ })
      """
    let output = """
      queue.sync { /* some code */ }
      """
    testFormatting(for: input, output, rule: .trailingClosures)
  }

  @Test func dispatchSyncFlagsClosureArgumentMadeTrailing() {
    let input = """
      queue.sync(flags: f, execute: { /* some code */ })
      """
    let output = """
      queue.sync(flags: f) { /* some code */ }
      """
    testFormatting(for: input, output, rule: .trailingClosures)
  }

  // autoreleasepool

  @Test func autoreleasepoolMadeTrailing() {
    let input = """
      autoreleasepool(invoking: { /* some code */ })
      """
    let output = """
      autoreleasepool { /* some code */ }
      """
    testFormatting(for: input, output, rule: .trailingClosures)
  }

  // explicit trailing closure methods

  @Test func customMethodMadeTrailing() {
    let input = """
      foo(bar: 1, baz: { /* some code */ })
      """
    let output = """
      foo(bar: 1) { /* some code */ }
      """
    let options = FormatOptions(trailingClosures: ["foo"])
    testFormatting(for: input, output, rule: .trailingClosures, options: options)
  }

  // explicit non-trailing closure methods

  @Test func performBatchUpdatesNotMadeTrailing() {
    let input = """
      collectionView.performBatchUpdates({ /* some code */ })
      """
    testFormatting(for: input, rule: .trailingClosures)
  }

  @Test func nimbleExpectNotMadeTrailing() {
    let input = """
      expect({ bar }).to(beNil())
      """
    testFormatting(for: input, rule: .trailingClosures)
  }

  @Test func customMethodNotMadeTrailing() {
    let input = """
      foo({ /* some code */ })
      """
    let options = FormatOptions(neverTrailing: ["foo"])
    testFormatting(for: input, rule: .trailingClosures, options: options)
  }

  @Test func optionalClosureCallMadeTrailing() {
    let input = """
      myClosure?(foo: 5, { /* some code */ })
      """
    let output = """
      myClosure?(foo: 5) { /* some code */ }
      """
    testFormatting(for: input, output, rule: .trailingClosures)
  }

  @Test func optionalSolitaryClosureCallMadeTrailing() {
    let input = """
      myClosure?({ /* some code */ })
      """
    let output = """
      myClosure? { /* some code */ }
      """
    testFormatting(for: input, output, rule: .trailingClosures)
  }

  @Test func optionalClosureInChainMadeTrailing() {
    let input = """
      foo.myClosure?({ $0.path }).joined()
      """
    let output = """
      foo.myClosure? { $0.path }.joined()
      """
    testFormatting(for: input, output, rule: .trailingClosures)
  }

  @Test func optionalNamedClosureArgumentNotMadeTrailing() {
    let input = """
      myClosure?(foo: 5, bar: { /* some code */ })
      """
    testFormatting(for: input, rule: .trailingClosures)
  }

  @Test func returnTupleNotConfusedForFunctionCall() {
    let input = """
      return (expectation, { state in
          #expect(state == expectedStates.removeFirst())
          expectation.fulfill()
      })
      """

    testFormatting(for: input, rule: .trailingClosures, exclude: [.redundantParens])
  }

  @Test func closureReturnTupleNotConfusedForFunctionCall() {
    let input = """
      { _ in
          (expectation, { state in
              #expect(state == expectedStates.removeFirst())
              expectation.fulfill()
          })
      }
      """

    testFormatting(for: input, rule: .trailingClosures, exclude: [.redundantParens])
  }

  // multiple closures

  @Test func multipleTrailingClosuresWithFirstUnlabeled() {
    let input = """
      withAnimation(.linear, {
          // perform animation
      }, completion: {
          // handle completion
      })
      """
    let output = """
      withAnimation(.linear) {
          // perform animation
      } completion: {
          // handle completion
      }
      """
    testFormatting(for: input, output, rule: .trailingClosures)
  }

  @Test func multipleTrailingClosuresWithFirstLabeled() {
    let input = """
      withAnimation(.linear, animation: {
          // perform animation
      }, completion: {
          // handle completion
      })
      """
    testFormatting(for: input, rule: .trailingClosures)
  }

  @Test func multipleTrailingClosuresWithThreeClosures() {
    let input = """
      performTask(param: 1, {
          // first closure
      }, onSuccess: {
          // success handler
      }, onFailure: {
          // failure handler
      })
      """
    let output = """
      performTask(param: 1) {
          // first closure
      } onSuccess: {
          // success handler
      } onFailure: {
          // failure handler
      }
      """
    testFormatting(for: input, output, rule: .trailingClosures)
  }

  @Test func multipleTrailingClosuresNotAppliedWhenFirstIsLabeled() {
    let input = """
      someFunction(param: 1, first: {
          // first closure
      }, second: {
          // second closure
      })
      """
    testFormatting(for: input, rule: .trailingClosures)
  }

  @Test func multipleNestedClosures() {
    let repeatCount = 10
    let input = """
      override func foo() {
          bar {
              var baz = 5
      \(String(repeating: """
                fizz {
                    buzz {
                        fizzbuzz()
                    }
                }

        """, count: repeatCount))    }
      }
      """
    testFormatting(for: input, rule: .trailingClosures)
  }

  @Test func multipleTrailingClosuresWithTrailingComma() {
    let input = """
      withAnimationIfNeeded(
          .foo,
          .bar,
          { didAppear = true },
          completion: { animateText = true },
      )

      """
    let output = """
      withAnimationIfNeeded(
          .foo,
          .bar
      ) {
          didAppear = true
      } completion: {
          animateText = true
      }

      """
    testFormatting(
      for: input, [output], rules: [.trailingClosures, .indent, .wrapArguments, .wrap],
    )
  }

  @Test func multipleUnlabeledClosuresNotTransformed() {
    let input = """
      let foo = bar(
          { baz },
          { quux }
      )
      """
    testFormatting(for: input, rule: .trailingClosures)
  }

  @Test func multipleClosuresWithNonClosureArgumentInMiddle() {
    let input = """
      withObservationTracking(
          {
              _ = self[keyPath: keyPath]
          },
          token: {
              guard !isCancelled.value else {
                  return nil
              }

              return ""
          },
          willChange: nil,
          didChange: { [weak cancellable] in
              action(self[keyPath: keyPath])
              cancellable?.cancel()
          }
      )
      """

    testFormatting(for: input, rule: .trailingClosures)
  }

  @Test func methodWithOnlyClosureArguments() {
    let input = """
      withObservationTracking(
          {
              _ = self[keyPath: keyPath]
          },
          token: {
              guard !isCancelled.value else {
                  return nil
              }

              return ""
          },
          didChange: { [weak cancellable] in
              action(self[keyPath: keyPath])
              cancellable?.cancel()
          }
      )

      """

    let output = """
      withObservationTracking {
          _ = self[keyPath: keyPath]
      } token: {
          guard !isCancelled.value else {
              return nil
          }

          return ""
      } didChange: { [weak cancellable] in
          action(self[keyPath: keyPath])
          cancellable?.cancel()
      }

      """

    testFormatting(for: input, [output], rules: [.trailingClosures, .indent])
  }

  // property wrapper

  @Test func propertyWrapperDoesNotFormat() {
    let input = """
      class A {
          @BlockEquatable({ $0.isEqualTo($1) })
          var field: [B] = []
      }
      """
    testFormatting(for: input, rule: .trailingClosures)
  }
}
