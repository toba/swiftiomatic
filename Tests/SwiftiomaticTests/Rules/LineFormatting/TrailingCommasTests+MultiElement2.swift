import Testing

@testable import Swiftiomatic

extension TrailingCommasTests {
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
      for: input, output, rule: .trailingCommas, options: options,
    )
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
      for: input, output, rule: .trailingCommas, options: options,
    )
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
      exclude: [.propertyTypes],
    )
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
      for: input, output, rule: .trailingCommas, options: options,
      exclude: [.redundantParens],
    )
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
      for: input, output, rule: .trailingCommas, options: options, exclude: [.propertyTypes],
    )
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
      for: input, rule: .trailingCommas, options: options,
      exclude: [
        .typeSugar,
        .propertyTypes,
      ],
    )
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
      exclude: [.typeSugar, .propertyTypes],
    )
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
      exclude: [.typeSugar, .propertyTypes],
    )
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
      exclude: [.typeSugar, .propertyTypes],
    )
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

}
