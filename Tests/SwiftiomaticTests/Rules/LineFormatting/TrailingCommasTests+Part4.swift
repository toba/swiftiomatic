import Testing

@testable import Swiftiomatic

extension TrailingCommasTests {
  @Test func trailingCommasAddedToClosureTupleTypealiasesInSwift6_2() {
    let input = """
      public typealias StringToInt = (
          String
      ) -> Int

      public enum Toster {
          public typealias StringToInt = ((
              String
          ) -> Int)?
      }

      public typealias Tuple = (
          foo: String,
          bar: Int
      )

      public typealias OptionalTuple = (
          foo: String,
          bar: Int,
          baaz: Bool
      )?
      """
    let output = """
      public typealias StringToInt = (
          String,
      ) -> Int

      public enum Toster {
          public typealias StringToInt = ((
              String,
          ) -> Int)?
      }

      public typealias Tuple = (
          foo: String,
          bar: Int,
      )

      public typealias OptionalTuple = (
          foo: String,
          bar: Int,
          baaz: Bool,
      )?
      """

    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasAddedToReturnTupleSwift6_2() {
    let input = """
      func foo() -> (Int, Int) {
          let bar = 0
          let baz = 1

          return (
              bar,
              baz
          )
      }
      """
    let output = """
      func foo() -> (Int, Int) {
          let bar = 0
          let baz = 1

          return (
              bar,
              baz,
          )
      }
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasAddedToThrowSwift6_2() {
    let input = """
      enum FooError: Error {
          case bar
      }

      func baz() throws {
          throw (
              FooError.bar
          )
      }
      """

    let output = """
      enum FooError: Error {
          case bar
      }

      func baz() throws {
          throw (
              FooError.bar,
          )
      }
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasAddedToSwitchSwift6_2() {
    let input = """
      let foo = (
          bar: 0,
          baz: 1
      )
      switch (
          foo.bar,
          foo.baz
      ) {
      case (
          0,
          1
      ): break
      default: break
      }
      """
    let output = """
      let foo = (
          bar: 0,
          baz: 1,
      )
      switch (
          foo.bar,
          foo.baz,
      ) {
      case (
          0,
          1,
      ): break
      default: break
      }
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasAddedToAttributeSwift6_2() {
    let input = """
      @Foo(
          "bar",
          "baz"
      )
      struct Qux {}
      """
    let output = """
      @Foo(
          "bar",
          "baz",
      )
      struct Qux {}
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasNotAddedToBuiltInAttributesInSwift6_2() {
    let input = """
      @available(
          *,
          deprecated,
          renamed: "bar"
      )
      func foo() {}

      @backDeployed(
          before: iOS 17
      )
      public func foo() {}

      @objc(
          custom_objc_name
      )
      class MyClass: NSObject()

      @freestanding(
          declaration,
          names: named(CodingKeys)
      )
      macro FreestandingMacro() = #externalMacro(module: "Macros", type: "")

      @attached(
          extension,
          names: arbitrary
      )
      macro AttachedMacro() = #externalMacro(module: "Macros", type: "")

      @_originallyDefinedIn(
          module: "Foo",
          macOS 10.0
      )
      extension CoreFoundation.CGFloat: Swift.SignedNumeric {}
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
    testFormatting(for: input, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasAddedToMacroSwift6_2() {
    let input = """
      #foo(
          "bar",
          "baz"
      )
      """
    let output = """
      #foo(
          "bar",
          "baz",
      )
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasAddedToGenericListSwift6_2() {
    let input = """
      struct S<
          T1,
          T2,
          T3
      > {}

      typealias T<
          T1,
          T2
      > = S<T1, T2, Bool>

      func foo<
          T1,
          T2,
      >() -> (T1, T2) {}
      """
    let output = """
      struct S<
          T1,
          T2,
          T3,
      > {}

      typealias T<
          T1,
          T2,
      > = S<T1, T2, Bool>

      func foo<
          T1,
          T2,
      >() -> (T1, T2) {}
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasAddedToGenericTypesInSwift6_2() {
    // Trailing commas are now supported in generic types in Swift 6.2
    let input = """
      public final class TestThing: GenericThing<
          Test1,
          Test2,
          Test3
      > {}

      func foo(_: GenericThing<
          Test1,
          Test2,
          Test3
      >) {}

      typealias T<
          T1,
          T2,
      > = S<
          T1,
          T2,
          Bool
      >

      extension Dictionary<
          String,
          Any
      > {}

      protocol MyProtocolWithAssociatedTypes<
          Foo,
          Bar
      > {}
      """
    let output = """
      public final class TestThing: GenericThing<
          Test1,
          Test2,
          Test3,
      > {}

      func foo(_: GenericThing<
          Test1,
          Test2,
          Test3,
      >) {}

      typealias T<
          T1,
          T2,
      > = S<
          T1,
          T2,
          Bool,
      >

      extension Dictionary<
          String,
          Any,
      > {}

      protocol MyProtocolWithAssociatedTypes<
          Foo,
          Bar,
      > {}
      """

    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
    testFormatting(
      for: input, output, rule: .trailingCommas, options: options,
      exclude: [.emptyExtensions, .typeSugar],
    )
  }

  @Test func trailingCommasRemovedFromSingleLineGenericListSwift6_2() {
    let input = """
      struct S<T1, T2, T3,> {}
      """
    let output = """
      struct S<T1, T2, T3> {}
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasAddedToCaptureListSwift6_2() {
    let input = """
      { [
          capturedValue1,
          capturedValue2
      ] in
      }
      """
    let output = """
      { [
          capturedValue1,
          capturedValue2,
      ] in
      }
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasRemovedFromSingleElementCaptureListSwift6_2() {
    let input = """
      { [
          capturedValue1,
      ] in
      }
      """
    let output = """
      { [
          capturedValue1
      ] in
      }
      """
    let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.2")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasRemovedFromSingleLineCaptureListSwift6_2() {
    let input = """
      { [capturedValue1, capturedValue2,] in
          print(capturedValue1, capturedValue2)
      }
      """
    let output = """
      { [capturedValue1, capturedValue2] in
          print(capturedValue1, capturedValue2)
      }
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasAddedToSubscriptSwift6_2() {
    let input = """
      let value = m[
          x,
          y
      ]
      """
    let output = """
      let value = m[
          x,
          y,
      ]
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasRemoveFromSubscriptWhenCollectionsOnlySwift6_2() {
    let input = """
      let value = m[
          x,
          y,
      ]
      """
    let output = """
      let value = m[
          x,
          y
      ]
      """
    let options = FormatOptions(trailingCommas: .collectionsOnly, swiftVersion: "6.2")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasRemovedFromSingleLineSubscriptSwift6_2() {
    let input = """
      let value = m[x, y,]
      """
    let output = """
      let value = m[x, y]
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func addingTrailingCommaDoesNotConflictWithOpaqueGenericParametersRuleSwift6_2() {
    let input = """
      private func foo<
          Foo: Bar,
          Bar: Baaz
      >(a: Foo, b: Foo)
          where Foo == Bar
      {
          print(a, b)
      }
      """

    let output = """
      private func foo<
          Foo: Bar,
          Bar: Baaz,
      >(a: Foo, b: Foo)
          where Foo == Bar
      {
          print(a, b)
      }
      """

    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func collectionsOnlyAddsCollectionCommasAndRemovesNonCollectionCommasSwift6_2() {
    let input = """
      let array = [
          1,
          2
      ]

      func foo(
          a: Int,
          b: Int,
      ) {
          print(a, b)
      }
      """
    let output = """
      let array = [
          1,
          2,
      ]

      func foo(
          a: Int,
          b: Int
      ) {
          print(a, b)
      }
      """
    let options = FormatOptions(trailingCommas: .collectionsOnly, swiftVersion: "6.2")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasNotRemovedFromInitParametersWithAlwaysOptionSwift6_2() {
    let input = """
      public init(
          parameter: Parameter,
      ) {
          // test
      }
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
    testFormatting(
      for: input,
      rule: .trailingCommas,
      options: options,
      exclude: [.unusedArguments],
    )
  }

  @Test func trailingCommasAddedToInitParametersWithAlwaysOptionSwift6_2() {
    let input = """
      public init(
          parameter: Parameter
      ) {
          // test
      }
      """
    let output = """
      public init(
          parameter: Parameter,
      ) {
          // test
      }
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
    testFormatting(
      for: input, output, rule: .trailingCommas, options: options,
      exclude: [.unusedArguments],
    )
  }

  @Test func multiElementListsAddsCommaToMultiElementArraySwift6_2() {
    let input = """
      let array = [
          1,
          2
      ]
      """
    let output = """
      let array = [
          1,
          2,
      ]
      """
    let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.2")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func multiElementListsDoesNotAddCommaToSingleElementArraySwift6_2() {
    let input = """
      let array = [
          1
      ]
      """
    let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.2")
    testFormatting(for: input, rule: .trailingCommas, options: options)
  }

  @Test func multiElementListsAddsCommaToMultiElementFunctionSwift6_2() {
    let input = """
      func foo(
          a: Int,
          b: Int
      ) {
          print(a, b)
      }
      """
    let output = """
      func foo(
          a: Int,
          b: Int,
      ) {
          print(a, b)
      }
      """
    let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.2")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func multiElementListsDoesNotAddCommaToSingleElementFunctionSwift6_2() {
    let input = """
      func foo(
          a: Int
      ) {
          print(a)
      }

      init(
          a: Int
      ) {
          print(a)
      }
      """
    let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.2")
    testFormatting(for: input, rule: .trailingCommas, options: options)
  }

  @Test func multiElementListsAddsCommaToMultiElementFunctionCallSwift6_2() {
    let input = """
      foo(
          a: 1,
          b: 2
      )
      """
    let output = """
      foo(
          a: 1,
          b: 2,
      )
      """
    let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.2")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func multiElementListsDoesNotAddCommaToSingleElementFunctionCallSwift6_2() {
    let input = """
      foo(
          a: 1
      )
      """
    let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.2")
    testFormatting(for: input, rule: .trailingCommas, options: options)
  }

  @Test func multiElementListsAddsCommaToMultiElementGenericListSwift6_2() {
    let input = """
      struct Foo<
          T,
          U
      > {}
      """
    let output = """
      struct Foo<
          T,
          U,
      > {}
      """
    let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.2")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func multiElementListsDoesNotAddCommaToSingleElementGenericListSwift6_2() {
    let input = """
      struct Foo<
          T
      > {}
      """
    let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.2")
    testFormatting(for: input, rule: .trailingCommas, options: options)
  }

  @Test func multiElementListsRemovesCommaFromSingleElementArraySwift6_2() {
    let input = """
      let array = [
          1,
      ]
      """
    let output = """
      let array = [
          1
      ]
      """
    let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.2")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func multiElementListsRemovesCommaFromSingleElementFunctionSwift6_2() {
    let input = """
      func foo(
          a: Int,
      ) {
          print(a)
      }
      """
    let output = """
      func foo(
          a: Int
      ) {
          print(a)
      }
      """
    let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.2")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func multiElementListsRemovesCommaFromSingleElementInitSwift6_2() {
    let input = """
      public init(
          a: Int,
      ) {
          print(a)
      }
      """
    let output = """
      public init(
          a: Int
      ) {
          print(a)
      }
      """
    let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.2")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func multiElementListsAddCommaToInitSwift6_2() {
    let input = """
      public init(
          a: Int,
          b: Int
      ) {
          print(a, b)
      }
      """
    let output = """
      public init(
          a: Int,
          b: Int,
      ) {
          print(a, b)
      }
      """
    let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.2")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommaAddedToTupleAndClosureTypesSwift6_2() {
    let input = """
      let foo: (
          bar: String,
          quux: String
      )

      let bar: (
          bar: String,
          baaz: String
      ) -> Void

      public @Test func closureArgumentInTuple() {
          _ = object.methodWithTupleArgument((
              closureArgument: { capturedObject in
                  _ = capturedObject
              },
          ))
      }
      """
    let output = """
      let foo: (
          bar: String,
          quux: String,
      )

      let bar: (
          bar: String,
          baaz: String,
      ) -> Void

      public @Test func closureArgumentInTuple() {
          _ = object.methodWithTupleArgument((
              closureArgument: { capturedObject in
                  _ = capturedObject
              },
          ))
      }
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func multiElementListsTrailingCommasAddedToClosureTypeSwift6_2() {
    let input = """
      let foo: (
          bar: String
      ) -> Void

      let foo: (
          bar: String,
          baaz: String
      ) -> Void
      """
    let output = """
      let foo: (
          bar: String
      ) -> Void

      let foo: (
          bar: String,
          baaz: String,
      ) -> Void
      """
    let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.2")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func multiElementListsTrailingCommasAddedToTupleAndClosureTypesSwift6_2() {
    let input = """
      let bar: (
          bar: String,
          baaz: String
      )

      let bar: (
          bar: String,
          baaz: String
      ) -> Void
      """
    let output = """
      let bar: (
          bar: String,
          baaz: String,
      )

      let bar: (
          bar: String,
          baaz: String,
      ) -> Void
      """
    let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.2")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasAddedToOptionalClosureCallSwift6_2() {
    let input = """
      myClosure?(
          foo: 5,
          bar: 10
      )
      """
    let output = """
      myClosure?(
          foo: 5,
          bar: 10,
      )
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasAddedToOptionalClosureCallSingleParameterSwift6_2() {
    let input = """
      myClosure?(
          foo: 5
      )
      """
    let output = """
      myClosure?(
          foo: 5,
      )
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasMultiElementListsOptionalClosureCallSwift6_2() {
    let input = """
      myClosure?(
          foo: 5,
      )

      otherClosure?(
          foo: 5,
          bar: 10
      )
      """
    let output = """
      myClosure?(
          foo: 5
      )

      otherClosure?(
          foo: 5,
          bar: 10,
      )
      """
    let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.2")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasInTupleTypeCastAddedSwift6_2() {
    // Now supported in Swift 6.2
    let input = """
      let foo = bar as? (
          Foo,
          Bar
      )
      """
    let output = """
      let foo = bar as? (
          Foo,
          Bar,
      )
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func issue2142Swift6_2() {
    let input = """
      public func bindExitButton<T: Presenter>(
          action: T.Action,
          withIdentifier identifier: UIAction.Identifier? = nil,
          on controlEvents: UIControl.Event = .primaryActionTriggered,
          to presenter: T,
      ) {
          _ = action
          _ = identifier
          _ = controlEvents
          _ = presenter
      }

      let setModeSwizzle = Swizzle<AVAudioSession>(
          instance: instance,
          original: #selector(AVAudioSession.setMode(_:)),
          swizzled: #selector(AVAudioSession.swizzled_setMode(_:)),
      )
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
    testFormatting(
      for: input,
      rule: .trailingCommas,
      options: options,
      exclude: [.propertyTypes],
    )
  }

  @Test func issue2143Swift6_2() {
    let input = """
      public @Test func closureArgumentInTuple() {
          _ = object.methodWithTupleArgument((
              closureArgument: { capturedObject in
                  _ = capturedObject
              },
          ))
      }
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
    testFormatting(for: input, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommaNotAddedToTypedThrows() {
    let input = """
      func confirmCommunication(transactionID: String) async throws(
          Either<PhoneNumberChangeConfirmCommunicationError, SkyusersV2GenericError>
      ) -> TimeInterval
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
    testFormatting(for: input, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommaNotAddedToSelector() {
    let input = """
      foo(action: #selector(
          reallyLongFunctionName(withLongParameters:)
      ))
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
    testFormatting(for: input, rule: .trailingCommas, options: options)
  }

  @Test func arrayTypeNotMistakenForLiteral() {
    let input = """
      let myParsedList = (myRawList as? [
          MyItemType
      ])?.compactMap(parse)
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
    testFormatting(for: input, rule: .trailingCommas, options: options)
  }
}
