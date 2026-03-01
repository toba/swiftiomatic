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
      exclude: [.opaqueGenericParameters],
    )
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
      for: input, output, rule: .trailingCommas, options: options,
    )
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
      for: input, output, rule: .trailingCommas, options: options,
    )
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
      exclude: [.propertyTypes],
    )
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
      for: input, output, rule: .trailingCommas, options: options,
      exclude: [.redundantParens],
    )
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
    testFormatting(
      for: input,
      rule: .trailingCommas,
      options: options,
      exclude: [.propertyTypes],
    )
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
      for: input, rule: .trailingCommas, options: options,
      exclude: [
        .typeSugar,
        .propertyTypes,
      ],
    )
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

}
