import Testing

@testable import Swiftiomatic

extension UnusedArgumentsTests {
  @Test func conditionalIfLetMarkedAsUnused() {
    let input = """
      func foo(bar: UIViewController) {
          if let bar = baz {
              bar.loadViewIfNeeded()
          }
      }
      """
    let output = """
      func foo(bar _: UIViewController) {
          if let bar = baz {
              bar.loadViewIfNeeded()
          }
      }
      """
    testFormatting(for: input, output, rule: .unusedArguments)
  }

  @Test func conditionAfterIfCaseHoistedLetNotMarkedUnused() {
    let input = """
      func isLoadingFirst(for tabID: String) -> Bool {
          if case let .loading(.first(loadingTabID, _)) = requestState.status, loadingTabID == tabID {
              return true
          } else {
              return false
          }

          print(tabID)
      }
      """
    let options = FormatOptions(hoistPatternLet: true)
    testFormatting(for: input, rule: .unusedArguments, options: options)
  }

  @Test func conditionAfterIfCaseInlineLetNotMarkedUnused2() {
    let input = """
      func isLoadingFirst(for tabID: String) -> Bool {
          if case .loading(.first(let loadingTabID, _)) = requestState.status, loadingTabID == tabID {
              return true
          } else {
              return false
          }

          print(tabID)
      }
      """
    let options = FormatOptions(hoistPatternLet: false)
    testFormatting(for: input, rule: .unusedArguments, options: options)
  }

  @Test func conditionAfterIfCaseInlineLetNotMarkedUnused3() {
    let input = """
      private func isFocusedView(formDataID: FormDataID) -> Bool {
          guard
              case .selected(let selectedFormDataID) = currentState.selectedFormItemAction,
              selectedFormDataID == formDataID
          else {
              return false
          }

          return true
      }
      """
    let options = FormatOptions(hoistPatternLet: false)
    testFormatting(for: input, rule: .unusedArguments, options: options)
  }

  @Test func conditionAfterIfCaseInlineLetNotMarkedUnused4() {
    let input = """
      private func totalRowContent(priceItemsCount: Int, priceBreakdownStyle: PriceBreakdownStyle) {
          if
              case .all(let shouldCollapseByDefault, _) = priceBreakdownStyle,
              priceItemsCount > 0
          {
              // ..
          }
      }
      """
    let options = FormatOptions(hoistPatternLet: false)
    testFormatting(for: input, rule: .unusedArguments, options: options)
  }

  @Test func conditionAfterIfCaseInlineLetNotMarkedUnused5() {
    let input = """
      private mutating func clearPendingRemovals(itemIDs: Set<String>) {
          for change in changes {
              if case .removal(itemID: let itemID) = change, !itemIDs.contains(itemID) {
                  // ..
              }
          }
      }
      """
    let options = FormatOptions(hoistPatternLet: false)
    testFormatting(for: input, rule: .unusedArguments, options: options)
  }

  @Test func secondConditionAfterTupleMarkedUnused() {
    let input = """
      func foobar(bar: Int) {
          let (foo, baz) = (1, 2), bar = 3
          print(foo, bar, baz)
      }
      """
    let output = """
      func foobar(bar _: Int) {
          let (foo, baz) = (1, 2), bar = 3
          print(foo, bar, baz)
      }
      """
    testFormatting(
      for: input,
      output,
      rule: .unusedArguments,
      exclude: [.singlePropertyPerLine],
    )
  }

  @Test func unusedParamsInTupleAssignment() {
    let input = """
      func foobar(_ foo: Int, _ bar: Int, _ baz: Int, _ quux: Int) {
          let ((foo, bar), baz) = ((foo, quux), bar)
          print(foo, bar, baz, quux)
      }
      """
    let output = """
      func foobar(_ foo: Int, _ bar: Int, _: Int, _ quux: Int) {
          let ((foo, bar), baz) = ((foo, quux), bar)
          print(foo, bar, baz, quux)
      }
      """
    testFormatting(
      for: input,
      output,
      rule: .unusedArguments,
      exclude: [.singlePropertyPerLine],
    )
  }

  @Test func shadowedIfLetNotMarkedAsUnused() {
    let input = """
      func method(_ foo: Int?, _ bar: String?) {
          if let foo = foo, let bar = bar {}
      }
      """
    testFormatting(for: input, rule: .unusedArguments)
  }

  @Test func shorthandIfLetNotMarkedAsUnused() {
    let input = """
      func method(_ foo: Int?, _ bar: String?) {
          if let foo, let bar {}
      }
      """
    testFormatting(for: input, rule: .unusedArguments)
  }

  @Test func shorthandLetMarkedAsUnused() {
    let input = """
      func method(_ foo: Int?, _ bar: Int?) {
          var foo, bar: Int?
      }
      """
    let output = """
      func method(_: Int?, _: Int?) {
          var foo, bar: Int?
      }
      """
    testFormatting(
      for: input,
      output,
      rule: .unusedArguments,
      exclude: [.singlePropertyPerLine],
    )
  }

  @Test func shadowedClosureNotMarkedUnused() {
    let input = """
      func foo(bar: () -> Void) {
          let bar = {
              print("log")
              bar()
          }
          bar()
      }
      """
    testFormatting(for: input, rule: .unusedArguments)
  }

  @Test func shadowedClosureMarkedUnused() {
    let input = """
      func foo(bar: () -> Void) {
          let bar = {
              print("log")
          }
          bar()
      }
      """
    let output = """
      func foo(bar _: () -> Void) {
          let bar = {
              print("log")
          }
          bar()
      }
      """
    testFormatting(for: input, output, rule: .unusedArguments)
  }

  @Test func viewBuilderAnnotationDoesNotBreakUnusedArgDetection() {
    let input = """
      public struct Foo {
          let content: View

          public init(
              responsibleFileID: StaticString = #fileID,
              @ViewBuilder content: () -> View)
          {
              self.content = content()
          }
      }
      """
    let output = """
      public struct Foo {
          let content: View

          public init(
              responsibleFileID _: StaticString = #fileID,
              @ViewBuilder content: () -> View)
          {
              self.content = content()
          }
      }
      """
    testFormatting(
      for: input, output, rule: .unusedArguments,
      exclude: [.braces, .wrapArguments],
    )
  }

  @Test func argumentUsedInDictionaryLiteral() {
    let input = """
      class MyClass {
          func testMe(value: String) {
              let value = [
                  "key": value
              ]
              print(value)
          }
      }
      """
    testFormatting(
      for: input, rule: .unusedArguments,
      exclude: [.trailingCommas],
    )
  }

  @Test func argumentUsedAfterIfDefInsideSwitchBlock() {
    let input = """
      func test(string: String) {
          let number = 5
          switch number {
          #if DEBUG
              case 1:
                  print("ONE")
          #endif
          default:
              print("NOT ONE")
          }
          print(string)
      }
      """
    testFormatting(for: input, rule: .unusedArguments)
  }

  @Test func usedConsumingArgument() {
    let input = """
      func close(file: consuming FileHandle) {
          file.close()
      }
      """
    testFormatting(for: input, rule: .unusedArguments, exclude: [.noExplicitOwnership])
  }

  @Test func usedConsumingBorrowingArguments() {
    let input = """
      func foo(a: consuming Foo, b: borrowing Bar) {
          consume(a)
          borrow(b)
      }
      """
    testFormatting(for: input, rule: .unusedArguments, exclude: [.noExplicitOwnership])
  }

  @Test func unusedConsumingArgument() {
    let input = """
      func close(file: consuming FileHandle) {
          print("no-op")
      }
      """
    let output = """
      func close(file _: consuming FileHandle) {
          print("no-op")
      }
      """
    testFormatting(for: input, output, rule: .unusedArguments, exclude: [.noExplicitOwnership])
  }

  @Test func unusedConsumingBorrowingArguments() {
    let input = """
      func foo(a: consuming Foo, b: borrowing Bar) {
          print("no-op")
      }
      """
    let output = """
      func foo(a _: consuming Foo, b _: borrowing Bar) {
          print("no-op")
      }
      """
    testFormatting(for: input, output, rule: .unusedArguments, exclude: [.noExplicitOwnership])
  }

  @Test func functionArgumentUsedInGuardNotRemoved() {
    let input = """
      func scrollViewDidEndDecelerating(_ visibleDayRange: DayRange) {
          guard
              store.state.request.isIdle,
              let nextDayToLoad = store.state.request.nextCursor?.lowerBound,
              visibleDayRange.upperBound.distance(to: nextDayToLoad) < 30
          else {
              return
          }

          store.handle(.loadNext)
      }
      """
    testFormatting(for: input, rule: .unusedArguments)
  }

  @Test func functionArgumentUsedInGuardNotRemoved2() {
    let input = """
      func convert(
          filter: Filter,
          accounts: [Account],
          outgoingTotal: MulticurrencyTotal?,
      ) -> History? {
          guard
              let firstParameter = incomingTotal?.currency,
              let secondParameter = outgoingTotal?.currency,
              isFilter(filter, accounts: accounts)
          else {
              return nil
          }

          return History(firstParameter, secondParameter)
      }
      """
    testFormatting(for: input, rule: .unusedArguments, exclude: [.trailingCommas])
  }

  @Test func functionArgumentUsedInGuardNotRemoved3() {
    let input = """
      public func flagMessage(_ message: Message) {
        model.withState { state in
          guard
            let flagMessageFeature,
            shouldAllowFlaggingMessage(
              message,
              thread: state.thread)
          else { return }
        }
      }
      """
    testFormatting(
      for: input, rule: .unusedArguments,
      exclude: [.wrapArguments, .wrapConditionalBodies, .indent],
    )
  }

  // functions (closure-only)

  @Test func noMarkFunctionArgument() {
    let input = """
      func foo(_ bar: Int, baz: String) {
          print(\"Hello \\(baz)\")
      }
      """
    let options = FormatOptions(stripUnusedArguments: .closureOnly)
    testFormatting(for: input, rule: .unusedArguments, options: options)
  }

  // functions (unnamed-only)

  @Test func noMarkNamedFunctionArgument() {
    let input = """
      func foo(bar: Int, baz: String) {
          print(\"Hello \\(baz)\")
      }
      """
    let options = FormatOptions(stripUnusedArguments: .unnamedOnly)
    testFormatting(for: input, rule: .unusedArguments, options: options)
  }

  @Test func removeUnnamedFunctionArgument() {
    let input = """
      func foo(_ foo: Int) {}
      """
    let output = """
      func foo(_: Int) {}
      """
    let options = FormatOptions(stripUnusedArguments: .unnamedOnly)
    testFormatting(for: input, output, rule: .unusedArguments, options: options)
  }

  @Test func noRemoveInternalFunctionArgumentName() {
    let input = """
      func foo(foo bar: Int) {}
      """
    let options = FormatOptions(stripUnusedArguments: .unnamedOnly)
    testFormatting(for: input, rule: .unusedArguments, options: options)
  }

  // init

  @Test func markUnusedInitArgument() {
    let input = """
      init(
          bar: Int,
          baz: String,
      ) {
          self.baz = baz
      }
      """
    let output = """
      init(
          bar _: Int,
          baz: String,
      ) {
          self.baz = baz
      }
      """
    testFormatting(for: input, output, rule: .unusedArguments, exclude: [.trailingCommas])
  }

  // subscript

  @Test func markUnusedSubscriptArgument() {
    let input = """
      subscript(foo: Int, baz: String) -> String {
          return get(baz)
      }
      """
    let output = """
      subscript(_: Int, baz: String) -> String {
          return get(baz)
      }
      """
    testFormatting(for: input, output, rule: .unusedArguments)
  }

  @Test func markUnusedUnnamedSubscriptArgument() {
    let input = """
      subscript(_ foo: Int, baz: String) -> String {
          return get(baz)
      }
      """
    let output = """
      subscript(_: Int, baz: String) -> String {
          return get(baz)
      }
      """
    testFormatting(for: input, output, rule: .unusedArguments)
  }

  @Test func markUnusedNamedSubscriptArgument() {
    let input = """
      subscript(foo foo: Int, baz: String) -> String {
          return get(baz)
      }
      """
    let output = """
      subscript(foo _: Int, baz: String) -> String {
          return get(baz)
      }
      """
    testFormatting(for: input, output, rule: .unusedArguments)
  }

  @Test func unusedArgumentWithClosureShadowingParamName() {
    let input = """
      func test(foo: Foo) {
          let foo = {
              if foo.bar {
                  baaz
              } else {
                  bar
              }
          }()
          print(foo)
      }
      """
    testFormatting(for: input, rule: .unusedArguments)
  }

  @Test func unusedArgumentWithConditionalAssignmentShadowingParamName() {
    let input = """
      func test(foo: Foo) {
          let foo =
              if foo.bar {
                  baaz
              } else {
                  bar
              }
          print(foo)
      }
      """
    testFormatting(for: input, rule: .unusedArguments)
  }

  @Test func unusedArgumentWithSwitchAssignmentShadowingParamName() {
    let input = """
      func test(foo: Foo) {
          let foo =
              switch foo.bar {
              case true:
                  baaz
              case false:
                  bar
              }
          print(foo)
      }
      """
    testFormatting(for: input, rule: .unusedArguments)
  }

  @Test func unusedArgumentWithConditionalAssignmentNotShadowingParamName() {
    let input = """
      func test(bar: Bar) {
          let quux =
              if foo {
                  bar
              } else {
                  baaz
              }
          print(quux)
      }
      """
    testFormatting(for: input, rule: .unusedArguments)
  }

  @Test func issue1688_1() {
    let input = #"""
      func urlTestContains(path: String, strict _: Bool = true) -> Bool {
          let path = if path.hasSuffix("/") { path } else { "\(path)/" }

          return false
      }
      """#
    testFormatting(for: input, rule: .unusedArguments, exclude: [.wrapConditionalBodies])
  }

  @Test func issue1688_2() {
    let input = """
      enum Sample {
          func invite(lang: String, randomValue: Int) -> String {
              let flag: String? = if randomValue > 0 { "hello" } else { nil }

              let lang = if let flag { flag } else { lang }

              return lang
          }
      }
      """
    testFormatting(
      for: input, rule: .unusedArguments,
      exclude: [
        .wrapConditionalBodies,
        .redundantProperty,
      ],
    )
  }

  @Test func issue1694() {
    let input = """
      listenForUpdates() { [weak self] update, error in
          guard let update, error == nil else {
              return
          }

          self?.configure(update)
      }
      """
    testFormatting(for: input, rule: .unusedArguments, exclude: [.redundantParens])
  }

  @Test func issue1696() {
    let input = """
      func someFunction(with parameter: Int) -> Int {
          let parameter = max(
              200,
              parameter
          )
          return parameter
      }
      """
    testFormatting(for: input, rule: .unusedArguments, exclude: [.redundantProperty])
  }

  @Test func argumentUsedInsideMultilineStringLiteral() {
    // https://github.com/nicklockwood/SwiftFormat/issues/1847
    let input = #"""
      public func foo(message: String = "hi") {
          let message =
              """
              Message: \(message)
              """
          print(message)
      }
      """#
    testFormatting(for: input, rule: .unusedArguments)
  }

  @Test func argumentUsedInsideMultilineStringLiteral2() {
    let input = #"""
      func foo(message: String) {
          let message =
              """
              \(1 + 1)
              Message: \(message)
              """
          print(message)
      }
      """#
    testFormatting(for: input, rule: .unusedArguments)
  }

  @Test func argumentUsedInsideMultilineArrayLiteral() {
    let input = #"""
      func foo(message: String) {
          let message = [
              message,
          ]
          print(message)
      }
      """#
    testFormatting(for: input, rule: .unusedArguments)
  }

  @Test func issue1850() {
    let input = """
      init(a3: A42.ID) {
          a15.a22
              .sink {
                  Task {
                      switch a23.a27 {
                      #if !A34
                          case .a35:
                              A31.a32(.a33(.a34Failed))
                      #endif
                      case .a36:
                          break
                      }
                  }
              }
              .store(in: &a14)

          if a4.a57 == nil {
              a51 = a3.a.b?.a54
          }
      }
      """
    testFormatting(for: input, rule: .unusedArguments)
  }

  @Test func functionLabelNotConfusedWithArgument() {
    let input = """
      func g(foo: Int) {
          f(foo: 42)
      }
      """
    let output = """
      func g(foo _: Int) {
          f(foo: 42)
      }
      """
    testFormatting(for: input, output, rule: .unusedArguments)
  }

  @Test func subscriptLabelNotConfusedWithArgument() {
    let input = """
      func g(foo: Int) {
          f[foo: 42]
      }
      """
    let output = """
      func g(foo _: Int) {
          f[foo: 42]
      }
      """
    testFormatting(for: input, output, rule: .unusedArguments)
  }

  @Test func caseLetNotConfusedWithArgument() {
    let input = """
      func f(e: TheEnum, bar: String) {
          switch e {
          case let .foo(bar):
              print(bar)
          }
      }
      """
    let output = """
      func f(e: TheEnum, bar _: String) {
          switch e {
          case let .foo(bar):
              print(bar)
          }
      }
      """
    testFormatting(for: input, output, rule: .unusedArguments)
  }

  @Test func shadowedArgumentNameInGuard() {
    let input = """
      func getTableInfo(forTable table: String) {
          guard let table = try? db.schema.objectDefinitions(name: table, type: .table).first else { return nil }
          print(table)
      }
      """

    testFormatting(
      for: input, rule: .unusedArguments,
      exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements],
    )
  }

  @Test func shadowedArgumentNameInDoBlock() {
    let input = """
      func mapToResponse(_ jsonData: Data) -> Response {
          let jsonData = try! JSONSerialization.jsonObject(with: jsonData, options: []) as! [String: AnyObject]
          return Response(jsonData)
      }
      """

    testFormatting(for: input, rule: .unusedArguments)
  }

  @Test func unusedArgumentsWithAttributes() {
    let input = """
      func foo(
          @Attribute<Foo> foo: Bar,
          @Attribute bar baaz: Baaz,
          quux: Quux,
      ) {
          print(quux)
      }
      """

    let output = """
      func foo(
          @Attribute<Foo> foo _: Bar,
          @Attribute bar _: Baaz,
          quux: Quux,
      ) {
          print(quux)
      }
      """

    testFormatting(for: input, output, rule: .unusedArguments, exclude: [.trailingCommas])
  }

  @Test func argumentUsedInMacroTreatedAsUsed() {
    let input = """
      @Test
      func something(value: String?) throws {
          let value = try #require(value)
          print(value)
      }
      """

    testFormatting(for: input, rule: .unusedArguments)
  }

  @Test func ifdefCrash() {
    let input = """
      func test(unused: Int) {
          foo {
              if true {
                  #if FOO
                      switch 1 {
                      default: ()
                      }
                  #endif
              } else if true {
                  ()
              }
          }
      }
      """
    let output = """
      func test(unused _: Int) {
          foo {
              if true {
                  #if FOO
                      switch 1 {
                      default: ()
                      }
                  #endif
              } else if true {
                  ()
              }
          }
      }
      """
    testFormatting(for: input, output, rule: .unusedArguments)
  }
}
