import Testing

@testable import Swiftiomatic

extension OrganizeDeclarationsTests {
  @Test func organizeDeclarationsContainingNonisolated() {
    let input = """
      public class Test {
          public static func test1() {}

          private nonisolated(unsafe) static var test3: ((
              _ arg1: Bool,
              _ arg2: Int
          ) -> Bool)?

          static func test2() {}
      }
      """
    let output = """
      public class Test {

          // MARK: Public

          public static func test1() {}

          // MARK: Internal

          static func test2() {}

          // MARK: Private

          private nonisolated(unsafe) static var test3: ((
              _ arg1: Bool,
              _ arg2: Int
          ) -> Bool)?

      }
      """
    testFormatting(
      for: input, output, rule: .organizeDeclarations,
      exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope],
    )
  }

  @Test func sortStructPropertiesWithAttributes() {
    let input = """
      // sm:sort
      struct BookReaderView {
        @Namespace private var animation
        @State private var animationContent: Bool = false
        @State private var offsetY: CGFloat = 0
        @Bindable var model: Book
        @Query(
          filter: #Predicate<TextContent> { $0.progress_ < 1 },
          sort: \\.updatedAt_,
          order: .reverse
        ) private var incompleteTextContents: [TextContent]
      }
      """
    let output = """
      // sm:sort
      struct BookReaderView {

        // MARK: Internal

        @Bindable var model: Book

        // MARK: Private

        @Namespace private var animation
        @State private var animationContent: Bool = false
        @Query(
          filter: #Predicate<TextContent> { $0.progress_ < 1 },
          sort: \\.updatedAt_,
          order: .reverse
        ) private var incompleteTextContents: [TextContent]
        @State private var offsetY: CGFloat = 0
      }
      """
    let options = FormatOptions(indent: "  ", organizeTypes: ["struct"])
    testFormatting(
      for: input, output, rule: .organizeDeclarations,
      options: options, exclude: [.blankLinesAtStartOfScope],
    )
  }

  @Test func sortSingleSwiftUIPropertyWrapper() {
    let input = """
      struct ContentView: View {

          init(label: String) {
              self.label = label
          }

          private var label: String

          @State
          private var isOn: Bool = false

          private var foo = true

          @ViewBuilder
          private var toggle: some View {
              Toggle(label, isOn: $isOn)
          }

          @ViewBuilder
          var body: some View {
              toggle
          }
      }
      """

    let output = """
      struct ContentView: View {

          // MARK: Lifecycle

          init(label: String) {
              self.label = label
          }

          // MARK: Internal

          @ViewBuilder
          var body: some View {
              toggle
          }

          // MARK: Private

          @State
          private var isOn: Bool = false

          private var label: String

          private var foo = true

          @ViewBuilder
          private var toggle: some View {
              Toggle(label, isOn: $isOn)
          }

      }
      """

    testFormatting(
      for: input, output,
      rule: .organizeDeclarations,
      options: FormatOptions(organizeTypes: ["struct"], organizationMode: .visibility),
      exclude: [
        .blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .privateStateVariables,
        .redundantViewBuilder,
      ],
    )
  }

  @Test func sortMultipleSwiftUIPropertyWrappers() {
    let input = """
      struct ContentView: View {

          init(foo: Foo, baaz: Baaz) {
              self.foo = foo
              self.baaz = baaz
          }

          let foo: Foo
          @State var bar = true
          let baaz: Baaz
          @State var quux = true

          @ViewBuilder
          private var toggle: some View {
              Toggle(label, isOn: $isOn)
          }

          @ViewBuilder
          var body: some View {
              toggle
          }
      }
      """

    let output = """
      struct ContentView: View {

          // MARK: Lifecycle

          init(foo: Foo, baaz: Baaz) {
              self.foo = foo
              self.baaz = baaz
          }

          // MARK: Internal

          @State var bar = true
          @State var quux = true

          let foo: Foo
          let baaz: Baaz

          @ViewBuilder
          var body: some View {
              toggle
          }

          // MARK: Private

          @ViewBuilder
          private var toggle: some View {
              Toggle(label, isOn: $isOn)
          }

      }
      """

    testFormatting(
      for: input, output,
      rule: .organizeDeclarations,
      options: FormatOptions(organizeTypes: ["struct"], organizationMode: .visibility),
      exclude: [
        .blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .privateStateVariables,
        .redundantMemberwiseInit, .redundantViewBuilder,
      ],
    )
  }

  @Test func sortSwiftUIPropertyWrappersWithDifferentVisibility() {
    let input = """
      struct ContentView: View {

          init(foo: Foo, baaz: Baaz, isOn: Binding<Bool>) {
              self.foo = foo
              self.baaz = baaz
              self_.isOn = isOn
          }

          let foo: Foo
          @State private var bar = 0
          private let baaz: Baaz
          @Binding var isOn: Bool

          @ViewBuilder
          private var toggle: some View {
              Toggle(label, isOn: $isOn)
          }

          @ViewBuilder
          var body: some View {
              toggle
          }
      }
      """

    let output = """
      struct ContentView: View {

          // MARK: Lifecycle

          init(foo: Foo, baaz: Baaz, isOn: Binding<Bool>) {
              self.foo = foo
              self.baaz = baaz
              self_.isOn = isOn
          }

          // MARK: Internal

          @Binding var isOn: Bool

          let foo: Foo

          @ViewBuilder
          var body: some View {
              toggle
          }

          // MARK: Private

          @State private var bar = 0

          private let baaz: Baaz

          @ViewBuilder
          private var toggle: some View {
              Toggle(label, isOn: $isOn)
          }

      }
      """

    testFormatting(
      for: input, output,
      rule: .organizeDeclarations,
      options: FormatOptions(organizeTypes: ["struct"], organizationMode: .visibility),
      exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .redundantViewBuilder],
    )
  }

  @Test func sortSwiftUIPropertyWrappersWithArguments() {
    let input = """
      struct ContentView: View {

          init(foo: Foo, baaz: Baaz) {
              self.foo = foo
              self.baaz = baaz
          }

          let foo: Foo
          @Environment(\\.colorScheme) var colorScheme
          let baaz: Baaz
          @Environment(\\.quux) let quux: Quux

          @ViewBuilder
          private var toggle: some View {
              Toggle(label, isOn: $isOn)
          }

          @ViewBuilder
          var body: some View {
              toggle
          }
      }
      """

    let output = """
      struct ContentView: View {

          // MARK: Lifecycle

          init(foo: Foo, baaz: Baaz) {
              self.foo = foo
              self.baaz = baaz
          }

          // MARK: Internal

          @Environment(\\.colorScheme) var colorScheme
          @Environment(\\.quux) let quux: Quux

          let foo: Foo
          let baaz: Baaz

          @ViewBuilder
          var body: some View {
              toggle
          }

          // MARK: Private

          @ViewBuilder
          private var toggle: some View {
              Toggle(label, isOn: $isOn)
          }

      }
      """

    testFormatting(
      for: input, output,
      rule: .organizeDeclarations,
      options: FormatOptions(organizeTypes: ["struct"], organizationMode: .visibility),
      exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .redundantViewBuilder],
    )
  }

  @Test func doesNotAddUnexpectedBlankLinesDueToBlankLinesWithSpaces() {
    // The blank lines in this input code are indented with four spaces.
    // Done using string interpolation in the input code to make this
    // more clear, and to prevent the spaces from being removed automatically.
    let input = """
      public class TestClass {
          var variable01 = 1
          var variable02 = 2
          var variable03 = 3
          var variable04 = 4
          var variable05 = 5
      \("    ")
          public func foo() {}
      \("    ")
          func bar() {}
      \("    ")
          private func baz() {}
      }
      """

    let output = """
      public class TestClass {

          // MARK: Public

          public func foo() {}
      \("    ")
          // MARK: Internal

          var variable01 = 1
          var variable02 = 2
          var variable03 = 3
          var variable04 = 4
          var variable05 = 5
      \("    ")
          func bar() {}
      \("    ")
          // MARK: Private

          private func baz() {}
      }
      """

    testFormatting(
      for: input, output,
      rule: .organizeDeclarations,
      exclude: [
        .blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .consecutiveBlankLines,
        .trailingSpace,
        .consecutiveSpaces, .indent,
      ],
    )
  }

  @Test func sortSwiftUIPropertyWrappersSubCategoryAlphabetically() {
    let input = """
      struct ContentView: View {
          init() {}

          @Environment(\\.colorScheme) var colorScheme
          @State var foo: Foo
          @Binding var isOn: Bool
          @Environment(\\.quux) var quux: Quux
          @Bindable var model: MyModel

          @ViewBuilder
          var body: some View {
              Toggle(label, isOn: $isOn)
          }
      }
      """

    let output = """
      struct ContentView: View {

          // MARK: Lifecycle

          init() {}

          // MARK: Internal

          @Bindable var model: MyModel
          @Binding var isOn: Bool
          @Environment(\\.colorScheme) var colorScheme
          @Environment(\\.quux) var quux: Quux
          @State var foo: Foo

          @ViewBuilder
          var body: some View {
              Toggle(label, isOn: $isOn)
          }
      }
      """

    testFormatting(
      for: input, output,
      rule: .organizeDeclarations,
      options: FormatOptions(
        organizeTypes: ["struct"],
        organizationMode: .visibility,
        blankLineAfterSubgroups: false,
        swiftUIPropertiesSortMode: .alphabetize,
      ),
      exclude: [
        .blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .privateStateVariables,
        .redundantViewBuilder,
      ],
    )
  }

  @Test func sortSwiftUIWrappersByTypeAndMaintainGroupSpacingAlphabetically() {
    let input = """
      struct ContentView: View {
          init() {}

          @State var foo: Foo
          @State var bar: Bar

          @Environment(\\.colorScheme) var colorScheme
          @Environment(\\.quux) var quux: Quux

          @Binding var isOn: Bool

          @ViewBuilder
          var body: some View {
              Toggle(label, isOn: $isOn)
          }
      }
      """

    let output = """
      struct ContentView: View {

          // MARK: Lifecycle

          init() {}

          // MARK: Internal

          @Binding var isOn: Bool

          @Environment(\\.colorScheme) var colorScheme
          @Environment(\\.quux) var quux: Quux

          @State var foo: Foo
          @State var bar: Bar

          @ViewBuilder
          var body: some View {
              Toggle(label, isOn: $isOn)
          }
      }
      """

    testFormatting(
      for: input, output,
      rule: .organizeDeclarations,
      options: FormatOptions(
        organizeTypes: ["struct"],
        organizationMode: .visibility,
        blankLineAfterSubgroups: false,
        swiftUIPropertiesSortMode: .alphabetize,
      ),
      exclude: [
        .blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .privateStateVariables,
        .redundantViewBuilder,
      ],
    )
  }

  @Test func sortSwiftUIPropertyWrappersSubCategoryPreservingGroupPosition() {
    let input = """
      struct ContentView: View {
          init() {}

          @Environment(\\.colorScheme) var colorScheme
          @State var foo: Foo
          @Binding var isOn: Bool
          @Environment(\\.quux) var quux: Quux

          @ViewBuilder
          var body: some View {
              Toggle(label, isOn: $isOn)
          }
      }
      """

    let output = """
      struct ContentView: View {

          // MARK: Lifecycle

          init() {}

          // MARK: Internal

          @Environment(\\.colorScheme) var colorScheme
          @Environment(\\.quux) var quux: Quux
          @State var foo: Foo
          @Binding var isOn: Bool

          @ViewBuilder
          var body: some View {
              Toggle(label, isOn: $isOn)
          }
      }
      """

    testFormatting(
      for: input, output,
      rule: .organizeDeclarations,
      options: FormatOptions(
        organizeTypes: ["struct"],
        organizationMode: .visibility,
        blankLineAfterSubgroups: false,
        swiftUIPropertiesSortMode: .firstAppearanceSort,
      ),
      exclude: [
        .blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .privateStateVariables,
        .redundantViewBuilder,
      ],
    )
  }

  @Test func sortSwiftUIWrappersByTypeAndMaintainGroupSpacingAndPosition() {
    let input = """
      struct ContentView: View {
          init() {}

          @State var foo: Foo
          @State var bar: Bar

          @Environment(\\.colorScheme) var colorScheme
          @Environment(\\.quux) var quux: Quux

          @Binding var isOn: Bool

          @ViewBuilder
          var body: some View {
              Toggle(label, isOn: $isOn)
          }
      }
      """

    let output = """
      struct ContentView: View {

          // MARK: Lifecycle

          init() {}

          // MARK: Internal

          @State var foo: Foo
          @State var bar: Bar

          @Environment(\\.colorScheme) var colorScheme
          @Environment(\\.quux) var quux: Quux

          @Binding var isOn: Bool

          @ViewBuilder
          var body: some View {
              Toggle(label, isOn: $isOn)
          }
      }
      """

    testFormatting(
      for: input, output,
      rule: .organizeDeclarations,
      options: FormatOptions(
        organizeTypes: ["struct"],
        organizationMode: .visibility,
        blankLineAfterSubgroups: false,
        swiftUIPropertiesSortMode: .firstAppearanceSort,
      ),
      exclude: [
        .blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .privateStateVariables,
        .redundantViewBuilder,
      ],
    )
  }

  @Test func preservesBlockOfConsecutivePropertiesWithoutBlankLinesBetweenSubgroups1() {
    let input = """
      class Foo {
          init() {}

          let foo: Foo
          let baaz: Baaz
          static let bar: Bar

      }
      """

    let output = """
      class Foo {

          // MARK: Lifecycle

          init() {}

          // MARK: Internal

          static let bar: Bar
          let foo: Foo
          let baaz: Baaz

      }
      """

    testFormatting(
      for: input, output,
      rule: .organizeDeclarations,
      options: FormatOptions(blankLineAfterSubgroups: false),
      exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope],
    )
  }

  @Test func preservesBlockOfConsecutivePropertiesWithoutBlankLinesBetweenSubgroups2() {
    let input = """
      class Foo {
          init() {}

          let foo: Foo
          let baaz: Baaz
          static let bar: Bar

          static let quux: Quux
          let fooBar: FooBar
          let baazQuux: BaazQuux

      }
      """

    let output = """
      class Foo {

          // MARK: Lifecycle

          init() {}

          // MARK: Internal

          static let bar: Bar
          static let quux: Quux
          let foo: Foo
          let baaz: Baaz

          let fooBar: FooBar
          let baazQuux: BaazQuux

      }
      """

    testFormatting(
      for: input, output,
      rule: .organizeDeclarations,
      options: FormatOptions(blankLineAfterSubgroups: false),
      exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope],
    )
  }

  @Test func preservesBlockOfConsecutiveProperties() {
    let input = """
      class Foo {
          init() {}

          let foo: Foo
          let baaz: Baaz
          static let bar: Bar

      }
      """

    let output = """
      class Foo {

          // MARK: Lifecycle

          init() {}

          // MARK: Internal

          static let bar: Bar

          let foo: Foo
          let baaz: Baaz

      }
      """

    testFormatting(
      for: input, output,
      rule: .organizeDeclarations,
      exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope],
    )
  }

  @Test func preservesBlockOfConsecutiveProperties2() {
    let input = """
      class Foo {
          init() {}

          let foo: Foo
          let baaz: Baaz
          static let bar: Bar

          static let quux: Quux
          let fooBar: FooBar
          let baazQuux: BaazQuux

      }
      """

    let output = """
      class Foo {

          // MARK: Lifecycle

          init() {}

          // MARK: Internal

          static let bar: Bar
          static let quux: Quux

          let foo: Foo
          let baaz: Baaz

          let fooBar: FooBar
          let baazQuux: BaazQuux

      }
      """

    testFormatting(
      for: input, output,
      rule: .organizeDeclarations,
      exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope],
    )
  }

  @Test func preservesCommentAtEndOfTypeBody() {
    let input = """
      class Foo {

          // MARK: Lifecycle

          init() {}

          // MARK: Internal

          let bar: Bar
          let baaz: Baaz

          // Comment at end of file

      }
      """

    testFormatting(
      for: input,
      rule: .organizeDeclarations,
      exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope],
    )
  }

  @Test func swiftUIPropertyWrappersSortDoesNotBreakViewSynthesizedMemberwiseInitializer() {
    // @Environment properties don't affect memberwise init, so they can be freely reordered.
    // The stored properties (foo, baaz) maintain their relative order to preserve memberwise init.
    let input = """
      struct ContentView: View {

          let foo: Foo
          @Environment(\\.colorScheme) private var colorScheme
          let baaz: Baaz
          @Environment(\\.quux) private let quux: Quux

          @ViewBuilder
          private var toggle: some View {
              Toggle(label, isOn: $isOn)
          }

          @ViewBuilder
          var body: some View {
              toggle
          }
      }
      """

    let output = """
      struct ContentView: View {

          // MARK: Internal

          let foo: Foo
          let baaz: Baaz

          @ViewBuilder
          var body: some View {
              toggle
          }

          // MARK: Private

          @Environment(\\.colorScheme) private var colorScheme
          @Environment(\\.quux) private let quux: Quux

          @ViewBuilder
          private var toggle: some View {
              Toggle(label, isOn: $isOn)
          }

      }
      """

    testFormatting(
      for: input, output,
      rule: .organizeDeclarations,
      options: FormatOptions(organizeTypes: ["struct"], organizationMode: .visibility),
      exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .redundantViewBuilder],
    )
  }

  @Test func reorderingPropertiesCreatesFormatterChanges() {
    let input = """
      struct Test {
          var bar: Bar { "Bar" }

          var foo: Foo

          func test() {}
      }
      """

    let output = """
      struct Test {
          var foo: Foo

          var bar: Bar { "Bar" }

          func test() {}
      }
      """

    testFormatting(
      for: input, output,
      rule: .organizeDeclarations, exclude: [.wrapPropertyBodies],
    )
  }

}
