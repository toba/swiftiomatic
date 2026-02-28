import Testing

@testable import Swiftiomatic

@Suite struct TrailingCommasTests {
  @Test func commaAddedToSingleItem() {
    let input = """
      [
          foo
      ]
      """
    let output = """
      [
          foo,
      ]
      """
    testFormatting(for: input, output, rule: .trailingCommas)
  }

  @Test func commaAddedToLastItem() {
    let input = """
      [
          foo,
          bar
      ]
      """
    let output = """
      [
          foo,
          bar,
      ]
      """
    testFormatting(for: input, output, rule: .trailingCommas)
  }

  @Test func commaAddedToLastItemCollectionsOnly() {
    let input = """
      [
          foo,
          bar
      ]
      """
    let output = """
      [
          foo,
          bar,
      ]
      """
    let options = FormatOptions(trailingCommas: .collectionsOnly)
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func commaAddedToDictionary() {
    let input = """
      [
          foo: bar
      ]
      """
    let output = """
      [
          foo: bar,
      ]
      """
    testFormatting(for: input, output, rule: .trailingCommas)
  }

  @Test func commaNotAddedToInlineArray() {
    let input = """
      [foo, bar]
      """
    testFormatting(for: input, rule: .trailingCommas)
  }

  @Test func commaNotAddedToInlineDictionary() {
    let input = """
      [foo: bar]
      """
    testFormatting(for: input, rule: .trailingCommas)
  }

  @Test func commaNotAddedToSubscript() {
    let input = """
      foo[bar]
      """
    testFormatting(for: input, rule: .trailingCommas)
  }

  @Test func commaAddedBeforeComment() {
    let input = """
      [
          foo // comment
      ]
      """
    let output = """
      [
          foo, // comment
      ]
      """
    testFormatting(for: input, output, rule: .trailingCommas)
  }

  @Test func commaNotAddedAfterComment() {
    let input = """
      [
          foo, // comment
      ]
      """
    testFormatting(for: input, rule: .trailingCommas)
  }

  @Test func commaNotAddedInsideEmptyArrayLiteral() {
    let input = """
      foo = [
      ]
      """
    testFormatting(for: input, rule: .trailingCommas)
  }

  @Test func commaNotAddedInsideEmptyDictionaryLiteral() {
    let input = """
      foo = [:
      ]
      """
    let options = FormatOptions(wrapCollections: .disabled)
    testFormatting(for: input, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommaRemovedInInlineArray() {
    let input = """
      [foo,]
      """
    let output = """
      [foo]
      """
    testFormatting(for: input, output, rule: .trailingCommas)
  }

  @Test func trailingCommaNotAddedToSubscript() {
    let input = """
      foo[
          bar
      ]
      """
    testFormatting(for: input, rule: .trailingCommas)
  }

  @Test func trailingCommaNotAddedToSubscript2() {
    let input = """
      foo?[
          bar
      ]
      """
    testFormatting(for: input, rule: .trailingCommas)
  }

  @Test func trailingCommaNotAddedToSubscript3() {
    let input = """
      foo()[
          bar
      ]
      """
    testFormatting(for: input, rule: .trailingCommas)
  }

  @Test func trailingCommaNotAddedToSubscriptInsideArrayLiteral() {
    let input = """
      let array = [
          foo
              .bar[
                  0
              ]
              .baz,
      ]
      """
    testFormatting(for: input, rule: .trailingCommas)
  }

  @Test func trailingCommaAddedToArrayLiteralInsideTuple() {
    let input = """
      let arrays = ([
          foo
      ], [
          bar
      ])
      """
    let output = """
      let arrays = ([
          foo,
      ], [
          bar,
      ])
      """
    testFormatting(for: input, output, rule: .trailingCommas)
  }

  @Test func noTrailingCommaAddedToArrayLiteralInsideTuple() {
    let input = """
      let arrays = ([
          Int
      ], [
          Int
      ]).self
      """
    testFormatting(for: input, rule: .trailingCommas, exclude: [.propertyTypes])
  }

  @Test func trailingCommaNotAddedToTypeDeclaration() {
    let input = """
      var foo: [
          Int:
              String
      ]
      """
    testFormatting(for: input, rule: .trailingCommas)
  }

  @Test func trailingCommaNotAddedToTypeDeclaration2() {
    let input = """
      func foo(bar: [
          Int:
              String
      ])
      """
    testFormatting(for: input, rule: .trailingCommas)
  }

  @Test func trailingCommaNotAddedToTypeDeclaration3() {
    let input = """
      func foo() -> [
          String: String
      ]
      """
    testFormatting(for: input, rule: .trailingCommas)
  }

  @Test func trailingCommaNotAddedToTypeDeclaration4() {
    let input = """
      func foo() -> [String: [
          String: Int
      ]]
      """
    testFormatting(for: input, rule: .trailingCommas)
  }

  @Test func trailingCommaNotAddedToTypeDeclaration5() {
    let input = """
      let foo = [String: [
          String: Int
      ]]()
      """
    testFormatting(for: input, rule: .trailingCommas, exclude: [.propertyTypes])
  }

  @Test func trailingCommaNotAddedToTypeDeclaration6() {
    let input = """
      let foo = [String: [
          (Foo<[
              String
          ]>, [
              Int
          ])
      ]]()
      """
    testFormatting(for: input, rule: .trailingCommas, exclude: [.propertyTypes])
  }

  @Test func trailingCommaNotAddedToTypeDeclaration7() {
    let input = """
      func foo() -> Foo<[String: [
          String: Int
      ]]>
      """
    testFormatting(for: input, rule: .trailingCommas)
  }

  @Test func trailingCommaNotAddedToTypeDeclaration8() {
    let input = """
      extension Foo {
          var bar: [
              Int
          ] {
              fatalError()
          }
      }
      """
    testFormatting(for: input, rule: .trailingCommas)
  }

  @Test func trailingCommaNotAddedToTypealias() {
    let input = """
      typealias Foo = [
          Int
      ]
      """
    testFormatting(for: input, rule: .trailingCommas)
  }

  @Test func trailingCommaNotAddedToCaptureList() {
    let input = """
      let foo = { [
          self
      ] in }
      """
    testFormatting(for: input, rule: .trailingCommas)
  }

  @Test func trailingCommaNotAddedToCaptureListWithComment() {
    let input = """
      let foo = { [
          self // captures self
      ] in }
      """
    testFormatting(for: input, rule: .trailingCommas)
  }

  @Test func trailingCommaNotAddedToCaptureListWithMainActor() {
    let input = """
      let closure = { @MainActor [
          foo = state.foo,
          baz = state.baz
      ] _ in }
      """
    testFormatting(for: input, rule: .trailingCommas)
  }

  @Test func trailingCommaNotAddedToArrayExtension() {
    let input = """
      extension [
          Int
      ] {
          func foo() {}
      }
      """
    testFormatting(for: input, rule: .trailingCommas)
  }

  // trailingCommas = false

  @Test func commaNotAddedToLastItem() {
    let input = """
      [
          foo,
          bar
      ]
      """
    let options = FormatOptions(trailingCommas: .never)
    testFormatting(for: input, rule: .trailingCommas, options: options)
  }

  @Test func commaRemovedFromLastItem() {
    let input = """
      [
          foo,
          bar,
      ]
      """
    let output = """
      [
          foo,
          bar
      ]
      """
    let options = FormatOptions(trailingCommas: .never)
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasAddedToFunctionParameters() {
    let input = """
      struct Foo {
          func foo(
              bar: Int,
              baaz: Int
          ) -> Int {
              bar + baaz
          }
      }
      """
    let output = """
      struct Foo {
          func foo(
              bar: Int,
              baaz: Int,
          ) -> Int {
              bar + baaz
          }
      }
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasRemovedFromFunctionParametersOnUnsupportedSwiftVersion() {
    let input = """
      struct Foo {
          func foo(
              bar: Int,
              baaz: Int,
          ) -> Int {
              bar + baaz
          }
      }
      """
    let output = """
      struct Foo {
          func foo(
              bar: Int,
              baaz: Int
          ) -> Int {
              bar + baaz
          }
      }
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.0")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasAddedToGenericFunctionParameters() {
    let input = """
      struct Foo {
          func foo<
              Bar,
              Baaz
          >(
              bar: Bar,
              baaz: Baaz
          ) -> Int {
              bar + baaz
          }
      }
      """
    let output = """
      struct Foo {
          func foo<
              Bar,
              Baaz,
          >(
              bar: Bar,
              baaz: Baaz,
          ) -> Int {
              bar + baaz
          }
      }
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
    testFormatting(
      for: input, output, rule: .trailingCommas, options: options,
      exclude: [.opaqueGenericParameters])
  }

  @Test func trailingCommasNotAddedToFunctionParametersBeforeSwift6_1() {
    let input = """
      func foo(
          bar _: Int
      ) {}
      """
    let options = FormatOptions(trailingCommas: .always)
    testFormatting(for: input, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasRemovedFromFunctionParameters() {
    let input = """
      func foo(
          bar _: Int,
      ) {}
      """
    let output = """
      func foo(
          bar _: Int
      ) {}
      """
    let options = FormatOptions(trailingCommas: .never)
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasRemovedFromFunctionParametersWithParenOnSameLine_trailingCommasDisabled()
  {
    let input = """
      func foo(
          bar _: Int,
          baaz _: Int,)
      {}
      """
    let output = """
      func foo(
          bar _: Int,
          baaz _: Int)
      {}
      """
    let options = FormatOptions(trailingCommas: .never, closingParenPosition: .sameLine)
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasRemovedFromFunctionParametersWithParenOnSameLine_trailingCommasEnabled()
  {
    let input = """
      func foo(
          bar _: Int,
          baaz _: Int,)
      {}
      """
    let output = """
      func foo(
          bar _: Int,
          baaz _: Int)
      {}
      """
    let options = FormatOptions(trailingCommas: .always, closingParenPosition: .sameLine)
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasAddedToFunctionArguments() {
    let input = """
      foo(
          bar _: Int
      ) {}
      """
    let output = """
      foo(
          bar _: Int,
      ) {}
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasRemovedFromFunctionArguments() {
    let input = """
      foo(
          bar _: Int,
      ) {}
      """
    let output = """
      foo(
          bar _: Int
      ) {}
      """
    let options = FormatOptions(trailingCommas: .never)
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasAddedToEnumCaseAssociatedValue() {
    let input = """
      enum Foo {
          case bar(
              baz: String
          )
      }
      """
    let output = """
      enum Foo {
          case bar(
              baz: String,
          )
      }
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasRemovedFromEnumCaseAssociatedValue() {
    let input = """
      enum Foo {
          case bar(
              baz: String,
          )
      }
      """
    let output = """
      enum Foo {
          case bar(
              baz: String
          )
      }
      """
    let options = FormatOptions(trailingCommas: .never)
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasAddedToInitializer() {
    let input = """
      let foo: Foo = .init(
          1
      )
      """
    let output = """
      let foo: Foo = .init(
          1,
      )
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasRemovedFromInitializer() {
    let input = """
      let foo: Foo = .init(
          1,
      )
      """
    let output = """
      let foo: Foo = .init(
          1
      )
      """
    let options = FormatOptions(trailingCommas: .never)
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasAddedToTuple() {
    let input = """
      var foo = (
          bar: 0,
          baz: 1
      )

      foo = (
          bar: 1,
          baz: 2
      )
      """
    let output = """
      var foo = (
          bar: 0,
          baz: 1,
      )

      foo = (
          bar: 1,
          baz: 2,
      )
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasAddedToTupleReturnedFromFunction() {
    let input = """
      func foo() -> (bar: Int, baz: Int) {
          (
              bar: 0,
              baz: 1
          )
      }

      func bar() -> (bar: Int, baz: Int) {
          return (
              bar: 0,
              baz: 1
          )
      }
      """
    let output = """
      func foo() -> (bar: Int, baz: Int) {
          (
              bar: 0,
              baz: 1,
          )
      }

      func bar() -> (bar: Int, baz: Int) {
          return (
              bar: 0,
              baz: 1,
          )
      }
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
    testFormatting(
      for: input, output, rule: .trailingCommas, options: options, exclude: [.redundantReturn])
  }

  @Test func trailingCommasAddedToTupleInFunctionCall() {
    let input = """
      foo(
          bar: bar,
          baaz: (
              quux: quux,
              foobar: foobar
          )
      )
      """

    let output = """
      foo(
          bar: bar,
          baaz: (
              quux: quux,
              foobar: foobar,
          ),
      )
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
    testFormatting(
      for: input, output, rule: .trailingCommas, options: options, exclude: [.redundantReturn])
  }

  @Test func trailingCommasAddedToTupleInGenericInitCall() {
    let input = """
      let setModeSwizzle = Swizzle<AVAudioSession>(
          instance: instance,
          original: #selector(AVAudioSession.setMode(_:)),
          swizzled: #selector(AVAudioSession.swizzled_setMode(_:))
      )
      """

    let output = """
      let setModeSwizzle = Swizzle<AVAudioSession>(
          instance: instance,
          original: #selector(AVAudioSession.setMode(_:)),
          swizzled: #selector(AVAudioSession.swizzled_setMode(_:)),
      )
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
    testFormatting(
      for: input, output, rule: .trailingCommas, options: options,
      exclude: [.redundantReturn, .propertyTypes])
  }

  @Test func trailingCommasAddedToParensAroundSingleValue() {
    let input = """
      let foo = (
          0
      )
      """
    let output = """
      let foo = (
          0,
      )
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
    testFormatting(
      for: input, output, rule: .trailingCommas, options: options, exclude: [.redundantParens])
  }

  @Test func trailingCommasAddedToTupleWithNoArguments() {
    let input = """
      let foo = (
          0,
          1
      )
      """
    let output = """
      let foo = (
          0,
          1,
      )
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasRemovedFromTuple() {
    let input = """
      let foo = (
          bar: 0,
          baz: 1,
      )
      """
    let output = """
      let foo = (
          bar: 0,
          baz: 1
      )
      """
    let options = FormatOptions(trailingCommas: .never)
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasPreservedInTupleTypeInSwift6_1() {
    // Trailing commas are unexpectedly not supported in tuple types in Swift 6.1
    // https://github.com/swiftlang/swift/issues/81485
    let input = """
      let foo: (
          bar: String,
          quux: String // trailing comma not supported
      )
      """

    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
    testFormatting(for: input, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasPreservedInTupleTypeInSwift6_1_multiElementLists() {
    // Trailing commas are unexpectedly not supported in tuple types in Swift 6.1
    // https://github.com/swiftlang/swift/issues/81485
    let input = """
      let foo: (
          bar: String,
          quux: String // trailing comma not supported
      )
      """

    let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
    testFormatting(for: input, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasPreservedInTupleTypeInArrayInSwift6_1() {
    // Trailing commas are unexpectedly not supported in tuple types in Swift 6.1
    // https://github.com/swiftlang/swift/issues/81485
    let input = """
      let foo: [[(
          bar: String,
          quux: String // trailing comma not supported
      )]]

      let foo = [[(
          bar: String,
          quux: String // trailing comma not supported
      )]]()
      """

    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
    testFormatting(for: input, rule: .trailingCommas, options: options, exclude: [.propertyTypes])
  }

  @Test func trailingCommasPreservedInTupleTypeInGenericBracketsInSwift6_1() {
    // Trailing commas are unexpectedly not supported in tuple types in Swift 6.1
    // https://github.com/swiftlang/swift/issues/81485
    let input = """
      let foo: Array<(
          bar: String,
          quux: String // trailing comma not supported
      )>

      let foo = Array<(
          bar: String,
          quux: String // trailing comma not supported
      )>()
      """

    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
    testFormatting(
      for: input, rule: .trailingCommas, options: options, exclude: [.typeSugar, .propertyTypes])
  }

  @Test func preservesTrailingCommaInTupleFunctionArgumentInSwift6_1_issue_2050() {
    let input = """
      func updateBackgroundMusic(
          inputs _: (
              isFullyVisible: Bool,
              currentLevel: LevelsService.Level?,
              isAudioEngineRunningInForeground: Bool,
              cameraMode: EnvironmentCameraMode // <--- trailing comma does not compile
          ),
      ) {}
      """

    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
    testFormatting(for: input, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasPreservedInClosureTypeInSwift6_1() {
    // Trailing commas are unexpectedly not supported in closure types in Swift 6.1
    // https://github.com/swiftlang/swift/issues/81485
    let input = """
      let closure: (
          String,
          String // trailing comma not supported
      ) -> (
          bar: String,
          quux: String // trailing comma not supported
      )

      let closure: @Sendable (
          String,
          String // trailing comma not supported
      ) -> (
          bar: String,
          quux: String // trailing comma not supported
      )

      let closure: (
          String,
          String // trailing comma not supported
      ) async -> (
          bar: String,
          quux: String // trailing comma not supported
      )

      let closure: (
          String,
          String // trailing comma not supported
      ) async throws -> (
          bar: String,
          quux: String // trailing comma not supported
      )

      func foo(_: @escaping (
          String,
          String // trailing comma not supported
      ) -> Void) {}
      """

    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
    testFormatting(for: input, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasPreservedInClosureTypeInSwift6_1_multiElementList() {
    // Trailing commas are unexpectedly not supported in closure types in Swift 6.1
    // https://github.com/swiftlang/swift/issues/81485
    let input = """
      let closure: (
          String,
          String // trailing comma not supported
      ) -> (
          bar: String,
          quux: String // trailing comma not supported
      )

      let closure: @Sendable (
          String // trailing comma not supported
      ) -> (
          bar: String,
          quux: String // trailing comma not supported
      )
      """

    let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
    testFormatting(for: input, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasPreservedInOptionalClosureTypeInSwift6_1() {
    let input = """
      public func requestLocationAuthorizationAndAccuracy(completion _: (
          (
              _ authorizationStatus: CLAuthorizationStatus?,
              _ accuracyAuthorization: CLAccuracyAuthorization?,
              _ error: LocationServiceError?
          ) -> Void
      )?) {}
      """

    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
    testFormatting(for: input, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasPreservedInClosureTupleTypealiasesInSwift6_1() {
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

    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
    testFormatting(for: input, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasAddedToReturnTuple() {
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
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasRemovedFromReturnTuple() {
    let input = """
      func foo() -> (Int, Int) {
          let bar = 0
          let baz = 1

          return (
              bar,
              baz,
          )
      }
      """
    let output = """
      func foo() -> (Int, Int) {
          let bar = 0
          let baz = 1

          return (
              bar,
              baz
          )
      }
      """
    let options = FormatOptions(trailingCommas: .never)
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasAddedToThrow() {
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
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasRemovedFromThrow() {
    let input = """
      enum FooError: Error {
          case bar
      }

      func baz() throws {
          throw (
              FooError.bar,
          )
      }
      """
    let output = """
      enum FooError: Error {
          case bar
      }

      func baz() throws {
          throw (
              FooError.bar
          )
      }
      """
    let options = FormatOptions(trailingCommas: .never)
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasAddedToSwitch() {
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
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasNotAddedToTypeAnnotation() {
    let input = """
      let foo: (
          bar: Int,
          baz: Int
      )
      """
    let options = FormatOptions(trailingCommas: .never)
    testFormatting(for: input, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasRemovedFromCaseLet() {
    let input = """
      let foo = (0, 1)
      switch foo {
      case let (
          bar,
          baz,
      ): break
      }
      """
    let output = """
      let foo = (0, 1)
      switch foo {
      case let (
          bar,
          baz
      ): break
      }
      """
    let options = FormatOptions(trailingCommas: .never)
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommaRemovedFromDestructuringLetTuple() {
    let input = """
      let (
          foo,
          bar,
      ) = (0, 1)
      """
    let output = """
      let (
          foo,
          bar
      ) = (0, 1)
      """
    let options = FormatOptions(trailingCommas: .never)
    testFormatting(
      for: input, output, rule: .trailingCommas, options: options, exclude: [.singlePropertyPerLine]
    )
  }

  @Test func trailingCommasNotAddedToEmptyParentheses() {
    let input = """
      let foo = (

      )
      """
    let options = FormatOptions(trailingCommas: .never)
    testFormatting(
      for: input, rule: .trailingCommas,
      options: options,
      exclude: [
        .blankLinesAtEndOfScope,
        .blankLinesAtStartOfScope,
      ])
  }

  @Test func trailingCommasRemovedFromStringInterpolation() {
    let input = """
      let foo = \"""
      Foo: \\(
          1,
          2,
      )
      \"""
      """
    let output = """
      let foo = \"""
      Foo: \\(
          1,
          2
      )
      \"""
      """
    let options = FormatOptions(trailingCommas: .never)
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasAddedToAttribute() {
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
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasNotAddedToBuiltInAttributesInSwift6_1() {
    // Built-in attributes unexpectedly don't support trailing commas in Swift 6.1.
    // Property wrappers and macros are supported properly.
    // https://github.com/swiftlang/swift/issues/81475
    let input = """
      @available(
          *,
          deprecated,
          renamed: "bar"
      )
      func foo() {}

      @backDeployed(
          before: iOS 17 // trailing comma not allowed
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

    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
    testFormatting(for: input, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasNotAddedToBuiltInAttributesInSwift6_1_multiElementList() {
    // Built-in attributes unexpectedly don't support trailing commas in Swift 6.1.
    // Property wrappers and macros are supported properly.
    // https://github.com/swiftlang/swift/issues/81475
    let input = """
      @available(
          *,
          deprecated,
          renamed: "bar"
      )
      func foo() {}

      @objc(
          custom_objc_name
      )
      class MyClass: NSObject()
      """

    let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
    testFormatting(for: input, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasRemovedFromAttribute() {
    let input = """
      @Foo(
          "bar",
          "baz",
      )
      struct Qux {}
      """
    let output = """
      @Foo(
          "bar",
          "baz"
      )
      struct Qux {}
      """
    let options = FormatOptions(trailingCommas: .never)
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasAddedToMacro() {
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
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasRemovedFromMacro() {
    let input = """
      #foo(
          "bar",
          "baz",
      )
      """
    let output = """
      #foo(
          "bar",
          "baz"
      )
      """
    let options = FormatOptions(trailingCommas: .never)
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasAddedToGenericList() {
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
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasNotAddedToGenericTypesInSwift6_1() {
    // Trailing commas are not supported in types in Swift 6.1
    // https://github.com/swiftlang/swift/issues/81474
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

    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
    testFormatting(
      for: input, rule: .trailingCommas, options: options, exclude: [.emptyExtensions, .typeSugar])
  }

  @Test func trailingCommasRemovedFromGenericList() {
    let input = """
      struct S<
          T1,
          T2,
          T3,
      > {}
      """
    let output = """
      struct S<
          T1,
          T2,
          T3
      > {}
      """
    let options = FormatOptions(trailingCommas: .never)
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasRemovedFromSingleLineGenericList() {
    let input = """
      struct S<T1, T2, T3,> {}
      """
    let output = """
      struct S<T1, T2, T3> {}
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasAddedToCaptureList() {
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
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasRemovedFromSingleElementCaptureList() {
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
    let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasRemovedFromCaptureList() {
    let input = """
      { [
          capturedValue1,
          capturedValue2,
      ] in
      }
      """
    let output = """
      { [
          capturedValue1,
          capturedValue2
      ] in
      }
      """
    let options = FormatOptions(trailingCommas: .never)
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasRemovedFromSingleLineCaptureList() {
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
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasAddedToSubscript() {
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
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasRemoveFromSubscriptWhenCollectionsOnly() {
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
    let options = FormatOptions(trailingCommas: .collectionsOnly, swiftVersion: "6.1")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasRemovedFromSubscript() {
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
    let options = FormatOptions(trailingCommas: .never)
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasRemovedFromSingleLineSubscript() {
    let input = """
      let value = m[x, y,]
      """
    let output = """
      let value = m[x, y]
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func addingTrailingCommaDoesntConflictWithOpaqueGenericParametersRule() {
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

    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func singleLineArrayWithMultipleElements() {
    let input = """
      for file in files where
          file != "build" && !file.hasPrefix(".") && ![
              ".build", ".app", ".framework", ".xcodeproj", ".xcassets",
          ].contains(where: { file.hasSuffix($0) }) {}
      """

    let options = FormatOptions(trailingCommas: .always)
    testFormatting(for: input, rule: .trailingCommas, options: options)
  }

  @Test func singleLineArrayWithMultipleElementsFollowingNotOperator() {
    let input = """
      for file in files where
          file != "build" && !file.hasPrefix(".") && ![
              ".build", ".app", ".framework", ".xcodeproj", ".xcassets",
          ].contains(where: { file.hasSuffix($0) }) {}
      """

    let options = FormatOptions(trailingCommas: .always)
    testFormatting(for: input, rule: .trailingCommas, options: options)
  }

  @Test func singleLineArrayWithMultipleElementsFollowingForceTry() {
    let input = """
      let foo = try! [
          ".build", ".app", ".framework", ".xcodeproj", ".xcassets",
      ].throwingOperation()

      let bar = try? [
          ".build", ".app", ".framework", ".xcodeproj", ".xcassets",
      ].throwingOperation()
      """

    let options = FormatOptions(trailingCommas: .always)
    testFormatting(for: input, rule: .trailingCommas, options: options)
  }

  @Test func collectionsOnlyAddsCollectionCommasAndRemovesNonCollectionCommas() {
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
    let options = FormatOptions(trailingCommas: .collectionsOnly, swiftVersion: "6.1")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasNotRemovedFromInitParametersWithAlwaysOption() {
    let input = """
      public init(
          parameter: Parameter,
      ) {
          // test
      }
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
    testFormatting(for: input, rule: .trailingCommas, options: options, exclude: [.unusedArguments])
  }

  @Test func trailingCommasAddedToInitParametersWithAlwaysOption() {
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
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
    testFormatting(
      for: input, output, rule: .trailingCommas, options: options, exclude: [.unusedArguments])
  }

  // MARK: - Multi-element lists tests

  @Test func multiElementListsAddsCommaToMultiElementArray() {
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
    let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func multiElementListsDoesNotAddCommaToSingleElementArray() {
    let input = """
      let array = [
          1
      ]
      """
    let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
    testFormatting(for: input, rule: .trailingCommas, options: options)
  }

  @Test func multiElementListsAddsCommaToMultiElementFunction() {
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
    let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func multiElementListsDoesNotAddCommaToSingleElementFunction() {
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
    let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
    testFormatting(for: input, rule: .trailingCommas, options: options)
  }

  @Test func multiElementListsAddsCommaToMultiElementFunctionCall() {
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
    let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func multiElementListsDoesNotAddCommaToSingleElementFunctionCall() {
    let input = """
      foo(
          a: 1
      )
      """
    let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
    testFormatting(for: input, rule: .trailingCommas, options: options)
  }

  @Test func multiElementListsAddsCommaToMultiElementGenericList() {
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
    let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func multiElementListsDoesNotAddCommaToSingleElementGenericList() {
    let input = """
      struct Foo<
          T
      > {}
      """
    let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
    testFormatting(for: input, rule: .trailingCommas, options: options)
  }

  @Test func multiElementListsRemovesCommaFromSingleElementArray() {
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
    let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func multiElementListsRemovesCommaFromSingleElementFunction() {
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
    let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func multiElementListsRemovesCommaFromSingleElementInit() {
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
    let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func multiElementListsAddCommaToInit() {
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
    let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommaNotRemovedFromTupleAndClosureTypesSwift6_1() {
    let input = """
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
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
    testFormatting(for: input, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommaNotAddedToTupleAndClosureTypesSwift6_1() {
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
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
    testFormatting(for: input, rule: .trailingCommas, options: options)
  }

  @Test func multiElementListsTrailingCommaNotRemovedFromClosureTypeSwift6_1() {
    let input = """
      let foo: (
          bar: String,
      ) -> Void

      let foo: (
          bar: String,
          baaz: String,
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
    let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func multiElementListsTrailingCommaNotAddedToTupleAndClosureTypesSwift6_1() {
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
    let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
    testFormatting(for: input, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasAddedToOptionalClosureCall() {
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
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasRemovedFromOptionalClosureCall() {
    let input = """
      myClosure!(
          foo: 5,
          bar: 10,
      )
      """
    let output = """
      myClosure!(
          foo: 5,
          bar: 10
      )
      """
    let options = FormatOptions(trailingCommas: .never)
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasAddedToOptionalClosureCallSingleParameter() {
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
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasMultiElementListsOptionalClosureCall() {
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
    let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.1")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasInTupleTypeCastNotRemovedSwift6_1() {
    // Unexpectedly not supported in Swift 6.1
    let input = """
      let foo = bar as? (
          Foo,
          Bar
      )
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
    testFormatting(for: input, rule: .trailingCommas, options: options)
  }

  @Test func issue2142() {
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
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
    testFormatting(for: input, rule: .trailingCommas, options: options, exclude: [.propertyTypes])
  }

  @Test func issue2143() {
    let input = """
      public @Test func closureArgumentInTuple() {
          _ = object.methodWithTupleArgument((
              closureArgument: { capturedObject in
                  _ = capturedObject
              },
          ))
      }
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.1")
    testFormatting(for: input, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasAddedToFunctionParametersSwift6_2() {
    let input = """
      struct Foo {
          func foo(
              bar: Int,
              baaz: Int
          ) -> Int {
              bar + baaz
          }
      }
      """
    let output = """
      struct Foo {
          func foo(
              bar: Int,
              baaz: Int,
          ) -> Int {
              bar + baaz
          }
      }
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasAddedToGenericFunctionParametersSwift6_2() {
    let input = """
      struct Foo {
          func foo<
              Bar,
              Baaz
          >(
              bar: Bar,
              baaz: Baaz
          ) -> Int {
              bar + baaz
          }
      }
      """
    let output = """
      struct Foo {
          func foo<
              Bar,
              Baaz,
          >(
              bar: Bar,
              baaz: Baaz,
          ) -> Int {
              bar + baaz
          }
      }
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
    testFormatting(
      for: input, output, rule: .trailingCommas, options: options,
      exclude: [.opaqueGenericParameters])
  }

  @Test func trailingCommasAddedToFunctionArgumentsSwift6_2() {
    let input = """
      foo(
          bar _: Int
      ) {}
      """
    let output = """
      foo(
          bar _: Int,
      ) {}
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasAddedToEnumCaseAssociatedValueSwift6_2() {
    let input = """
      enum Foo {
          case bar(
              baz: String
          )
      }
      """
    let output = """
      enum Foo {
          case bar(
              baz: String,
          )
      }
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasAddedToInitializerSwift6_2() {
    let input = """
      let foo: Foo = .init(
          1
      )
      """
    let output = """
      let foo: Foo = .init(
          1,
      )
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasAddedToTupleSwift6_2() {
    let input = """
      var foo = (
          bar: 0,
          baz: 1
      )

      foo = (
          bar: 1,
          baz: 2
      )
      """
    let output = """
      var foo = (
          bar: 0,
          baz: 1,
      )

      foo = (
          bar: 1,
          baz: 2,
      )
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasAddedToTupleReturnedFromFunctionSwift6_2() {
    let input = """
      func foo() -> (bar: Int, baz: Int) {
          (
              bar: 0,
              baz: 1
          )
      }

      func bar() -> (bar: Int, baz: Int) {
          return (
              bar: 0,
              baz: 1
          )
      }
      """
    let output = """
      func foo() -> (bar: Int, baz: Int) {
          (
              bar: 0,
              baz: 1,
          )
      }

      func bar() -> (bar: Int, baz: Int) {
          return (
              bar: 0,
              baz: 1,
          )
      }
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
    testFormatting(
      for: input, output, rule: .trailingCommas, options: options, exclude: [.redundantReturn])
  }

  @Test func trailingCommasAddedToTupleInFunctionCallSwift6_2() {
    let input = """
      foo(
          bar: bar,
          baaz: (
              quux: quux,
              foobar: foobar
          )
      )
      """

    let output = """
      foo(
          bar: bar,
          baaz: (
              quux: quux,
              foobar: foobar,
          ),
      )
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
    testFormatting(
      for: input, output, rule: .trailingCommas, options: options, exclude: [.redundantReturn])
  }

  @Test func trailingCommasAddedToTupleInGenericInitCallSwift6_2() {
    let input = """
      let setModeSwizzle = Swizzle<AVAudioSession>(
          instance: instance,
          original: #selector(AVAudioSession.setMode(_:)),
          swizzled: #selector(AVAudioSession.swizzled_setMode(_:))
      )
      """

    let output = """
      let setModeSwizzle = Swizzle<AVAudioSession>(
          instance: instance,
          original: #selector(AVAudioSession.setMode(_:)),
          swizzled: #selector(AVAudioSession.swizzled_setMode(_:)),
      )
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
    testFormatting(
      for: input, output, rule: .trailingCommas, options: options,
      exclude: [.redundantReturn, .propertyTypes])
  }

  @Test func trailingCommasAddedToParensAroundSingleValueSwift6_2() {
    let input = """
      let foo = (
          0
      )
      """

    let output = """
      let foo = (
          0,
      )
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
    testFormatting(
      for: input, output, rule: .trailingCommas, options: options, exclude: [.redundantParens])
  }

  @Test func trailingCommasAddedToTupleWithNoArgumentsSwift6_2() {
    let input = """
      let foo = (
          0,
          1
      )
      """
    let output = """
      let foo = (
          0,
          1,
      )
      """
    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasAddedToTupleTypesInSwift6_2() {
    // Trailing commas are now supported in tuple types in Swift 6.2
    let input = """
      let foo: (
          bar: String,
          quux: String
      )
      """
    let output = """
      let foo: (
          bar: String,
          quux: String,
      )
      """

    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasAddedToTupleTypesInSwift6_2_multiElementLists() {
    // Trailing commas are now supported in tuple types in Swift 6.2
    let input = """
      let foo: (
          bar: String,
          quux: String
      )
      """
    let output = """
      let foo: (
          bar: String,
          quux: String,
      )
      """

    let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.2")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasAddedToTupleTypeInArrayInSwift6_2() {
    // Trailing commas are now supported in tuple types in Swift 6.2
    let input = """
      let foo: [[(
          bar: String,
          quux: String
      )]]

      let foo = [[(
          bar: String,
          quux: String
      )]]()
      """
    let output = """
      let foo: [[(
          bar: String,
          quux: String,
      )]]

      let foo = [[(
          bar: String,
          quux: String,
      )]]()
      """

    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
    testFormatting(
      for: input, output, rule: .trailingCommas, options: options, exclude: [.propertyTypes])
  }

  @Test func trailingCommasNotAddedToTupleTypeInGenericBracketsInSwift6_2() {
    // In Swift 6.2, trailing commas are unexpectedly not supported in tuple types
    // within generic arguments: https://github.com/swiftlang/swift-syntax/pull/3153
    let input = """
      let foo: Array<(
          bar: String,
          quux: String
      )>
      """

    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
    testFormatting(
      for: input, rule: .trailingCommas, options: options, exclude: [.typeSugar, .propertyTypes])
  }

  @Test func trailingCommasAddedToTupleTypeInGenericBracketsInSwift6_3() {
    let input = """
      let foo: Array<(
          bar: String,
          quux: String
      )>
      """

    let output = """
      let foo: Array<(
          bar: String,
          quux: String,
      )>
      """

    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.3")
    testFormatting(
      for: input, output, rule: .trailingCommas, options: options,
      exclude: [.typeSugar, .propertyTypes])
  }

  @Test func trailingCommasNotAddedToClosureTupleReturnType() {
    // Trailing commas are unexpectedly not allowed here in Swift 6.2
    let input = """
      let closure = { () -> (
          foo: String,
          bar: String
      ) in
          (foo: "foo", bar: "bar")
      }

      func foo() -> (
          foo: String,
          bar: String
      ) {
          (foo: "foo", bar: "bar")
      }
      """

    let output = """
      let closure = { () -> (
          foo: String,
          bar: String
      ) in
          (foo: "foo", bar: "bar")
      }

      func foo() -> (
          foo: String,
          bar: String,
      ) {
          (foo: "foo", bar: "bar")
      }
      """

    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
    testFormatting(
      for: input, output, rule: .trailingCommas, options: options,
      exclude: [.typeSugar, .propertyTypes])
  }

  @Test func trailingCommasAddedToClosureTupleReturnTypeSwift6_3() {
    let input = """
      let closure = { () -> (
          foo: String,
          bar: String
      ) in
          (foo: "foo", bar: "bar")
      }

      func foo() -> (
          foo: String,
          bar: String
      ) {
          (foo: "foo", bar: "bar")
      }
      """

    let output = """
      let closure = { () -> (
          foo: String,
          bar: String,
      ) in
          (foo: "foo", bar: "bar")
      }

      func foo() -> (
          foo: String,
          bar: String,
      ) {
          (foo: "foo", bar: "bar")
      }
      """

    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.3")
    testFormatting(
      for: input, output, rule: .trailingCommas, options: options,
      exclude: [.typeSugar, .propertyTypes])
  }

  @Test func trailingCommasAddedToTupleFunctionArgumentInSwift6_2() {
    let input = """
      func updateBackgroundMusic(
          inputs _: (
              isFullyVisible: Bool,
              currentLevel: LevelsService.Level?,
              isAudioEngineRunningInForeground: Bool,
              cameraMode: EnvironmentCameraMode
          ),
      ) {}
      """
    let output = """
      func updateBackgroundMusic(
          inputs _: (
              isFullyVisible: Bool,
              currentLevel: LevelsService.Level?,
              isAudioEngineRunningInForeground: Bool,
              cameraMode: EnvironmentCameraMode,
          ),
      ) {}
      """

    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasAddedToClosureTypeInSwift6_2() {
    // Trailing commas are now supported in closure types in Swift 6.2
    let input = """
      let closure: (
          String,
          String
      ) -> (
          bar: String,
          quux: String
      )

      let closure: @Sendable (
          String,
          String
      ) -> (
          bar: String,
          quux: String
      )

      let closure: (
          String,
          String
      ) async -> (
          bar: String,
          quux: String
      )

      let closure: (
          String,
          String
      ) async throws -> (
          bar: String,
          quux: String
      )

      func foo(_: @escaping (
          String,
          String
      ) -> Void) {}
      """
    let output = """
      let closure: (
          String,
          String,
      ) -> (
          bar: String,
          quux: String,
      )

      let closure: @Sendable (
          String,
          String,
      ) -> (
          bar: String,
          quux: String,
      )

      let closure: (
          String,
          String,
      ) async -> (
          bar: String,
          quux: String,
      )

      let closure: (
          String,
          String,
      ) async throws -> (
          bar: String,
          quux: String,
      )

      func foo(_: @escaping (
          String,
          String,
      ) -> Void) {}
      """

    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasAddedToClosureTypeInSwift6_2_multiElementList() {
    // Trailing commas are now supported in closure types in Swift 6.2
    let input = """
      let closure: (
          String,
          String
      ) -> (
          bar: String,
          quux: String
      )

      let closure: @Sendable (
          String
      ) -> (
          bar: String,
          quux: String
      )
      """
    let output = """
      let closure: (
          String,
          String,
      ) -> (
          bar: String,
          quux: String,
      )

      let closure: @Sendable (
          String
      ) -> (
          bar: String,
          quux: String,
      )
      """

    let options = FormatOptions(trailingCommas: .multiElementLists, swiftVersion: "6.2")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

  @Test func trailingCommasAddedToOptionalClosureTypeInSwift6_2() {
    let input = """
      public func requestLocationAuthorizationAndAccuracy(completion _: (
          (
              _ authorizationStatus: CLAuthorizationStatus?,
              _ accuracyAuthorization: CLAccuracyAuthorization?,
              _ error: LocationServiceError?
          ) -> Void
      )?) {}
      """
    let output = """
      public func requestLocationAuthorizationAndAccuracy(completion _: (
          (
              _ authorizationStatus: CLAuthorizationStatus?,
              _ accuracyAuthorization: CLAccuracyAuthorization?,
              _ error: LocationServiceError?,
          ) -> Void
      )?) {}
      """

    let options = FormatOptions(trailingCommas: .always, swiftVersion: "6.2")
    testFormatting(for: input, output, rule: .trailingCommas, options: options)
  }

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
      exclude: [.emptyExtensions, .typeSugar])
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

  @Test func addingTrailingCommaDoesntConflictWithOpaqueGenericParametersRuleSwift6_2() {
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
    testFormatting(for: input, rule: .trailingCommas, options: options, exclude: [.unusedArguments])
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
      for: input, output, rule: .trailingCommas, options: options, exclude: [.unusedArguments])
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
    testFormatting(for: input, rule: .trailingCommas, options: options, exclude: [.propertyTypes])
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
