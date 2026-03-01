import Testing

@testable import Swiftiomatic

extension IndentTests {
  @Test func ifEndifInsideCaseNoIndenting2() {
    let input = """
      switch foo {
      case .bar:
      #if x
      bar()
      #endif
      baz()
      case .baz: break
      }
      """
    let output = """
      switch foo {
          case .bar:
              #if x
              bar()
              #endif
              baz()
          case .baz: break
      }
      """
    let options = FormatOptions(indentCase: true, ifdefIndent: .noIndent)
    testFormatting(
      for: input, output, rule: .indent, options: options,
      exclude: [.blankLineAfterSwitchCase],
    )
  }

  @Test func switchCaseInIfEndif() {
    let input = """
      func baz(value: Example) -> String {
          #if DEBUG
              switch value {
                  case .foo: return "foo"
                  case .bar: return "bar"
                  @unknown default: return "unknown"
              }
          #else
              switch value {
                  case .foo: return "foo"
                  case .bar: return "bar"
                  @unknown default: return "unknown"
              }
          #endif
      }
      """
    let options = FormatOptions(indentCase: true, ifdefIndent: .indent)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func switchCaseInIfEndifNoIndenting() {
    let input = """
      func baz(value: Example) -> String {
          #if DEBUG
          switch value {
              case .foo: return "foo"
              case .bar: return "bar"
              @unknown default: return "unknown"
          }
          #else
          switch value {
              case .foo: return "foo"
              case .bar: return "bar"
              @unknown default: return "unknown"
          }
          #endif
      }
      """
    let options = FormatOptions(indentCase: true, ifdefIndent: .noIndent)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func ifEndifInsideEnumNoIndenting() {
    let input = """
      enum Foo {
          case bar
          #if x
          case baz
          #endif
      }
      """
    let options = FormatOptions(ifdefIndent: .noIndent)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func ifEndifInsideEnumWithTrailingCommentNoIndenting() {
    let input = """
      enum Foo {
          case bar
          #if x
          case baz
          #endif // ends
      }
      """
    let options = FormatOptions(ifdefIndent: .noIndent)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func ifDefPostfixMemberSyntaxNoIndenting() {
    let input = """
      class Bar {
          func foo() {
              Text("Hello")
              #if os(iOS)
                  .font(.largeTitle)
              #elseif os(macOS)
                  .font(.headline)
              #else
                  .font(.headline)
              #endif
          }
      }
      """
    let options = FormatOptions(ifdefIndent: .noIndent)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func ifDefPostfixMemberSyntaxNoIndenting2() {
    let input = """
      func foo() {
          Button {
              "Hello"
          }
          #if DEBUG
          .foo()
          #else
          .bar()
          #endif
          .baz()
      }
      """
    let options = FormatOptions(ifdefIndent: .noIndent)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func ifDefPostfixMemberSyntaxNoIndenting3() {
    let input = """
      func foo() {
          Text(
              "Hello"
          )
          #if DEBUG
          .foo()
          #else
          .bar()
          #endif
          .baz()
      }
      """
    let options = FormatOptions(ifdefIndent: .noIndent)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func noIndentDotInitInsideIfdef() {
    let input = """
      func myFunc() -> String {
          #if DEBUG
          .init("foo")
          #elseif PROD
          .init("bar")
          #else
          .init("baz")
          #endif
      }
      """
    let options = FormatOptions(ifdefIndent: .noIndent)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func noIndentDotInitInsideIfdef2() {
    let input = """
      var title: Font {
          #if os(iOS)
          .init(style: .title2)
          #else
          .init(style: .title2, size: 40)
          #endif
      }
      """
    let options = FormatOptions(ifdefIndent: .noIndent)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func ifDefPostfixMemberSyntaxPreserveKeepsAlignment() {
    let input = """
      struct Example: View {
          var body: some View {
              Text("Example")
                  .frame(maxWidth: 500, alignment: .leading)
                  #if !os(tvOS)
                  .font(.system(size: 14, design: .monospaced))
                  #endif
                  .padding(10)
          }
      }
      """
    let options = FormatOptions(ifdefIndent: .preserve)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func ifDefPreserveWithinIndentedChain() {
    let input = """
      struct ContentView: View {
          var body: some View {
              VStack {
                  Text("Hello World")
              }
              .foregroundStyle(Color.white)
              #if os(iOS)
              .frame(maxWidth: .infinity, maxHeight: .infinity)
              #endif
          }
      }
      """
    let options = FormatOptions(ifdefIndent: .preserve)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func ifDefPreserveWithinNestedChainBlock() {
    let input = """
      struct ContentView: View {
          var body: some View {
              VStack {
                  Text("Hello World")
              }
              .foregroundStyle(Color.white)
              #if os(iOS)
              .background {
                  Color.black
              }
              #endif
          }
      }
      """
    let options = FormatOptions(ifdefIndent: .preserve)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func ifDefPreserveWithinNestedChainBlock2() {
    let input = """
      struct ContentView: View {
          var body: some View {
              VStack {
                  Text("Hello World")
              }
              .foregroundStyle(Color.white)
              #if os(iOS)
              .background {
                  Color.black
                      .overlay {
                          Color.white
                      }
              }
              #endif
          }
      }
      """
    let options = FormatOptions(ifdefIndent: .preserve)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func ifDefPreserveWithinNestedChainBlock3() {
    let input = """
      struct ContentView: View {
          var body: some View {
              VStack {
                  Text("Hello World")
              }
              .foregroundStyle(Color.white)
              #if os(iOS)
              .background {
                  Color.black
                      .overlay {
                          Color.white
                              .mask {
                                  Circle()
                              }
                      }
              }
              #endif
          }
      }
      """
    let options = FormatOptions(ifdefIndent: .preserve)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func ifDefPreserveWithinNestedChainBlock4() {
    let input = """
      struct ContentView: View {
          var body: some View {
              VStack {
                  Text("Hello World")
              }
              .foregroundStyle(Color.white)
              #if os(iOS)
              .background {
                  Color.black
                      .overlay {
                          Color.white
                              .mask {
                                  Circle()
                                      .overlay {
                                          Rectangle()
                                      }
                              }
                      }
              }
              #endif
          }
      }
      """
    let options = FormatOptions(ifdefIndent: .preserve)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func ifDefPreserveWithCommentBeforeModifier() {
    let input = """
      struct ContentView: View {
          var body: some View {
              Text("Hello")
                  .frame(maxWidth: 200)
                  #if os(iOS)
                  // comment about padding
                  .padding(4)
                  #endif
          }
      }
      """
    let options = FormatOptions(ifdefIndent: .preserve)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test(.disabled("Indent behavior differs from upstream SwiftFormat"))
  func ifDefPreserveWithMultiplePlatformBranches() {
    let input = """
      import SwiftUI
      import SwiftUIIntrospect
      import Testing

      @MainActor
      @Suite
      struct NavigationViewWithColumnsStyleTests {
          #if canImport(UIKit) && (os(iOS) || os(visionOS))
          typealias PlatformNavigationViewWithColumnsStyle = UISplitViewController
          #elseif canImport(UIKit) && os(tvOS)
          typealias PlatformNavigationViewWithColumnsStyle = UINavigationController
          #elseif canImport(AppKit)
          typealias PlatformNavigationViewWithColumnsStyle = NSSplitView
          #endif

          func testIntrospect() async throws {
              try await introspection(of: PlatformNavigationViewWithColumnsStyle.self) { spy in
                  NavigationView {
                      ZStack {
                          Color.red
                          Text("Something")
                      }
                  }
                  .navigationViewStyle(DoubleColumnNavigationViewStyle())
                  #if os(iOS) || os(visionOS)
                  .introspect(.navigationView(style: .columns), on: .iOS(.v13, .v14, .v15, .v16, .v17, .v18, .v26), .visionOS(.v1, .v2, .v26), customize: spy)
                  #elseif os(tvOS)
                  .introspect(.navigationView(style: .columns), on: .tvOS(.v13, .v14, .v15, .v16, .v17, .v18, .v26), customize: spy)
                  #elseif os(macOS)
                  .introspect(.navigationView(style: .columns), on: .macOS(.v10_15, .v11, .v12, .v13, .v14, .v15, .v26), customize: spy)
                  #endif
              }
          }

          func testIntrospectAsAncestor() async throws {
              try await introspection(of: PlatformNavigationViewWithColumnsStyle.self) { spy in
                  NavigationView {
                      ZStack {
                          Color.red
                          Text("Something")
                          #if os(iOS) || os(visionOS)
                          .introspect(.navigationView(style: .columns), on: .iOS(.v13, .v14, .v15, .v16, .v17, .v18, .v26), .visionOS(.v1, .v2, .v26), scope: .ancestor, customize: spy)
                          #elseif os(tvOS)
                          .introspect(.navigationView(style: .columns), on: .tvOS(.v13, .v14, .v15, .v16, .v17, .v18, .v26), scope: .ancestor, customize: spy)
                          #elseif os(macOS)
                          .introspect(.navigationView(style: .columns), on: .macOS(.v10_15, .v11, .v12, .v13, .v14, .v15, .v26), scope: .ancestor, customize: spy)
                          #endif
                      }
                  }
                  .navigationViewStyle(DoubleColumnNavigationViewStyle())
                  #if os(iOS)
                  // NB: this is necessary for ancestor introspection to work, because initially on iPad the "Customized" text isn't shown as it's hidden in the sidebar. This is why ancestor introspection is discouraged for most situations and it's opt-in.
                  .introspect(.navigationView(style: .columns), on: .iOS(.v13, .v14, .v15, .v16, .v17, .v18, .v26)) {
                      $0.preferredDisplayMode = .oneOverSecondary
                  }
                  #endif
              }
          }
      }
      """
    let options = FormatOptions(ifdefIndent: .preserve)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func ifDefPreserveMultipleModifiersInChain() {
    let input = """
      struct ContentView: View {
          var body: some View {
              Text("Example")
                  .frame(maxWidth: 200)
                  #if os(iOS)
                  .padding(4)
                  .background {
                      Color.red
                          .overlay {
                              Text("Inner")
                          }
                  }
                  .cornerRadius(8)
                  #endif
          }
      }
      """
    let options = FormatOptions(ifdefIndent: .preserve)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func ifDefPreserveWithElseIfBranches() {
    let input = """
      struct ContentView: View {
          var body: some View {
              Text("Example")
                  .frame(maxWidth: 200)
                  #if os(iOS)
                  .padding(4)
                      .background {
                          Color.red
                      }
                  #elseif os(macOS)
                  .padding(10)
                      .background {
                          Color.blue
                              .overlay {
                                  Circle()
                              }
                      }
                  #else
                  .foregroundColor(.gray)
                  .shadow(radius: 2)
                  #endif
          }
      }
      """
    let options = FormatOptions(ifdefIndent: .preserve)
    testFormatting(for: input, rule: .indent, options: options)
  }

  // indent #if/#else/#elseif/#endif (mode: outdent)

  @Test func ifEndifOutdenting() {
    let input = """
      #if x
      // foo
      #endif
      """
    let options = FormatOptions(ifdefIndent: .outdent)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func indentedIfEndifOutdenting() {
    let input = """
      {
      #if x
      // foo
      #endif
      }
      """
    let output = """
      {
      #if x
          // foo
      #endif
      }
      """
    let options = FormatOptions(ifdefIndent: .outdent)
    testFormatting(for: input, output, rule: .indent, options: options)
  }

  @Test func ifElseEndifOutdenting() {
    let input = """
      #if x
      // foo
      #else
      // bar
      #endif
      """
    let options = FormatOptions(ifdefIndent: .outdent)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func indentedIfElseEndifOutdenting() {
    let input = """
      {
      #if x
      // foo
      foo()
      #else
      // bar
      #endif
      }
      """
    let output = """
      {
      #if x
          // foo
          foo()
      #else
          // bar
      #endif
      }
      """
    let options = FormatOptions(ifdefIndent: .outdent)
    testFormatting(for: input, output, rule: .indent, options: options)
  }

  @Test func ifElseifEndifOutdenting() {
    let input = """
      #if x
      // foo
      #elseif y
      // bar
      #endif
      """
    let options = FormatOptions(ifdefIndent: .outdent)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func indentedIfElseifEndifOutdenting() {
    let input = """
      {
      #if x
      // foo
      foo()
      #elseif y
      // bar
      #endif
      }
      """
    let output = """
      {
      #if x
          // foo
          foo()
      #elseif y
          // bar
      #endif
      }
      """
    let options = FormatOptions(ifdefIndent: .outdent)
    testFormatting(for: input, output, rule: .indent, options: options)
  }

  @Test func nestedIndentedIfElseifEndifOutdenting() {
    let input = """
      {
      #if x
      #if y
      // foo
      foo()
      #elseif y
      // bar
      #endif
      #endif
      }
      """
    let output = """
      {
      #if x
      #if y
          // foo
          foo()
      #elseif y
          // bar
      #endif
      #endif
      }
      """
    let options = FormatOptions(ifdefIndent: .outdent)
    testFormatting(for: input, output, rule: .indent, options: options)
  }

  @Test func doubleNestedIndentedIfElseifEndifOutdenting() {
    let input = """
      {
      #if x
      #if y
      #if z
      // foo
      foo()
      #elseif y
      // bar
      #endif
      #endif
      #endif
      }
      """
    let output = """
      {
      #if x
      #if y
      #if z
          // foo
          foo()
      #elseif y
          // bar
      #endif
      #endif
      #endif
      }
      """
    let options = FormatOptions(ifdefIndent: .outdent)
    testFormatting(for: input, output, rule: .indent, options: options)
  }

  @Test func ifCaseEndifOutdenting() {
    let input = """
      switch foo {
      case .bar: break
      #if x
      case .baz: break
      #endif
      }
      """
    let options = FormatOptions(ifdefIndent: .outdent)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func ifEndifInsideEnumOutdenting() {
    let input = """
      enum Foo {
          case bar
      #if x
          case baz
      #endif
      }
      """
    let options = FormatOptions(ifdefIndent: .outdent)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func ifEndifInsideEnumWithTrailingCommentOutdenting() {
    let input = """
      enum Foo {
          case bar
      #if x
          case baz
      #endif // ends
      }
      """
    let options = FormatOptions(ifdefIndent: .outdent)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func ifDefPostfixMemberSyntaxOutdenting() {
    let input = """
      class Bar {
          func foo() {
              Text("Hello")
      #if os(iOS)
                  .font(.largeTitle)
      #elseif os(macOS)
                  .font(.headline)
      #else
                  .font(.headline)
      #endif
          }
      }
      """
    let options = FormatOptions(ifdefIndent: .outdent)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func ifDefPostfixMemberSyntaxOutdenting2() {
    let input = """
      func foo() {
          Button {
              "Hello"
          }
      #if DEBUG
          .foo()
      #else
          .bar()
      #endif
          .baz()
      }
      """
    let options = FormatOptions(ifdefIndent: .outdent)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func ifDefPostfixMemberSyntaxOutdenting3() {
    let input = """
      func foo() {
          Text(
              "Hello"
          )
      #if DEBUG
          .foo()
      #else
          .bar()
      #endif
          .baz()
      }
      """
    let options = FormatOptions(ifdefIndent: .outdent)
    testFormatting(for: input, rule: .indent, options: options)
  }

}
