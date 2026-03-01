import Testing

@testable import Swiftiomatic

extension OrganizeDeclarationsTests {
  @Test func organizesNestedTypesWithinConditionalCompilationBlock() {
    let input = """
      public struct Foo {

          public var bar = "bar"
          var baz = "baz"

          #if DEBUG
          public struct DebugFoo {
              init() {}
              var debugBar = "debug"
          }

          static let debugFoo = DebugFoo()

          private let other = "other"
          #endif

          init() {}

          var quuz = "quux"

          #if DEBUG
          struct Test {
              let foo: Bar
          }
          #endif
      }
      """

    let output = """
      public struct Foo {

          // MARK: Lifecycle

          init() {}

          // MARK: Public

          #if DEBUG
          public struct DebugFoo {

              // MARK: Lifecycle

              init() {}

              // MARK: Internal

              var debugBar = "debug"
          }

          static let debugFoo = DebugFoo()

          private let other = "other"
          #endif

          public var bar = "bar"

          // MARK: Internal

          #if DEBUG
          struct Test {
              let foo: Bar
          }
          #endif

          var baz = "baz"

          var quuz = "quux"

      }
      """

    testFormatting(
      for: input, output, rule: .organizeDeclarations,
      options: FormatOptions(ifdefIndent: .noIndent),
      exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .propertyTypes],
    )
  }

  @Test func organizesTypeBelowSymbolImport() {
    let input = """
      import protocol SomeModule.SomeProtocol
      import class SomeModule.SomeClass
      import enum SomeModule.SomeEnum
      import struct SomeModule.SomeStruct
      import typealias SomeModule.SomeTypealias
      import let SomeModule.SomeGlobalConstant
      import var SomeModule.SomeGlobalVariable
      import func SomeModule.SomeFunc

      public struct Foo {
          init() {}
          public func instanceMethod() {}
      }
      """

    let output = """
      import protocol SomeModule.SomeProtocol
      import class SomeModule.SomeClass
      import enum SomeModule.SomeEnum
      import struct SomeModule.SomeStruct
      import typealias SomeModule.SomeTypealias
      import let SomeModule.SomeGlobalConstant
      import var SomeModule.SomeGlobalVariable
      import func SomeModule.SomeFunc

      public struct Foo {

          // MARK: Lifecycle

          init() {}

          // MARK: Public

          public func instanceMethod() {}
      }
      """

    testFormatting(
      for: input, output, rule: .organizeDeclarations,
      exclude: [.blankLinesAtStartOfScope, .sortImports],
    )
  }

  @Test func doesNotBreakStructSynthesizedMemberwiseInitializer() {
    let input = """
      public struct Foo {
          
          let foo: Foo
          @State var bar: Bar?
          @ObservedObject var baaz: Baaz
          public let quux: Quux

          public var content: some View {
              foo
          }
      }

      Foo(foo: 1, bar: 2, baaz: 3, quux: 4)
      """

    let output = """
      public struct Foo {

          // MARK: Public

          public var content: some View {
              foo
          }

          // MARK: Internal

          let foo: Foo

          @State var bar: Bar?
          @ObservedObject var baaz: Baaz

          public let quux: Quux

      }

      Foo(foo: 1, bar: 2, baaz: 3, quux: 4)
      """

    testFormatting(
      for: input, [output], rules: [.organizeDeclarations, .consecutiveBlankLines],
      exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .privateStateVariables],
    )
  }

  @Test func organizesStructPropertiesThatDontBreakMemberwiseInitializer() {
    let input = """
      public struct Foo {
          var computed: String {
              let didSet = "didSet"
              let willSet = "willSet"
              return didSet + willSet
          }

          private func instanceMethod() {}
          public let bar: Int
          var baz: Int
          var quux: Int {
              didSet {}
          }
      }

      Foo(bar: 1, baz: 2, quux: 3)
      """

    let output = """
      public struct Foo {

          // MARK: Public

          public let bar: Int

          // MARK: Internal

          var baz: Int

          var computed: String {
              let didSet = "didSet"
              let willSet = "willSet"
              return didSet + willSet
          }

          var quux: Int {
              didSet {}
          }

          // MARK: Private

          private func instanceMethod() {}
      }

      Foo(bar: 1, baz: 2, quux: 3)
      """

    testFormatting(
      for: input, output, rule: .organizeDeclarations,
      exclude: [.blankLinesAtStartOfScope],
    )
  }

  @Test func preservesCategoryMarksInStructWithIncorrectSubcategoryOrdering() {
    let input = """
      public struct Foo {

          // MARK: Public

          public let quux: Int

          // MARK: Internal

          var bar: Int {
              didSet {}
          }

          var baz: Int
      }

      Foo(bar: 1, baz: 2, quux: 3)
      """

    testFormatting(
      for: input, rule: .organizeDeclarations,
      exclude: [.blankLinesAtStartOfScope],
    )
  }

  @Test func preservesCommentsAtBottomOfCategory() {
    let input = """
      public struct Foo {

          // MARK: Lifecycle

          init() {}

          // Important comment at end of section!

          // MARK: Public

          public let bar = 1
      }
      """

    testFormatting(
      for: input, rule: .organizeDeclarations,
      exclude: [.blankLinesAtStartOfScope],
    )
  }

  @Test func preservesCommentsAtBottomOfCategoryWhenReorganizing() {
    let input = """
      public struct Foo {

          // MARK: Lifecycle

          init() {}

          // Important comment at end of section!

          // MARK: Internal

          // Important comment at start of section!

          var baz = 1

          public let bar = 1
      }
      """

    let output = """
      public struct Foo {

          // MARK: Lifecycle

          init() {}

          // Important comment at end of section!

          // MARK: Public

          public let bar = 1

          // MARK: Internal

          // Important comment at start of section!

          var baz = 1

      }
      """

    testFormatting(
      for: input, output, rule: .organizeDeclarations,
      exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope],
    )
  }

  @Test func doesNotRemoveCategorySeparatorsFromBodyNotBeingOrganized() {
    let input = """
      public struct Foo {

          // MARK: Lifecycle

          init() {}

          // MARK: Public

          public var bar = 10
      }

      extension Foo {

          // MARK: Public

          public var baz: Int { 20 }

          // MARK: Internal

          var quux: Int { 30 }
      }
      """

    testFormatting(
      for: input, rule: .organizeDeclarations,
      options: FormatOptions(organizeStructThreshold: 20),
      exclude: [.blankLinesAtStartOfScope, .wrapPropertyBodies],
    )
  }

  @Test func parsesPropertiesWithBodies() {
    let input = """
      class Foo {
          // Instance properties without bodies:

          let propertyWithoutBody1 = 10

          let propertyWithoutBody2: String = {
              "bar"
          }()

          let propertyWithoutBody3: () -> String = {
              "bar"
          }

          // Instance properties with bodies:

          var withBody1: String {
              "bar"
          }

          var withBody2: String {
              didSet { print("didSet") }
          }

          var withBody3: String = "bar" {
              didSet { print("didSet") }
          }

          var withBody4: String = "bar" {
              didSet { print("didSet") }
          }

          var withBody5: () -> String = { "bar" } {
              didSet { print("didSet") }
          }

          var withBody6: String = { "bar" }() {
              didSet { print("didSet") }
          }
      }
      """

    testFormatting(
      for: input, rule: .organizeDeclarations,
      exclude: [
        .redundantClosure,
        .wrapPropertyBodies,
      ],
    )
  }

  @Test func funcWithNestedInitNotTreatedAsLifecycle() {
    let input = """
      public struct Foo {

          // MARK: Public

          public func baz() {}

          // MARK: Internal

          func bar() {
              class NestedClass {
                  init() {}
              }

              // ...
          }
      }
      """

    testFormatting(
      for: input, rule: .organizeDeclarations,
      exclude: [.blankLinesAtStartOfScope],
    )
  }

  @Test func organizeRuleNotConfusedByClassProtocol() {
    let input = """
      protocol Foo: class {
          func foo()
      }

      class Bar {
          // MARK: Fileprivate

          private var baz: Int

          // MARK: Private

          private let quux: String
      }
      """

    let output = """
      protocol Foo: class {
          func foo()
      }

      class Bar {
          private var baz: Int

          private let quux: String
      }
      """

    testFormatting(
      for: input, output, rule: .organizeDeclarations,
      exclude: [.blankLinesAtStartOfScope],
    )
  }

  @Test func organizeClassDeclarationsIntoCategoriesWithNoBlankLineAfterMark() {
    let input = """
      public class Foo {
          private func privateMethod() {}

          private let bar = 1
          public let baz = 1
          open var quack = 2
          var quux = 2

          init() {}

          /// Doc comment
          public func publicMethod() {}
      }
      """

    let output = """
      public class Foo {

          // MARK: Lifecycle
          init() {}

          // MARK: Open
          open var quack = 2

          // MARK: Public
          public let baz = 1

          /// Doc comment
          public func publicMethod() {}

          // MARK: Internal
          var quux = 2

          // MARK: Private
          private let bar = 1

          private func privateMethod() {}

      }
      """
    let options = FormatOptions(lineAfterMarks: false)
    testFormatting(
      for: input, output,
      rule: .organizeDeclarations,
      options: options,
      exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope],
    )
  }

  @Test func organizeWithNoCategoryMarks_noSpacesBetweenDeclarations() {
    let input = """
      public class Foo {
          private func privateMethod() {}
          private let bar = 1
          public let baz = 1
      }
      """

    let output = """
      public class Foo {
          public let baz = 1

          private let bar = 1

          private func privateMethod() {}
      }
      """

    testFormatting(
      for: input, output,
      rule: .organizeDeclarations,
      options: FormatOptions(markCategories: false),
    )
  }

  @Test func organizeWithNoCategoryMarks_withSpacesBetweenDeclarations() {
    let input = """
      public class Foo {
          private func privateMethod() {}

          private let bar = 1

          public let baz = 1

          private func anotherPrivateMethod() {}
      }
      """

    let output = """
      public class Foo {
          public let baz = 1

          private let bar = 1

          private func privateMethod() {}

          private func anotherPrivateMethod() {}
      }
      """

    // easy to start with?
    testFormatting(
      for: input, output,
      rule: .organizeDeclarations,
      options: FormatOptions(markCategories: false),
    )
  }

  @Test func organizeConditionalInitDeclaration() {
    let input = """
      class Foo {

          // MARK: Lifecycle

          init() {}

          #if DEBUG
          init() {
              print("Debug")
          }
          #endif

          // MARK: Internal

          func test() {}
      }
      """

    testFormatting(
      for: input, rule: .organizeDeclarations, options: FormatOptions(ifdefIndent: .noIndent),
      exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope],
    )
  }

  @Test func organizeConditionalPublicFunction() {
    let input = """
      public class Foo {

          // MARK: Lifecycle

          init() {}

          // MARK: Public

          #if DEBUG
          public func publicTest() {}
          #endif

          // MARK: Internal

          func internalTest() {}
      }
      """

    testFormatting(
      for: input, rule: .organizeDeclarations, options: FormatOptions(ifdefIndent: .noIndent),
      exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope],
    )
  }

  @Test func doesNotConflictWithOrganizeDeclarations() {
    let input = """
      // sm:sort
      enum FeatureFlags {
          case barFeature
          case fooFeature
          case upsellA
          case upsellB

          // MARK: Internal

          var anUnsortedProperty: Foo {
              Foo()
          }

          var unsortedProperty: Foo {
              Foo()
          }
      }
      """

    testFormatting(for: input, rule: .organizeDeclarations)
  }

  @Test func sortsWithinOrganizeDeclarations() {
    let input = """
      // sm:sort
      enum FeatureFlags {
          case fooFeature
          case barFeature
          case upsellB
          case upsellA

          // MARK: Internal

          var sortedProperty: Foo {
              Foo()
          }

          var aSortedProperty: Foo {
              Foo()
          }
      }
      """

    let output = """
      // sm:sort
      enum FeatureFlags {
          case barFeature
          case fooFeature
          case upsellA

          case upsellB

          // MARK: Internal

          var aSortedProperty: Foo {
              Foo()
          }

          var sortedProperty: Foo {
              Foo()
          }

      }
      """

    testFormatting(
      for: input, [output],
      rules: [.organizeDeclarations, .blankLinesBetweenScopes],
      exclude: [.blankLinesAtEndOfScope],
    )
  }

  @Test func sortsWithinOrganizeDeclarationsByClassName() {
    let input = """
      enum FeatureFlags {
          case fooFeature
          case barFeature
          case upsellB
          case upsellA

          // MARK: Internal

          var sortedProperty: Foo {
              Foo()
          }

          var aSortedProperty: Foo {
              Foo()
          }
      }
      """

    let output = """
      enum FeatureFlags {
          case barFeature
          case fooFeature
          case upsellA

          case upsellB

          // MARK: Internal

          var aSortedProperty: Foo {
              Foo()
          }

          var sortedProperty: Foo {
              Foo()
          }

      }
      """

    testFormatting(
      for: input, [output],
      rules: [.organizeDeclarations, .blankLinesBetweenScopes],
      options: .init(alphabeticallySortedDeclarationPatterns: ["FeatureFlags"]),
      exclude: [.blankLinesAtEndOfScope],
    )
  }

  @Test func sortsWithinOrganizeDeclarationsByPartialClassName() {
    let input = """
      enum FeatureFlags {
          case fooFeature
          case barFeature
          case upsellB
          case upsellA

          // MARK: Internal

          var sortedProperty: Foo {
              Foo()
          }

          var aSortedProperty: Foo {
              Foo()
          }
      }
      """

    let output = """
      enum FeatureFlags {
          case barFeature
          case fooFeature
          case upsellA

          case upsellB

          // MARK: Internal

          var aSortedProperty: Foo {
              Foo()
          }

          var sortedProperty: Foo {
              Foo()
          }

      }
      """

    testFormatting(
      for: input, [output],
      rules: [.organizeDeclarations, .blankLinesBetweenScopes],
      options: .init(alphabeticallySortedDeclarationPatterns: ["ureFla"]),
      exclude: [.blankLinesAtEndOfScope],
    )
  }

  @Test func dontSortsWithinOrganizeDeclarationsByClassNameInComment() {
    let input = """
      /// Comment
      enum FeatureFlags {
          case fooFeature
          case barFeature
          case upsellB
          case upsellA

          // MARK: Internal

          var sortedProperty: Foo {
              Foo()
          }

          var aSortedProperty: Foo {
              Foo()
          }
      }
      """

    testFormatting(
      for: input,
      rules: [.organizeDeclarations, .blankLinesBetweenScopes],
      options: .init(alphabeticallySortedDeclarationPatterns: ["Comment"]),
      exclude: [.blankLinesAtEndOfScope],
    )
  }

  @Test func organizeDeclarationsSortUsesLocalizedCompare() {
    let input = """
      // sm:sort
      enum FeatureFlags {
          case upsella
          case upsellA
          case upsellb
          case upsellB
      }
      """

    testFormatting(for: input, rule: .organizeDeclarations)
  }

  @Test func sortDeclarationsSortsExtensionBody() {
    let input = """
      public enum Namespace {}

      // sm:sort
      extension Namespace {
          static let foo = "foo"
          public static let bar = "bar"
          static let baaz = "baaz"
      }
      """

    let output = """
      public enum Namespace {}

      // sm:sort
      extension Namespace {
          static let baaz = "baaz"
          public static let bar = "bar"
          static let foo = "foo"
      }
      """

    // organizeTypes doesn't include "extension". So even though the
    // organizeDeclarations rule is enabled, the extension should be
    // sorted by the sortDeclarations rule.
    let options = FormatOptions(organizeTypes: ["class"])
    testFormatting(
      for: input, [output], rules: [.sortDeclarations, .organizeDeclarations],
      options: options,
    )
  }

  @Test func organizeDeclarationsSortsExtensionBody() {
    let input = """
      public enum Namespace {}

      // sm:sort
      extension Namespace {
          static let foo = "foo"
          public static let bar = "bar"
          static let baaz = "baaz"
      }
      """

    let output = """
      public enum Namespace {}

      // sm:sort
      extension Namespace {

          // MARK: Public

          public static let bar = "bar"

          // MARK: Internal

          static let baaz = "baaz"
          static let foo = "foo"
      }
      """

    let options = FormatOptions(organizeTypes: ["extension"])
    testFormatting(
      for: input, output, rule: .organizeDeclarations, options: options,
      exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope],
    )
  }

}
