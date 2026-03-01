import Testing

@testable import Swiftiomatic

@Suite struct UnusedArgumentsTests {
  // closures

  @Test func unusedTypedClosureArguments() {
    let input = """
      let foo = { (bar: Int, baz: String) in
          print(\"Hello \\(baz)\")
      }
      """
    let output = """
      let foo = { (_: Int, baz: String) in
          print(\"Hello \\(baz)\")
      }
      """
    testFormatting(for: input, output, rule: .unusedArguments)
  }

  @Test func unusedUntypedClosureArguments() {
    let input = """
      let foo = { bar, baz in
          print(\"Hello \\(baz)\")
      }
      """
    let output = """
      let foo = { _, baz in
          print(\"Hello \\(baz)\")
      }
      """
    testFormatting(for: input, output, rule: .unusedArguments)
  }

  @Test func noRemoveClosureReturnType() {
    let input = """
      let foo = { () -> Foo.Bar in baz() }
      """
    testFormatting(for: input, rule: .unusedArguments)
  }

  @Test func noRemoveClosureThrows() {
    let input = """
      let foo = { () throws in }
      """
    testFormatting(for: input, rule: .unusedArguments)
  }

  @Test func noRemoveClosureTypedThrows() {
    let input = """
      let foo = { () throws(Foo) in }
      """
    testFormatting(for: input, rule: .unusedArguments)
  }

  @Test func noRemoveClosureGenericReturnTypes() {
    let input = """
      let foo = { () -> Promise<String> in bar }
      """
    testFormatting(for: input, rule: .unusedArguments)
  }

  @Test func noRemoveClosureTupleReturnTypes() {
    let input = """
      let foo = { () -> (Int, Int) in (5, 6) }
      """
    testFormatting(for: input, rule: .unusedArguments)
  }

  @Test func noRemoveClosureGenericArgumentTypes() {
    let input = """
      let foo = { (_: Foo<Bar, Baz>) in }
      """
    testFormatting(for: input, rule: .unusedArguments)
  }

  @Test func noRemoveFunctionNameBeforeForLoop() {
    let input = """
      {
          func foo() -> Int {}
          for a in b {}
      }
      """
    testFormatting(for: input, rule: .unusedArguments)
  }

  @Test func closureTypeInClosureArgumentsIsNotMangled() {
    let input = """
      { (foo: (Int) -> Void) in }
      """
    let output = """
      { (_: (Int) -> Void) in }
      """
    testFormatting(for: input, output, rule: .unusedArguments)
  }

  @Test func unusedUnnamedClosureArguments() {
    let input = """
      { (_ foo: Int, _ bar: Int) in }
      """
    let output = """
      { (_: Int, _: Int) in }
      """
    testFormatting(for: input, output, rule: .unusedArguments)
  }

  @Test func unusedInoutClosureArgumentsNotMangled() {
    let input = """
      { (foo: inout Foo, bar: inout Bar) in }
      """
    let output = """
      { (_: inout Foo, _: inout Bar) in }
      """
    testFormatting(for: input, output, rule: .unusedArguments)
  }

  @Test func malformedFunctionNotMisidentifiedAsClosure() {
    let input = """
      func foo() { bar(5) {} in }
      """
    testFormatting(for: input, rule: .unusedArguments, exclude: [.wrapFunctionBodies])
  }

  @Test func shadowedUsedArguments() {
    let input = """
      forEach { foo, bar in
          guard let foo = foo, let bar = bar else {
              return
          }
      }
      """
    testFormatting(for: input, rule: .unusedArguments)
  }

  @Test func shadowedPartUsedArguments() {
    let input = """
      forEach { foo, bar in
          guard let foo = baz, bar == baz else {
              return
          }
      }
      """
    let output = """
      forEach { _, bar in
          guard let foo = baz, bar == baz else {
              return
          }
      }
      """
    testFormatting(for: input, output, rule: .unusedArguments)
  }

  @Test func shadowedParameterUsedInSameGuard() {
    let input = """
      forEach { foo in
          guard let foo = bar, baz = foo else {
              return
          }
      }
      """
    let output = """
      forEach { _ in
          guard let foo = bar, baz = foo else {
              return
          }
      }
      """
    testFormatting(for: input, output, rule: .unusedArguments)
  }

  @Test func parameterUsedInForIn() {
    let input = """
      forEach { foos in
          for foo in foos {
              print(foo)
          }
      }
      """
    testFormatting(for: input, rule: .unusedArguments)
  }

  @Test func parameterUsedInWhereClause() {
    let input = """
      forEach { foo in
          if bar where foo {
              print(bar)
          }
      }
      """
    testFormatting(for: input, rule: .unusedArguments)
  }

  @Test func parameterUsedInSwitchCase() {
    let input = """
      forEach { foo in
          switch bar {
          case let baz:
              foo = baz
          }
      }
      """
    testFormatting(for: input, rule: .unusedArguments)
  }

  @Test func parameterUsedInStringInterpolation() {
    let input = """
      forEach { foo in
          print("\\(foo)")
      }
      """
    testFormatting(for: input, rule: .unusedArguments)
  }

  @Test func shadowedClosureArgument() {
    let input = """
      _ = Parser<String, String> { input in
          let parser = Parser<String, String>.with(input)
          return parser
      }
      """
    testFormatting(
      for: input, rule: .unusedArguments, exclude: [.redundantProperty, .propertyTypes],
    )
  }

  @Test func shadowedClosureArgument2() {
    let input = """
      _ = foo { input in
          let input = ["foo": "Foo", "bar": "Bar"][input]
          return input
      }
      """
    testFormatting(for: input, rule: .unusedArguments, exclude: [.redundantProperty])
  }

  @Test func unusedPropertyWrapperArgument() {
    let input = """
      ForEach($list.notes) { $note in
          Text(note.foobar)
      }
      """
    testFormatting(for: input, rule: .unusedArguments)
  }

  @Test func unusedThrowingClosureArgument() {
    let input = """
      foo = { bar throws in \"\" }
      """
    let output = """
      foo = { _ throws in \"\" }
      """
    testFormatting(for: input, output, rule: .unusedArguments)
  }

  @Test func unusedTypedThrowingClosureArgument() {
    let input = """
      foo = { bar throws(Foo) in \"\" }
      """
    let output = """
      foo = { _ throws(Foo) in \"\" }
      """
    testFormatting(for: input, output, rule: .unusedArguments)
  }

  @Test func usedThrowingClosureArgument() {
    let input = """
      let foo = { bar throws in bar + \"\" }
      """
    testFormatting(for: input, rule: .unusedArguments)
  }

  @Test func usedTypedThrowingClosureArgument() {
    let input = """
      let foo = { bar throws(Foo) in bar + \"\" }
      """
    testFormatting(for: input, rule: .unusedArguments)
  }

  @Test func unusedTrailingAsyncClosureArgument() {
    let input = """
      app.get { foo async in
          print("No foo")
      }
      """
    let output = """
      app.get { _ async in
          print("No foo")
      }
      """
    testFormatting(for: input, output, rule: .unusedArguments)
  }

  @Test func unusedTrailingAsyncClosureArgument2() {
    let input = """
      app.get { foo async -> String in
          "No foo"
      }
      """
    let output = """
      app.get { _ async -> String in
          "No foo"
      }
      """
    testFormatting(for: input, output, rule: .unusedArguments)
  }

  @Test func unusedTrailingAsyncClosureArgument3() {
    let input = """
      app.get { (foo: String) async -> String in
          "No foo"
      }
      """
    let output = """
      app.get { (_: String) async -> String in
          "No foo"
      }
      """
    testFormatting(for: input, output, rule: .unusedArguments)
  }

  @Test func usedTrailingAsyncClosureArgument() {
    let input = """
      app.get { foo async -> String in
          "\\(foo)"
      }
      """
    testFormatting(for: input, rule: .unusedArguments)
  }

  @Test func trailingAsyncClosureArgumentAlreadyMarkedUnused() {
    let input = """
      app.get { _ async in 5 }
      """
    testFormatting(for: input, rule: .unusedArguments)
  }

  @Test func unusedTrailingClosureArgumentCalledAsync() {
    let input = """
      app.get { async -> String in
          "No async"
      }
      """
    let output = """
      app.get { _ -> String in
          "No async"
      }
      """
    testFormatting(for: input, output, rule: .unusedArguments)
  }

  @Test func closureArgumentUsedInGuardNotRemoved() {
    let input = """
      bar(for: quux) { _, _, foo in
          guard
              let baz = quux.baz,
              foo.contains(where: { $0.baz == baz })
          else {
              return
          }
      }
      """
    testFormatting(for: input, rule: .unusedArguments)
  }

  @Test func closureArgumentUsedInIfNotRemoved() {
    let input = """
      foo = { reservations, _ in
          if let reservations, eligibleToShow(
              reservations,
              accountService: accountService
          ) {
              coordinator.startFlow()
          }
      }
      """
    testFormatting(for: input, rule: .unusedArguments)
  }

  // init

  @Test func parameterUsedInInit() {
    let input = """
      init(m: Rotation) {
          let x = sqrt(max(0, m)) / 2
      }
      """
    testFormatting(for: input, rule: .unusedArguments)
  }

  @Test func unusedParametersShadowedInTupleAssignment() {
    let input = """
      init(x: Int, y: Int, v: Vector) {
          let (x, y) = v
      }
      """
    let output = """
      init(x _: Int, y _: Int, v: Vector) {
          let (x, y) = v
      }
      """
    testFormatting(for: input, output, rule: .unusedArguments)
  }

  @Test func usedParametersShadowedInAssignmentFromFunctionCall() {
    let input = """
      init(r: Double) {
          let r = max(abs(r), epsilon)
      }
      """
    testFormatting(for: input, rule: .unusedArguments)
  }

  @Test func shadowedUsedArgumentInSwitch() {
    let input = """
      init(_ action: Action, hub: Hub) {
          switch action {
          case let .get(hub, key):
              self = .get(key, hub)
          }
      }
      """
    let output = """
      init(_ action: Action, hub _: Hub) {
          switch action {
          case let .get(hub, key):
              self = .get(key, hub)
          }
      }
      """
    testFormatting(for: input, output, rule: .unusedArguments)
  }

  @Test func parameterUsedInSwitchCaseAfterShadowing() {
    let input = """
      func issue(name: String) -> String {
          switch self {
          case .b(let name): return name
          case .a: return name
          }
      }
      """
    testFormatting(
      for: input, rule: .unusedArguments
    )
  }

  // functions

  @Test func markUnusedFunctionArgument() {
    let input = """
      func foo(bar: Int, baz: String) {
          print(\"Hello \\(baz)\")
      }
      """
    let output = """
      func foo(bar _: Int, baz: String) {
          print(\"Hello \\(baz)\")
      }
      """
    testFormatting(for: input, output, rule: .unusedArguments)
  }

  @Test func markUnusedArgumentsInNonVoidFunction() {
    let input = """
      func foo(bar: Int, baz: String) -> (A<B, C>, D & E, [F: G]) { return baz.quux }
      """
    let output = """
      func foo(bar _: Int, baz: String) -> (A<B, C>, D & E, [F: G]) { return baz.quux }
      """
    testFormatting(for: input, output, rule: .unusedArguments, exclude: [.wrapFunctionBodies])
  }

  @Test func markUnusedArgumentsInThrowsFunction() {
    let input = """
      func foo(bar: Int, baz: String) throws {
          print(\"Hello \\(baz)\")
      }
      """
    let output = """
      func foo(bar _: Int, baz: String) throws {
          print(\"Hello \\(baz)\")
      }
      """
    testFormatting(for: input, output, rule: .unusedArguments)
  }

  @Test func markUnusedArgumentsInOptionalReturningFunction() {
    let input = """
      func foo(bar: Int, baz: String) -> String? {
          return \"Hello \\(baz)\"
      }
      """
    let output = """
      func foo(bar _: Int, baz: String) -> String? {
          return \"Hello \\(baz)\"
      }
      """
    testFormatting(for: input, output, rule: .unusedArguments)
  }

  @Test func noMarkUnusedArgumentsInProtocolFunction() {
    let input = """
      protocol Foo {
          func foo(bar: Int) -> Int
          var bar: Int { get }
      }
      """
    testFormatting(for: input, rule: .unusedArguments)
  }

  @Test func unusedUnnamedFunctionArgument() {
    let input = """
      func foo(_ foo: Int) {}
      """
    let output = """
      func foo(_: Int) {}
      """
    testFormatting(for: input, output, rule: .unusedArguments)
  }

  @Test func unusedInoutFunctionArgumentIsNotMangled() {
    let input = """
      func foo(_ foo: inout Foo) {}
      """
    let output = """
      func foo(_: inout Foo) {}
      """
    testFormatting(for: input, output, rule: .unusedArguments)
  }

  @Test func unusedInternallyRenamedFunctionArgument() {
    let input = """
      func foo(foo bar: Int) {}
      """
    let output = """
      func foo(foo _: Int) {}
      """
    testFormatting(for: input, output, rule: .unusedArguments)
  }

  @Test func noMarkProtocolFunctionArgument() {
    let input = """
      func foo(foo bar: Int)
      var bar: Bool { get }
      """
    testFormatting(for: input, rule: .unusedArguments, exclude: [.wrapPropertyBodies])
  }

  @Test func membersAreNotArguments() {
    let input = """
      func foo(bar: Int, baz: String) {
          print(\"Hello \\(bar.baz)\")
      }
      """
    let output = """
      func foo(bar: Int, baz _: String) {
          print(\"Hello \\(bar.baz)\")
      }
      """
    testFormatting(for: input, output, rule: .unusedArguments)
  }

  @Test func labelsAreNotArguments() {
    let input = """
      func foo(bar: Int, baz: String) {
          bar: while true { print(baz) }
      }
      """
    let output = """
      func foo(bar _: Int, baz: String) {
          bar: while true { print(baz) }
      }
      """
    testFormatting(for: input, output, rule: .unusedArguments, exclude: [.wrapLoopBodies])
  }

  @Test func dictionaryLiteralsRuinEverything() {
    let input = """
      func foo(bar: Int, baz: Int) {
          let quux = [bar: 1, baz: 2]
      }
      """
    testFormatting(for: input, rule: .unusedArguments)
  }

  @Test func operatorArgumentsAreUnnamed() {
    let input = """
      func == (lhs: Int, rhs: Int) { false }
      """
    let output = """
      func == (_: Int, _: Int) { false }
      """
    testFormatting(for: input, output, rule: .unusedArguments, exclude: [.wrapFunctionBodies])
  }

  @Test func unusedtFailableInitArgumentsAreNotMangled() {
    let input = """
      init?(foo: Bar) {}
      """
    let output = """
      init?(foo _: Bar) {}
      """
    testFormatting(for: input, output, rule: .unusedArguments)
  }

  @Test func treatEscapedArgumentsAsUsed() {
    let input = """
      func foo(default: Int) -> Int {
          return `default`
      }
      """
    testFormatting(for: input, rule: .unusedArguments)
  }

  @Test func partiallyMarkedUnusedArguments() {
    let input = """
      func foo(bar: Bar, baz _: Baz) {}
      """
    let output = """
      func foo(bar _: Bar, baz _: Baz) {}
      """
    testFormatting(for: input, output, rule: .unusedArguments)
  }

  @Test func partiallyMarkedUnusedArguments2() {
    let input = """
      func foo(bar _: Bar, baz: Baz) {}
      """
    let output = """
      func foo(bar _: Bar, baz _: Baz) {}
      """
    testFormatting(for: input, output, rule: .unusedArguments)
  }

  @Test func unownedUnsafeNotStripped() {
    let input = """
      func foo() {
          var num = 0
          Just(1)
              .sink { [unowned(unsafe) self] in
                  num += $0
              }
      }
      """
    testFormatting(for: input, rule: .unusedArguments)
  }

  @Test func shadowedUnusedArguments() {
    let input = """
      func foo(bar: String, baz: Int) {
          let bar = "bar", baz = 5
          print(bar, baz)
      }
      """
    let output = """
      func foo(bar _: String, baz _: Int) {
          let bar = "bar", baz = 5
          print(bar, baz)
      }
      """
    testFormatting(
      for: input,
      output,
      rule: .unusedArguments,
      exclude: [.singlePropertyPerLine],
    )
  }

  @Test func shadowedUsedArguments2() {
    let input = """
      func foo(things: [String], form: Form) {
          let form = FormRequest(
              things: things,
              form: form
          )
          print(form)
      }
      """
    testFormatting(for: input, rule: .unusedArguments)
  }

  @Test func shadowedUsedArguments3() {
    let input = """
      func zoomTo(locations: [Foo], count: Int) {
          let num = count
          guard num > 0, locations.count >= count else {
              return
          }

          print(locations)
      }
      """
    testFormatting(for: input, rule: .unusedArguments)
  }

  @Test func shadowedUsedArguments4() {
    let input = """
      func foo(bar: Int) {
          if let bar = baz {
              return
          }
          print(bar)
      }
      """
    testFormatting(for: input, rule: .unusedArguments)
  }

  @Test func shadowedUsedArguments5() {
    let input = """
      func doSomething(with number: Int) {
          if let number = Int?(123),
             number == 456
          {
              print("Not likely")
          }

          if number == 180 {
              print("Bullseye!")
          }
      }
      """
    testFormatting(for: input, rule: .unusedArguments)
  }

  @Test func shadowedUsedArgumentInSwitchCase() {
    let input = """
      func foo(bar baz: Foo) -> Foo? {
          switch (a, b) {
          case (0, _),
               (_, nil):
              return .none
          case let (1, baz?):
              return .bar(baz)
          default:
              return baz
          }
      }
      """
    testFormatting(
      for: input, rule: .unusedArguments,
      exclude: [.sortSwitchCases],
    )
  }

  @Test func tryArgumentNotMarkedUnused() {
    let input = """
      func foo(bar: String) throws -> String? {
          let bar =
              try parse(bar)
          return bar
      }
      """
    testFormatting(for: input, rule: .unusedArguments, exclude: [.redundantProperty])
  }

  @Test func tryAwaitArgumentNotMarkedUnused() {
    let input = """
      func foo(bar: String) async throws -> String? {
          let bar = try
              await parse(bar)
          return bar
      }
      """
    testFormatting(for: input, rule: .unusedArguments, exclude: [.redundantProperty])
  }

  @Test func typedTryAwaitArgumentNotMarkedUnused() {
    let input = """
      func foo(bar: String) async throws(Foo) -> String? {
          let bar = try
              await parse(bar)
          return bar
      }
      """
    testFormatting(for: input, rule: .unusedArguments, exclude: [.redundantProperty])
  }

}
