import Testing

@testable import Swiftiomatic

@Suite struct RedundantOptionalBindingTests {
  @Test func removesRedundantOptionalBindingsInSwift5_7() {
    let input = """
      if let foo = foo {
          print(foo)
      }

      else if var bar = bar {
          print(bar)
      }

      guard let self = self else {
          return
      }

      while var quux = quux {
          break
      }
      """

    let output = """
      if let foo {
          print(foo)
      }

      else if var bar {
          print(bar)
      }

      guard let self else {
          return
      }

      while var quux {
          break
      }
      """

    let options = FormatOptions(swiftVersion: "5.7")
    testFormatting(
      for: input, output, rule: .redundantOptionalBinding, options: options,
      exclude: [.elseOnSameLine])
  }

  @Test func removesMultipleOptionalBindings() {
    let input = """
      if let foo = foo, let bar = bar, let baaz = baaz {
          print(foo, bar, baaz)
      }

      guard let foo = foo, let bar = bar, let baaz = baaz else {
          return
      }
      """

    let output = """
      if let foo, let bar, let baaz {
          print(foo, bar, baaz)
      }

      guard let foo, let bar, let baaz else {
          return
      }
      """

    let options = FormatOptions(swiftVersion: "5.7")
    testFormatting(for: input, output, rule: .redundantOptionalBinding, options: options)
  }

  @Test func removesMultipleOptionalBindingsOnSeparateLines() {
    let input = """
      if
        let foo = foo,
        let bar = bar,
        let baaz = baaz
      {
        print(foo, bar, baaz)
      }

      guard
        let foo = foo,
        let bar = bar,
        let baaz = baaz
      else {
        return
      }
      """

    let output = """
      if
        let foo,
        let bar,
        let baaz
      {
        print(foo, bar, baaz)
      }

      guard
        let foo,
        let bar,
        let baaz
      else {
        return
      }
      """

    let options = FormatOptions(indent: "  ", swiftVersion: "5.7")
    testFormatting(for: input, output, rule: .redundantOptionalBinding, options: options)
  }

  @Test func keepsRedundantOptionalBeforeSwift5_7() {
    let input = """
      if let foo = foo {
          print(foo)
      }
      """

    let options = FormatOptions(swiftVersion: "5.6")
    testFormatting(for: input, rule: .redundantOptionalBinding, options: options)
  }

  @Test func keepsNonRedundantOptional() {
    let input = """
      if let foo = bar {
          print(foo)
      }
      """

    let options = FormatOptions(swiftVersion: "5.7")
    testFormatting(for: input, rule: .redundantOptionalBinding, options: options)
  }

  @Test func keepsOptionalNotEligibleForShorthand() {
    let input = """
      if let foo = self.foo, let bar = bar(), let baaz = baaz[0] {
          print(foo, bar, baaz)
      }
      """

    let options = FormatOptions(swiftVersion: "5.7")
    testFormatting(
      for: input, rule: .redundantOptionalBinding, options: options, exclude: [.redundantSelf])
  }

  @Test func redundantSelfAndRedundantOptionalTogether() {
    let input = """
      if let foo = self.foo {
          print(foo)
      }
      """

    let output = """
      if let foo {
          print(foo)
      }
      """

    let options = FormatOptions(swiftVersion: "5.7")
    testFormatting(
      for: input, [output], rules: [.redundantOptionalBinding, .redundantSelf], options: options)
  }

  @Test func doesntRemoveShadowingOutsideOfOptionalBinding() {
    let input = """
      let foo = foo

      if let bar = baaz({
          let foo = foo
          print(foo)
      }) {}
      """

    let options = FormatOptions(swiftVersion: "5.7")
    testFormatting(for: input, rule: .redundantOptionalBinding, options: options)
  }
}
