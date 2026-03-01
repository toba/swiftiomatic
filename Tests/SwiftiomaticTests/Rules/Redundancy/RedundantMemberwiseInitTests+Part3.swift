import Testing

@testable import Swiftiomatic

extension RedundantMemberwiseInitTests {
  @Test func dontRemovePrivateACLForPackageStruct() {
    let input = """
      package struct PackageView {
          init(value: Int) {
              self.value = value
          }

          private let value: Int
      }
      """
    let options = FormatOptions(preferSynthesizedInitForInternalStructs: .always)
    testFormatting(
      for: input, rule: .redundantMemberwiseInit, options: options,
      exclude: [.trailingSpace, .indent],
    )
  }

  @Test func removePrivateACLFromMultipleProperties() {
    let input = """
      struct DataModel {
          init(id: String, name: String, value: Int) {
              self.id = id
              self.name = name
              self.value = value
          }

          private let id: String
          private var name: String
          private let value: Int
          private var variableWithDefault = false
          private let constantWithDefault = true
      }
      """
    let output = """
      struct DataModel {
          let id: String
          var name: String
          let value: Int
          var variableWithDefault = false
          private let constantWithDefault = true
      }
      """
    let options = FormatOptions(preferSynthesizedInitForInternalStructs: .always)
    testFormatting(for: input, output, rule: .redundantMemberwiseInit, options: options)
  }

  @Test func removePrivateACLWithMixedAccessLevels() {
    let input = """
      struct MixedView {
          init(publicValue: Int, privateValue: String, onTap: @escaping () -> Void) {
              self.publicValue = publicValue
              self.privateValue = privateValue
              self.onTap = onTap
          }

          let publicValue: Int
          private let privateValue: String
          private let onTap: () -> Void
      }
      """
    let output = """
      struct MixedView {
          let publicValue: Int
          let privateValue: String
          let onTap: () -> Void
      }
      """
    let options = FormatOptions(preferSynthesizedInitForInternalStructs: .always)
    testFormatting(for: input, output, rule: .redundantMemberwiseInit, options: options)
  }

  @Test func removePrivateACLPreservesPropertyOrder() {
    let input = """
      struct OrderedView {
          private let first: Int
          private let second: String
          private let third: Bool

          init(first: Int, second: String, third: Bool) {
              self.first = first
              self.second = second
              self.third = third
          }
      }
      """
    let output = """
      struct OrderedView {
          let first: Int
          let second: String
          let third: Bool
      }
      """
    let options = FormatOptions(preferSynthesizedInitForInternalStructs: .always)
    testFormatting(for: input, output, rule: .redundantMemberwiseInit, options: options)
  }

  @Test func dontApplyOptionToClasses() {
    // Classes don't have synthesized memberwise inits, so the option should not apply
    let input = """
      class ProfileViewModel {
          init(user: User, settings: Settings) {
              self.user = user
              self.settings = settings
          }

          private let user: User
          private let settings: Settings
      }
      """
    let options = FormatOptions(preferSynthesizedInitForInternalStructs: .always)
    testFormatting(
      for: input, rule: .redundantMemberwiseInit, options: options,
    )
  }

  @Test func removePrivateACLForPrivateStruct() {
    let input = """
      private struct PrivateView {
          init(value: Int) {
              self.value = value
          }

          private let value: Int
      }
      """
    let output = """
      private struct PrivateView {
          let value: Int
      }
      """
    let options = FormatOptions(preferSynthesizedInitForInternalStructs: .always)
    testFormatting(for: input, output, rule: .redundantMemberwiseInit, options: options)
  }

  @Test func removePrivateACLForFileprivateStruct() {
    let input = """
      fileprivate struct FileprivateView {
          init(value: Int) {
              self.value = value
          }

          private let value: Int
      }
      """
    let output = """
      fileprivate struct FileprivateView {
          let value: Int
      }
      """
    let options = FormatOptions(preferSynthesizedInitForInternalStructs: .always)
    testFormatting(
      for: input, output, rule: .redundantMemberwiseInit, options: options,
      exclude: [.redundantFileprivate],
    )
  }

  @Test func preservePrivateOnPropertiesWithDefaultValues() {
    let input = """
      struct Foo: View {
          init(bar: Bar) {
              self.bar = bar
          }

          private let bar: Bar
          @State private let enabled = false
          private let baaz = Baaz()
      }
      """
    let output = """
      struct Foo: View {
          let bar: Bar
          @State private let enabled = false
          private let baaz = Baaz()
      }
      """
    let options = FormatOptions(preferSynthesizedInitForInternalStructs: .always)
    testFormatting(
      for: input, output, rule: .redundantMemberwiseInit, options: options,
      exclude: [.propertyTypes],
    )
  }

  @Test func preserveInitWhenPrivatePropertyWithStateAttributeInMemberwiseInit() {
    let input = """
      struct Foo: View {
          init(bar: Bar, enabled: Bool) {
              self.bar = bar
              self.enabled = enabled
          }

          private let bar: Bar
          @State private var enabled: Bool
      }
      """
    let options = FormatOptions(preferSynthesizedInitForInternalStructs: .always)
    testFormatting(for: input, rule: .redundantMemberwiseInit, options: options)
  }

  @Test func removePrivateACLFromPropertyWithCustomPropertyWrapper() {
    let input = """
      struct Foo {
          init(bar: Bar, value: String) {
              self.bar = bar
              self.value = value
          }

          private let bar: Bar
          @SomeCustomPropertyWrapper private var value: String
      }
      """
    let output = """
      struct Foo {
          let bar: Bar
          @SomeCustomPropertyWrapper var value: String
      }
      """
    let options = FormatOptions(preferSynthesizedInitForInternalStructs: .always)
    testFormatting(for: input, output, rule: .redundantMemberwiseInit, options: options)
  }

  @Test func preserveInitWhenPrivateVarWithDefaultValue() {
    // private var with default value is still part of memberwise init (optional param),
    // so synthesized init would be private
    let input = """
      struct Foo {
          init(foo: String) {
              self.foo = foo
          }

          let foo: String
          private var bar = "bar"
      }
      """
    testFormatting(for: input, rule: .redundantMemberwiseInit)
  }

  @Test func removeInitWhenPrivateLetWithDefaultValue() {
    // private let with default value is NOT part of memberwise init,
    // so it doesn't affect synthesized init visibility
    let input = """
      struct Foo {
          init(foo: String) {
              self.foo = foo
          }

          let foo: String
          private let bar = "bar"
      }
      """
    let output = """
      struct Foo {
          let foo: String
          private let bar = "bar"
      }
      """
    testFormatting(for: input, output, rule: .redundantMemberwiseInit)
  }

  @Test func removePrivateACLWithOrganizeDeclarations() {
    let input = """
      struct ProfileView: View {
          // MARK: Lifecycle

          init(user: User, settings: Settings) {
              self.user = user
              self.settings = settings
          }

          // MARK: Internal

          var body: some View { fatalError() }

          // MARK: Private

          @Environment(\\.colorScheme) private var colorScheme
          @State private var foo = "default"
          private let user: User
          private let settings: Settings
      }
      """
    let output = """
      struct ProfileView: View {
          // MARK: Internal

          let user: User
          let settings: Settings

          var body: some View { fatalError() }

          // MARK: Private

          @Environment(\\.colorScheme) private var colorScheme
          @State private var foo = "default"
      }
      """
    let options = FormatOptions(preferSynthesizedInitForInternalStructs: .always)
    testFormatting(
      for: input, [output],
      rules: [
        .redundantMemberwiseInit, .organizeDeclarations, .blankLinesAtEndOfScope,
        .blankLinesAtStartOfScope,
      ], options: options, exclude: [.wrapPropertyBodies],
    )
  }

  @Test func removeInitAndPrivateACLWhenPrivateVarWithDefaultValueAndOptionEnabled() {
    // With preferSynthesizedInitForInternalStructs enabled, we CAN remove the init
    // if there's a private var with default value, and we'll also remove its private ACL
    let input = """
      struct Foo {
          init(foo: String) {
              self.foo = foo
          }

          let foo: String
          private var bar = "default"
      }
      """
    let output = """
      struct Foo {
          let foo: String
          var bar = "default"
      }
      """
    let options = FormatOptions(preferSynthesizedInitForInternalStructs: .always)
    testFormatting(for: input, output, rule: .redundantMemberwiseInit, options: options)
  }

  @Test func removeInitWhenPrivateLetWithDefaultValueAndOptionEnabled() {
    // With preferSynthesizedInitForInternalStructs enabled, we CAN remove the init
    // if there's a private let with default value (not part of memberwise init)
    let input = """
      struct Foo {
          init(foo: String) {
              self.foo = foo
          }

          private let foo: String
          private let bar = "default"
      }
      """
    let output = """
      struct Foo {
          let foo: String
          private let bar = "default"
      }
      """
    let options = FormatOptions(preferSynthesizedInitForInternalStructs: .always)
    testFormatting(for: input, output, rule: .redundantMemberwiseInit, options: options)
  }

  @Test func preserveInitWithUnusedParameters() {
    // Init has parameters with `_` internal labels that are ignored.
    // This is not a memberwise init - it takes extra parameters.
    let input = """
      struct Foo {
          init(
              loggingID _: String,
              viewModel: ViewModel,
              context _: Context
          ) {
              self.viewModel = viewModel
          }

          let viewModel: ViewModel
      }
      """
    testFormatting(for: input, rule: .redundantMemberwiseInit)
  }

  // MARK: - conformances mode

  @Test func removePrivateACLForConformingStruct() {
    let input = """
      struct ProfileView: View {
          init(user: User) {
              self.user = user
          }

          private let user: User

          var body: some View {}
      }
      """
    let output = """
      struct ProfileView: View {
          let user: User

          var body: some View {}
      }
      """
    let options =
      FormatOptions(preferSynthesizedInitForInternalStructs: .conformances(["View"]))
    testFormatting(for: input, output, rule: .redundantMemberwiseInit, options: options)
  }

  @Test func dontRemovePrivateACLForNonConformingStruct() {
    let input = """
      struct ProfileModel {
          init(user: User) {
              self.user = user
          }

          private let user: User
      }
      """
    let options =
      FormatOptions(preferSynthesizedInitForInternalStructs: .conformances(["View"]))
    testFormatting(for: input, rule: .redundantMemberwiseInit, options: options)
  }

  @Test func removePrivateACLForMultipleConformances() {
    let input = """
      struct ProfileView: View, Equatable {
          init(user: User) {
              self.user = user
          }

          private let user: User

          var body: some View {}
      }
      """
    let output = """
      struct ProfileView: View, Equatable {
          let user: User

          var body: some View {}
      }
      """
    let options = FormatOptions(
      preferSynthesizedInitForInternalStructs: .conformances(["View", "ViewModifier"]),
    )
    testFormatting(for: input, output, rule: .redundantMemberwiseInit, options: options)
  }

  @Test func removePrivateACLForViewModifierConformance() {
    let input = """
      struct MyModifier: ViewModifier {
          init(isEnabled: Bool) {
              self.isEnabled = isEnabled
          }

          private let isEnabled: Bool

          func body(content: Content) -> some View {
              content
          }
      }
      """
    let output = """
      struct MyModifier: ViewModifier {
          let isEnabled: Bool

          func body(content: Content) -> some View {
              content
          }
      }
      """
    let options = FormatOptions(
      preferSynthesizedInitForInternalStructs: .conformances(["View", "ViewModifier"]),
    )
    testFormatting(for: input, output, rule: .redundantMemberwiseInit, options: options)
  }

  // MARK: - @ViewBuilder closure parameter handling

  @Test func removeInitWithViewBuilderClosureParameter() {
    let input = """
      struct MyView<Content: View>: View {
          let content: Content

          init(@ViewBuilder content: () -> Content) {
              self.content = content()
          }

          var body: some View {
              content
          }
      }
      """
    let output = """
      struct MyView<Content: View>: View {
          @ViewBuilder let content: Content

          var body: some View {
              content
          }
      }
      """
    let options = FormatOptions(swiftVersion: "6.4")
    testFormatting(for: input, output, rule: .redundantMemberwiseInit, options: options)
  }

  @Test func removeInitWithViewBuilderAndRegularParameters() {
    let input = """
      struct MyView<Content: View>: View {
          let title: String
          let content: Content

          init(title: String, @ViewBuilder content: () -> Content) {
              self.title = title
              self.content = content()
          }

          var body: some View {
              VStack {
                  Text(title)
                  content
              }
          }
      }
      """
    let output = """
      struct MyView<Content: View>: View {
          let title: String
          @ViewBuilder let content: Content

          var body: some View {
              VStack {
                  Text(title)
                  content
              }
          }
      }
      """
    let options = FormatOptions(swiftVersion: "6.4")
    testFormatting(for: input, output, rule: .redundantMemberwiseInit, options: options)
  }

  @Test func removeInitWithPrivateViewBuilderProperty() {
    // When preferSynthesizedInitForInternalStructs is .always, private ACL is removed
    // so the synthesized init can have internal access
    let input = """
      struct MyView<Content: View>: View {
          private let content: Content

          init(@ViewBuilder content: () -> Content) {
              self.content = content()
          }

          var body: some View {
              content
          }
      }
      """
    let output = """
      struct MyView<Content: View>: View {
          @ViewBuilder let content: Content

          var body: some View {
              content
          }
      }
      """
    let options = FormatOptions(
      preferSynthesizedInitForInternalStructs: .always, swiftVersion: "6.4",
    )
    testFormatting(for: input, output, rule: .redundantMemberwiseInit, options: options)
  }

  @Test func dontRemoveInitWithPrivateViewBuilderPropertyWithoutOption() {
    // Without preferSynthesizedInitForInternalStructs, we can't remove private ACL
    // so the synthesized init would be private, not matching the internal init
    let input = """
      struct MyView<Content: View>: View {
          private let content: Content

          init(@ViewBuilder content: () -> Content) {
              self.content = content()
          }

          var body: some View {
              content
          }
      }
      """
    // No options set, so init should be preserved
    testFormatting(for: input, rule: .redundantMemberwiseInit)
  }

  @Test func removeInitWithViewBuilderEscapingClosureParameter() {
    // When the init stores a closure directly (no invocation), we can still remove it
    // The @ViewBuilder attribute is transferred to the property
    let input = """
      struct MyView<Content: View>: View {
          let content: () -> Content

          init(@ViewBuilder content: @escaping () -> Content) {
              self.content = content
          }

          var body: some View {
              content()
          }
      }
      """
    let output = """
      struct MyView<Content: View>: View {
          @ViewBuilder let content: () -> Content

          var body: some View {
              content()
          }
      }
      """
    testFormatting(for: input, output, rule: .redundantMemberwiseInit)
  }

  @Test func dontRemoveInitWithNonEmptyClosureParameter() {
    // Closures with parameters like (Int) -> Content are not handled
    let input = """
      struct MyView<Content: View>: View {
          let content: Content

          init(@ViewBuilder content: (Int) -> Content) {
              self.content = content(0)
          }

          var body: some View {
              content
          }
      }
      """
    testFormatting(for: input, rule: .redundantMemberwiseInit)
  }

  @Test func dontRemoveInitWithViewBuilderWhenParameterOrderDiffers() {
    // The synthesized init uses property declaration order, not init parameter order
    // So we can't remove an init where the order differs
    let input = """
      struct MyView<Content: View>: View {
          let title: String
          let content: Content

          init(@ViewBuilder content: () -> Content, title: String) {
              self.content = content()
              self.title = title
          }

          var body: some View {
              Text(title)
              content
          }
      }
      """
    testFormatting(for: input, rule: .redundantMemberwiseInit)
  }

  @Test func removeInitWithMultipleViewBuilderParameters() {
    let input = """
      struct TwoColumnView<Left: View, Right: View>: View {
          let left: Left
          let right: Right

          init(@ViewBuilder left: () -> Left, @ViewBuilder right: () -> Right) {
              self.left = left()
              self.right = right()
          }

          var body: some View {
              HStack {
                  left
                  right
              }
          }
      }
      """
    let output = """
      struct TwoColumnView<Left: View, Right: View>: View {
          @ViewBuilder let left: Left
          @ViewBuilder let right: Right

          var body: some View {
              HStack {
                  left
                  right
              }
          }
      }
      """
    let options = FormatOptions(swiftVersion: "6.4")
    testFormatting(for: input, output, rule: .redundantMemberwiseInit, options: options)
  }

  @Test func removeInitWithCustomResultBuilder() {
    let input = """
      struct MyContainer<Content>: View {
          let content: Content

          init(@CustomBuilder content: () -> Content) {
              self.content = content()
          }

          var body: some View {
              // ...
          }
      }
      """
    let output = """
      struct MyContainer<Content>: View {
          @CustomBuilder let content: Content

          var body: some View {
              // ...
          }
      }
      """
    let options = FormatOptions(swiftVersion: "6.4")
    testFormatting(
      for: input, output, rule: .redundantMemberwiseInit, options: options,
      exclude: [.docComments],
    )
  }

  @Test func viewBuilderInitWithOrganizeDeclarationsPreservesPropertyOrder() {
    // When redundantMemberwiseInit removes an init with @ViewBuilder parameters,
    // the property order must be preserved so the synthesized init has the same API.
    // organizeDeclarations runs after redundantMemberwiseInit and should not reorder.
    let input = """
      struct Footer<ActionBar: View>: View {
          init(
              @ViewBuilder actionBar: () -> ActionBar,
              disclaimerText: String?,
              handler: Handler
          ) {
              self.actionBar = actionBar()
              self.disclaimerText = disclaimerText
              self.handler = handler
          }

          var body: some View {
              Text("test")
          }

          @Environment(\\.sizeClass) private var sizeClass

          private let actionBar: ActionBar
          private let disclaimerText: String?
          private let handler: Handler
      }
      """
    let output = """
      struct Footer<ActionBar: View>: View {
          // MARK: Internal

          @ViewBuilder let actionBar: ActionBar
          let disclaimerText: String?
          let handler: Handler

          var body: some View {
              Text("test")
          }

          // MARK: Private

          @Environment(\\.sizeClass) private var sizeClass
      }
      """
    let options = FormatOptions(
      markCategories: true,
      preferSynthesizedInitForInternalStructs: .conformances(["View"]),
      swiftVersion: "6.4",
    )
    testFormatting(
      for: input,
      [output],
      rules: [
        .redundantMemberwiseInit, .organizeDeclarations, .blankLinesAtStartOfScope,
        .blankLinesAtEndOfScope,
      ],
      options: options,
    )
  }

  @Test func removeInitWithGenericResultBuilder() {
    let input = """
      struct ItemList {
          let items: [String]

          init(@ArrayBuilder<String> items: () -> [String]) {
              self.items = items()
          }
      }
      """
    let output = """
      struct ItemList {
          @ArrayBuilder<String> let items: [String]
      }
      """
    let options = FormatOptions(swiftVersion: "6.4")
    testFormatting(for: input, output, rule: .redundantMemberwiseInit, options: options)
  }

  @Test func doesNotApplySynythesizedInitWithResultBuilderInNonGenericTypeSwift6_2() {
    // Result builder properties aren't supported properly in non-generic types before Swift 6.4:
    // https://github.com/swiftlang/swift/pull/86272
    let input = """
      struct ItemList {
          let items: [String]

          init(@ArrayBuilder<String> items: () -> [String]) {
              self.items = items()
          }
      }
      """
    let options = FormatOptions(swiftVersion: "6.2")
    testFormatting(for: input, rule: .redundantMemberwiseInit, options: options)
  }

  @Test func removeInitWithEscapingClosureParameter() {
    // Stored closure properties are implicitly escaping, so @escaping () -> Void parameter
    // is equivalent to () -> Void property.
    let input = """
      struct Button {
          let onTap: () -> Void

          init(onTap: @escaping () -> Void) {
              self.onTap = onTap
          }
      }
      """
    let output = """
      struct Button {
          let onTap: () -> Void
      }
      """
    testFormatting(for: input, output, rule: .redundantMemberwiseInit)
  }
}
