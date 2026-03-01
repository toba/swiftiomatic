import Testing

@testable import Swiftiomatic

@Suite struct WrapAttributesTests {
  @Test func preserveWrappedFuncAttributeByDefault() {
    let input = """
      @objc
      func foo() {}
      """
    testFormatting(for: input, rule: .wrapAttributes)
  }

  @Test func preserveUnwrappedFuncAttributeByDefault() {
    let input = """
      @objc func foo() {}
      """
    testFormatting(for: input, rule: .wrapAttributes)
  }

  @Test func wrapFuncAttribute() {
    let input = """
      @available(iOS 14.0, *) func foo() {}
      """
    let output = """
      @available(iOS 14.0, *)
      func foo() {}
      """
    let options = FormatOptions(funcAttributes: .prevLine)
    testFormatting(for: input, output, rule: .wrapAttributes, options: options)
  }

  @Test func wrapInitAttribute() {
    let input = """
      @available(iOS 14.0, *) init() {}
      """
    let output = """
      @available(iOS 14.0, *)
      init() {}
      """
    let options = FormatOptions(funcAttributes: .prevLine)
    testFormatting(for: input, output, rule: .wrapAttributes, options: options)
  }

  @Test func multipleAttributesNotSeparated() {
    let input = """
      @objc @IBAction func foo {}
      """
    let output = """
      @objc @IBAction
      func foo {}
      """
    let options = FormatOptions(funcAttributes: .prevLine)
    testFormatting(
      for: input, output, rule: .wrapAttributes,
      options: options, exclude: [.redundantObjc],
    )
  }

  @Test func funcAttributeStaysWrapped() {
    let input = """
      @available(iOS 14.0, *)
      func foo() {}
      """
    let options = FormatOptions(funcAttributes: .prevLine)
    testFormatting(for: input, rule: .wrapAttributes, options: options)
  }

  @Test func unwrapFuncAttribute() {
    let input = """
      @available(iOS 14.0, *)
      func foo() {}
      """
    let output = """
      @available(iOS 14.0, *) func foo() {}
      """
    let options = FormatOptions(funcAttributes: .sameLine)
    testFormatting(for: input, output, rule: .wrapAttributes, options: options)
  }

  @Test func unwrapFuncAttribute2() {
    let input = """
      class MyClass: NSObject {
          @objc
          func myFunction() {
              print("Testing")
          }
      }
      """
    let output = """
      class MyClass: NSObject {
          @objc func myFunction() {
              print("Testing")
          }
      }
      """
    let options = FormatOptions(funcAttributes: .sameLine)
    testFormatting(for: input, output, rule: .wrapAttributes, options: options)
  }

  @Test func funcAttributeStaysUnwrapped() {
    let input = """
      @objc func foo() {}
      """
    let options = FormatOptions(funcAttributes: .sameLine)
    testFormatting(for: input, rule: .wrapAttributes, options: options)
  }

  @Test func varAttributeIsNotWrapped() {
    let input = """
      @IBOutlet var foo: UIView?

      @available(iOS 14.0, *)
      func foo() {}
      """
    let options = FormatOptions(funcAttributes: .prevLine)
    testFormatting(for: input, rule: .wrapAttributes, options: options)
  }

  @Test func wrapTypeAttribute() {
    let input = """
      @available(iOS 14.0, *) class Foo {}
      """
    let output = """
      @available(iOS 14.0, *)
      class Foo {}
      """
    let options = FormatOptions(typeAttributes: .prevLine)
    testFormatting(
      for: input,
      output,
      rule: .wrapAttributes,
      options: options,
    )
  }

  @Test func wrapExtensionAttribute() {
    let input = """
      @available(iOS 14.0, *) extension Foo {}
      """
    let output = """
      @available(iOS 14.0, *)
      extension Foo {}
      """
    let options = FormatOptions(typeAttributes: .prevLine)
    testFormatting(
      for: input,
      output,
      rule: .wrapAttributes,
      options: options,
    )
  }

  @Test func typeAttributeStaysWrapped() {
    let input = """
      @available(iOS 14.0, *)
      struct Foo {}
      """
    let options = FormatOptions(typeAttributes: .prevLine)
    testFormatting(for: input, rule: .wrapAttributes, options: options)
  }

  @Test func unwrapTypeAttribute() {
    let input = """
      @available(iOS 14.0, *)
      enum Foo {}
      """
    let output = """
      @available(iOS 14.0, *) enum Foo {}
      """
    let options = FormatOptions(typeAttributes: .sameLine)
    testFormatting(for: input, output, rule: .wrapAttributes, options: options)
  }

  @Test func typeAttributeStaysUnwrapped() {
    let input = """
      @objc class Foo {}
      """
    let options = FormatOptions(typeAttributes: .sameLine)
    testFormatting(for: input, rule: .wrapAttributes, options: options)
  }

  @Test func ableImportIsNotWrapped() {
    let input = """
      @testable import Framework

      @available(iOS 14.0, *)
      class Foo {}
      """
    let options = FormatOptions(typeAttributes: .prevLine)
    testFormatting(for: input, rule: .wrapAttributes, options: options)
  }

  @Test func modifiersDontAffectAttributeWrapping() {
    let input = """
      @objc override public func foo {}
      """
    let output = """
      @objc
      override public func foo {}
      """
    let options = FormatOptions(funcAttributes: .prevLine)
    testFormatting(for: input, output, rule: .wrapAttributes, options: options)
  }

  @Test func classFuncAttributeTreatedAsFunction() {
    let input = """
      @objc class func foo {}
      """
    let output = """
      @objc
      class func foo {}
      """
    let options = FormatOptions(funcAttributes: .prevLine, fragment: true)
    testFormatting(for: input, output, rule: .wrapAttributes, options: options)
  }

  @Test func classFuncAttributeNotTreatedAsType() {
    let input = """
      @objc class func foo {}
      """
    let options = FormatOptions(typeAttributes: .prevLine, fragment: true)
    testFormatting(for: input, rule: .wrapAttributes, options: options)
  }

  @Test func classAttributeNotMistakenForClassLet() {
    let input = """
      @objc final class MyClass: NSObject {}
      let myClass = MyClass()
      """
    let output = """
      @objc
      final class MyClass: NSObject {}
      let myClass = MyClass()
      """
    let options = FormatOptions(typeAttributes: .prevLine)
    testFormatting(
      for: input, output, rule: .wrapAttributes, options: options, exclude: [.propertyTypes],
    )
  }

  @Test func classImportAttributeNotTreatedAsType() {
    let input = """
      @testable import class Framework.Foo
      """
    let options = FormatOptions(typeAttributes: .prevLine)
    testFormatting(for: input, rule: .wrapAttributes, options: options)
  }

  @Test func wrapPrivateSetComputedVarAttributes() {
    let input = """
      @objc private(set) dynamic var foo = Foo()
      """
    let output = """
      @objc
      private(set) dynamic var foo = Foo()
      """
    let options = FormatOptions(
      storedVarAttributes: .prevLine,
      computedVarAttributes: .prevLine,
    )
    testFormatting(
      for: input, output, rule: .wrapAttributes, options: options, exclude: [.propertyTypes],
    )
  }

  @Test func wrapPrivateSetVarAttributes() {
    let input = """
      @objc private(set) dynamic var foo = Foo()
      """
    let output = """
      @objc
      private(set) dynamic var foo = Foo()
      """
    let options = FormatOptions(varAttributes: .prevLine)
    testFormatting(
      for: input, output, rule: .wrapAttributes, options: options, exclude: [.propertyTypes],
    )
  }

  @Test func dontWrapPrivateSetVarAttributes() {
    let input = """
      @objc
      private(set) dynamic var foo = Foo()
      """
    let output = """
      @objc private(set) dynamic var foo = Foo()
      """
    let options = FormatOptions(varAttributes: .prevLine, storedVarAttributes: .sameLine)
    testFormatting(
      for: input, output, rule: .wrapAttributes, options: options, exclude: [.propertyTypes],
    )
  }

  @Test func wrapConvenienceInitAttribute() {
    let input = """
      @objc public convenience init() {}
      """
    let output = """
      @objc
      public convenience init() {}
      """
    let options = FormatOptions(funcAttributes: .prevLine)
    testFormatting(for: input, output, rule: .wrapAttributes, options: options)
  }

  @Test func wrapPropertyWrapperAttributeVarAttributes() {
    let input = """
      @OuterType.Wrapper var foo: Int
      """
    let output = """
      @OuterType.Wrapper
      var foo: Int
      """
    let options = FormatOptions(varAttributes: .prevLine)
    testFormatting(for: input, output, rule: .wrapAttributes, options: options)
  }

  @Test func wrapPropertyWrapperAttribute() {
    let input = """
      @OuterType.Wrapper var foo: Int
      """
    let output = """
      @OuterType.Wrapper
      var foo: Int
      """
    let options = FormatOptions(
      storedVarAttributes: .prevLine,
      computedVarAttributes: .prevLine,
    )
    testFormatting(for: input, output, rule: .wrapAttributes, options: options)
  }

  @Test func dontWrapPropertyWrapperAttribute() {
    let input = """
      @OuterType.Wrapper
      var foo: Int
      """
    let output = """
      @OuterType.Wrapper var foo: Int
      """
    let options = FormatOptions(varAttributes: .prevLine, storedVarAttributes: .sameLine)
    testFormatting(for: input, output, rule: .wrapAttributes, options: options)
  }

  @Test func wrapGenericPropertyWrapperAttribute() {
    let input = """
      @OuterType.Generic<WrappedType> var foo: WrappedType
      """
    let output = """
      @OuterType.Generic<WrappedType>
      var foo: WrappedType
      """
    let options = FormatOptions(
      storedVarAttributes: .prevLine,
      computedVarAttributes: .prevLine,
    )
    testFormatting(for: input, output, rule: .wrapAttributes, options: options)
  }

  @Test func wrapGenericPropertyWrapperAttribute2() {
    let input = """
      @OuterType.Generic<WrappedType>.Foo var foo: WrappedType
      """
    let output = """
      @OuterType.Generic<WrappedType>.Foo
      var foo: WrappedType
      """
    let options = FormatOptions(
      storedVarAttributes: .prevLine,
      computedVarAttributes: .prevLine,
    )
    testFormatting(for: input, output, rule: .wrapAttributes, options: options)
  }

  @Test func attributeOnComputedProperty() {
    let input = """
      extension SectionContainer: ContentProviding where Section: ContentProviding {
          @_disfavoredOverload
          public var content: Section.Content {
              section.content
          }
      }
      """

    let options = FormatOptions(varAttributes: .prevLine, storedVarAttributes: .sameLine)
    testFormatting(for: input, rule: .wrapAttributes, options: options)
  }

  @Test func wrapAvailableAttributeUnderMaxWidth() {
    let input = """
      @available(*, unavailable, message: "This property is deprecated.")
      var foo: WrappedType
      """
    let output = """
      @available(*, unavailable, message: "This property is deprecated.") var foo: WrappedType
      """
    let options = FormatOptions(
      maxWidth: 100, varAttributes: .prevLine, storedVarAttributes: .sameLine,
    )
    testFormatting(for: input, output, rule: .wrapAttributes, options: options)
  }

  @Test func doesNotWrapAvailableAttributeWithLongMessage() {
    // Unwrapping this attribute would just cause it to wrap in a different way:
    //
    //   @available(
    //       *,
    //       unavailable,
    //       message: "This property is deprecated. It has a really long message."
    //   ) var foo: WrappedType
    //
    // so instead leave it un-wrapped to preserve the existing formatting.
    let input = """
      @available(*, unavailable, message: "This property is deprecated. It has a really long message.")
      var foo: WrappedType
      """
    let options = FormatOptions(
      maxWidth: 100, varAttributes: .prevLine, storedVarAttributes: .sameLine,
    )
    testFormatting(for: input, rule: .wrapAttributes, options: options)
  }

  @Test func doesNotWrapComplexAttribute() {
    let input = """
      @Option(
          name: ["myArgument"],
          help: "Long help text for my example arg from Swift argument parser")
      var foo: WrappedType
      """
    let options = FormatOptions(
      closingParenPosition: .sameLine, varAttributes: .prevLine,
      storedVarAttributes: .sameLine,
      complexAttributes: .prevLine,
    )
    testFormatting(for: input, rule: .wrapAttributes, options: options)
  }

  @Test func doesNotWrapComplexMultilineAttribute() {
    let input = """
      @available(*, deprecated, message: "Deprecated!")
      var foo: WrappedType
      """
    let options = FormatOptions(
      varAttributes: .prevLine, storedVarAttributes: .sameLine, complexAttributes: .prevLine,
    )
    testFormatting(for: input, rule: .wrapAttributes, options: options)
  }

  @Test func wrapsComplexAttribute() {
    let input = """
      @available(*, deprecated, message: "Deprecated!") var foo: WrappedType
      """

    let output = """
      @available(*, deprecated, message: "Deprecated!")
      var foo: WrappedType
      """
    let options = FormatOptions(
      varAttributes: .prevLine, storedVarAttributes: .sameLine, complexAttributes: .prevLine,
    )
    testFormatting(for: input, output, rule: .wrapAttributes, options: options)
  }

  @Test func wrapAttributesIndentsLineCorrectly() {
    let input = """
      class Foo {
          @objc var foo = Foo()
      }
      """
    let output = """
      class Foo {
          @objc
          var foo = Foo()
      }
      """
    let options = FormatOptions(
      storedVarAttributes: .prevLine,
      computedVarAttributes: .prevLine,
    )
    testFormatting(
      for: input, output, rule: .wrapAttributes, options: options, exclude: [.propertyTypes],
    )
  }

  @Test func complexAttributesException() {
    let input = """
      @Environment(\\.myEnvironmentVar) var foo: Foo

      @SomeCustomAttr(argument: true) var foo: Foo

      @available(*, deprecated) var foo: Foo
      """

    let output = """
      @Environment(\\.myEnvironmentVar) var foo: Foo

      @SomeCustomAttr(argument: true) var foo: Foo

      @available(*, deprecated)
      var foo: Foo
      """

    let options = FormatOptions(
      varAttributes: .sameLine, storedVarAttributes: .sameLine,
      computedVarAttributes: .prevLine,
      complexAttributes: .prevLine, complexAttributesExceptions: ["@SomeCustomAttr"],
    )
    testFormatting(for: input, output, rule: .wrapAttributes, options: options)
  }

  @Test func mixedComplexAndSimpleAttributes() {
    let input = """
      /// Simple attributes stay on a single line:
      @State private var warpDriveEnabled: Bool

      @ObservedObject private var lifeSupportService: LifeSupportService

      @Environment(\\.controlPanelStyle) private var controlPanelStyle

      @AppStorage("ControlsConfig") private var controlsConfig: ControlConfiguration

      /// Complex attributes are wrapped:
      @AppStorage("ControlPanelState", store: myCustomUserDefaults) private var controlPanelState: ControlPanelState

      @Tweak(name: "Aspect ratio") private var aspectRatio = AspectRatio.stretch

      @available(*, unavailable) var saturn5Builder: Saturn5Builder

      @available(*, unavailable, message: "No longer in production") var saturn5Builder: Saturn5Builder
      """

    let output = """
      /// Simple attributes stay on a single line:
      @State private var warpDriveEnabled: Bool

      @ObservedObject private var lifeSupportService: LifeSupportService

      @Environment(\\.controlPanelStyle) private var controlPanelStyle

      @AppStorage("ControlsConfig") private var controlsConfig: ControlConfiguration

      /// Complex attributes are wrapped:
      @AppStorage("ControlPanelState", store: myCustomUserDefaults)
      private var controlPanelState: ControlPanelState

      @Tweak(name: "Aspect ratio")
      private var aspectRatio = AspectRatio.stretch

      @available(*, unavailable)
      var saturn5Builder: Saturn5Builder

      @available(*, unavailable, message: "No longer in production")
      var saturn5Builder: Saturn5Builder
      """

    let options = FormatOptions(storedVarAttributes: .sameLine, complexAttributes: .prevLine)
    testFormatting(
      for: input, output, rule: .wrapAttributes, options: options, exclude: [.propertyTypes],
    )
  }

  @Test func escapingClosureNotMistakenForComplexAttribute() {
    let input = """
      func foo(_ fooClosure: @escaping () throws -> Void) {
          try fooClosure()
      }
      """

    let options = FormatOptions(complexAttributes: .prevLine)
    testFormatting(for: input, rule: .wrapAttributes, options: options)
  }

  @Test func escapingTypedThrowClosureNotMistakenForComplexAttribute() {
    let input = """
      func foo(_ fooClosure: @escaping () throws(Foo) -> Void) {
          try fooClosure()
      }
      """

    let options = FormatOptions(complexAttributes: .prevLine)
    testFormatting(for: input, rule: .wrapAttributes, options: options)
  }

  @Test func wrapOrDontWrapMultipleDeclarationsInClass() {
    let input = """
      class Foo {
          @objc
          var foo = Foo()

          @available(*, unavailable)
          var bar: Bar

          @available(*, unavailable)
          var myComputedFoo: String {
              "myComputedFoo"
          }

          @Environment(\\.myEnvironmentVar)
          var foo

          @State
          private var myStoredFoo: String = "myStoredFoo" {
              didSet {
                  print(newValue)
              }
          }
      }
      """
    let output = """
      class Foo {
          @objc var foo = Foo()

          @available(*, unavailable)
          var bar: Bar

          @available(*, unavailable)
          var myComputedFoo: String {
              "myComputedFoo"
          }

          @Environment(\\.myEnvironmentVar) var foo

          @State private var myStoredFoo: String = "myStoredFoo" {
              didSet {
                  print(newValue)
              }
          }
      }
      """
    let options = FormatOptions(
      varAttributes: .sameLine, storedVarAttributes: .sameLine,
      computedVarAttributes: .prevLine,
      complexAttributes: .prevLine,
    )
    testFormatting(
      for: input, output, rule: .wrapAttributes, options: options, exclude: [.propertyTypes],
    )
  }

  @Test func wrapOrDontAttributesInSwiftUIView() {
    let input = """
      struct MyView: View {
          @State private var textContent: String

          var body: some View {
              childView
          }

          @ViewBuilder
          var childView: some View {
              Text(verbatim: textContent)
          }
      }
      """

    let options = FormatOptions(
      varAttributes: .sameLine, storedVarAttributes: .sameLine,
      computedVarAttributes: .prevLine,
    )
    testFormatting(
      for: input, rule: .wrapAttributes, options: options, exclude: [.redundantViewBuilder],
    )
  }

  @Test func wrapAttributesInSwiftUIView() {
    let input = """
      struct MyView: View {
          @State private var textContent: String
          @Environment(\\.myEnvironmentVar) var environmentVar

          var body: some View {
              childView
          }

          @ViewBuilder var childView: some View {
              Text(verbatim: textContent)
          }
      }
      """

    let options = FormatOptions(varAttributes: .sameLine, complexAttributes: .prevLine)
    testFormatting(
      for: input, rule: .wrapAttributes, options: options, exclude: [.redundantViewBuilder],
    )
  }

  @Test func inlineMainActorAttributeNotWrapped() {
    let input = """
      var foo: @MainActor (Foo) -> Void
      var bar: @MainActor (Bar) -> Void
      """
    let options = FormatOptions(
      storedVarAttributes: .prevLine,
      computedVarAttributes: .prevLine,
    )
    testFormatting(for: input, rule: .wrapAttributes, options: options)
  }

  @Test func issue2215_asyncEffectNotConfusedForModifier() {
    let input = """
      public typealias FooBar = @Sendable (_ foo: Foo, _ bar: Bar) async -> Void

      struct Foo {}
      """

    let options = FormatOptions(funcAttributes: .prevLine, typeAttributes: .prevLine)
    testFormatting(for: input, rule: .wrapAttributes, options: options)
  }
}
