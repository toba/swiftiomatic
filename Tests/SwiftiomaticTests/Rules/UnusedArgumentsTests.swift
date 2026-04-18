@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UnusedArgumentsTests: RuleTesting {

  // MARK: - Closures

  @Test func unusedTypedClosureArguments() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        let foo = { (1️⃣bar: Int, baz: String) in
            print("Hello \\(baz)")
        }
        """,
      expected: """
        let foo = { (_: Int, baz: String) in
            print("Hello \\(baz)")
        }
        """,
      findings: [FindingSpec("1️⃣", message: "closure parameter 'bar' is unused")])
  }

  @Test func unusedUntypedClosureArguments() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        let foo = { 1️⃣bar, baz in
            print("Hello \\(baz)")
        }
        """,
      expected: """
        let foo = { _, baz in
            print("Hello \\(baz)")
        }
        """,
      findings: [FindingSpec("1️⃣", message: "closure parameter 'bar' is unused")])
  }

  @Test func noRemoveClosureReturnType() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        let foo = { () -> Foo.Bar in baz() }
        """,
      expected: """
        let foo = { () -> Foo.Bar in baz() }
        """,
      findings: [])
  }

  @Test func noRemoveClosureThrows() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        let foo = { () throws in }
        """,
      expected: """
        let foo = { () throws in }
        """,
      findings: [])
  }

  @Test func closureTypeInClosureArgumentsIsNotMangled() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        { (1️⃣foo: (Int) -> Void) in }
        """,
      expected: """
        { (_: (Int) -> Void) in }
        """,
      findings: [FindingSpec("1️⃣", message: "closure parameter 'foo' is unused")])
  }

  @Test func unusedUnnamedClosureArguments() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        { (_ 1️⃣foo: Int, _ 2️⃣bar: Int) in }
        """,
      expected: """
        { (_: Int, _: Int) in }
        """,
      findings: [
        FindingSpec("1️⃣", message: "closure parameter 'foo' is unused"),
        FindingSpec("2️⃣", message: "closure parameter 'bar' is unused"),
      ])
  }

  @Test func unusedInoutClosureArguments() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        { (1️⃣foo: inout Foo, 2️⃣bar: inout Bar) in }
        """,
      expected: """
        { (_: inout Foo, _: inout Bar) in }
        """,
      findings: [
        FindingSpec("1️⃣", message: "closure parameter 'foo' is unused"),
        FindingSpec("2️⃣", message: "closure parameter 'bar' is unused"),
      ])
  }

  @Test func shadowedUsedClosureArguments() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        forEach { foo, bar in
            guard let foo = foo, let bar = bar else {
                return
            }
        }
        """,
      expected: """
        forEach { foo, bar in
            guard let foo = foo, let bar = bar else {
                return
            }
        }
        """,
      findings: [])
  }

  @Test func parameterUsedInForIn() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        forEach { foos in
            for foo in foos {
                print(foo)
            }
        }
        """,
      expected: """
        forEach { foos in
            for foo in foos {
                print(foo)
            }
        }
        """,
      findings: [])
  }

  @Test func parameterUsedInStringInterpolation() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        forEach { foo in
            print("\\(foo)")
        }
        """,
      expected: """
        forEach { foo in
            print("\\(foo)")
        }
        """,
      findings: [])
  }

  @Test func unusedThrowingClosureArgument() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        foo = { 1️⃣bar throws in "" }
        """,
      expected: """
        foo = { _ throws in "" }
        """,
      findings: [FindingSpec("1️⃣", message: "closure parameter 'bar' is unused")])
  }

  @Test func usedThrowingClosureArgument() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        let foo = { bar throws in bar + "" }
        """,
      expected: """
        let foo = { bar throws in bar + "" }
        """,
      findings: [])
  }

  @Test func unusedPropertyWrapperArgument() {
    // $note introduces both $note and note; skip
    assertFormatting(
      UnusedArguments.self,
      input: """
        ForEach($list.notes) { $note in
            Text(note.foobar)
        }
        """,
      expected: """
        ForEach($list.notes) { $note in
            Text(note.foobar)
        }
        """,
      findings: [])
  }

  @Test func closureArgumentUsedInGuardNotRemoved() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        bar(for: quux) { _, _, foo in
            guard
                let baz = quux.baz,
                foo.contains(where: { $0.baz == baz })
            else {
                return
            }
        }
        """,
      expected: """
        bar(for: quux) { _, _, foo in
            guard
                let baz = quux.baz,
                foo.contains(where: { $0.baz == baz })
            else {
                return
            }
        }
        """,
      findings: [])
  }

  // MARK: - Functions

  @Test func markUnusedFunctionArgument() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        func foo(1️⃣bar: Int, baz: String) {
            print("Hello \\(baz)")
        }
        """,
      expected: """
        func foo(bar _: Int, baz: String) {
            print("Hello \\(baz)")
        }
        """,
      findings: [FindingSpec("1️⃣", message: "parameter 'bar' is unused")])
  }

  @Test func markUnusedArgumentsInThrowsFunction() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        func foo(1️⃣bar: Int, baz: String) throws {
            print("Hello \\(baz)")
        }
        """,
      expected: """
        func foo(bar _: Int, baz: String) throws {
            print("Hello \\(baz)")
        }
        """,
      findings: [FindingSpec("1️⃣", message: "parameter 'bar' is unused")])
  }

  @Test func noMarkUnusedArgumentsInProtocolFunction() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        protocol Foo {
            func foo(bar: Int) -> Int
            var bar: Int { get }
        }
        """,
      expected: """
        protocol Foo {
            func foo(bar: Int) -> Int
            var bar: Int { get }
        }
        """,
      findings: [])
  }

  @Test func unusedUnnamedFunctionArgument() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        func foo(_ 1️⃣foo: Int) {}
        """,
      expected: """
        func foo(_: Int) {}
        """,
      findings: [FindingSpec("1️⃣", message: "parameter 'foo' is unused")])
  }

  @Test func unusedInoutFunctionArgument() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        func foo(_ 1️⃣foo: inout Foo) {}
        """,
      expected: """
        func foo(_: inout Foo) {}
        """,
      findings: [FindingSpec("1️⃣", message: "parameter 'foo' is unused")])
  }

  @Test func unusedInternallyRenamedFunctionArgument() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        func foo(foo 1️⃣bar: Int) {}
        """,
      expected: """
        func foo(foo _: Int) {}
        """,
      findings: [FindingSpec("1️⃣", message: "parameter 'bar' is unused")])
  }

  @Test func membersAreNotArguments() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        func foo(bar: Int, 1️⃣baz: String) {
            print("Hello \\(bar.baz)")
        }
        """,
      expected: """
        func foo(bar: Int, baz _: String) {
            print("Hello \\(bar.baz)")
        }
        """,
      findings: [FindingSpec("1️⃣", message: "parameter 'baz' is unused")])
  }

  @Test func dictionaryLiteralsCountAsUsage() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        func foo(bar: Int, baz: Int) {
            let quux = [bar: 1, baz: 2]
        }
        """,
      expected: """
        func foo(bar: Int, baz: Int) {
            let quux = [bar: 1, baz: 2]
        }
        """,
      findings: [])
  }

  @Test func operatorArgumentsAreUnnamed() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        func == (1️⃣lhs: Int, 2️⃣rhs: Int) { false }
        """,
      expected: """
        func == (_: Int, _: Int) { false }
        """,
      findings: [
        FindingSpec("1️⃣", message: "parameter 'lhs' is unused"),
        FindingSpec("2️⃣", message: "parameter 'rhs' is unused"),
      ])
  }

  @Test func unusedFailableInitArguments() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        init?(foo 1️⃣bar: Bar) {}
        """,
      expected: """
        init?(foo _: Bar) {}
        """,
      findings: [FindingSpec("1️⃣", message: "parameter 'bar' is unused")])
  }

  @Test func escapedArgumentsTreatedAsUsed() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        func foo(default: Int) -> Int {
            return `default`
        }
        """,
      expected: """
        func foo(default: Int) -> Int {
            return `default`
        }
        """,
      findings: [])
  }

  @Test func shadowedUnusedArguments() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        func foo(1️⃣bar: String, 2️⃣baz: Int) {
            let bar = "bar", baz = 5
            print(bar, baz)
        }
        """,
      expected: """
        func foo(bar _: String, baz _: Int) {
            let bar = "bar", baz = 5
            print(bar, baz)
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "parameter 'bar' is unused"),
        FindingSpec("2️⃣", message: "parameter 'baz' is unused"),
      ])
  }

  @Test func shadowedUsedArguments() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        func foo(things: [String], form: Form) {
            let form = FormRequest(
                things: things,
                form: form
            )
            print(form)
        }
        """,
      expected: """
        func foo(things: [String], form: Form) {
            let form = FormRequest(
                things: things,
                form: form
            )
            print(form)
        }
        """,
      findings: [])
  }

  @Test func shadowedUsedInSwitchCase() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        init(_ action: Action, 1️⃣hub: Hub) {
            switch action {
            case let .get(hub, key):
                self = .get(key, hub)
            }
        }
        """,
      expected: """
        init(_ action: Action, hub _: Hub) {
            switch action {
            case let .get(hub, key):
                self = .get(key, hub)
            }
        }
        """,
      findings: [FindingSpec("1️⃣", message: "parameter 'hub' is unused")])
  }

  @Test func conditionalIfLetMarkedAsUnused() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        func foo(1️⃣bar: UIViewController) {
            if let bar = baz {
                bar.loadViewIfNeeded()
            }
        }
        """,
      expected: """
        func foo(bar _: UIViewController) {
            if let bar = baz {
                bar.loadViewIfNeeded()
            }
        }
        """,
      findings: [FindingSpec("1️⃣", message: "parameter 'bar' is unused")])
  }

  @Test func functionLabelNotConfusedWithArgument() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        func g(1️⃣foo: Int) {
            f(foo: 42)
        }
        """,
      expected: """
        func g(foo _: Int) {
            f(foo: 42)
        }
        """,
      findings: [FindingSpec("1️⃣", message: "parameter 'foo' is unused")])
  }

  @Test func caseLetNotConfusedWithArgument() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        func f(e: TheEnum, 1️⃣bar: String) {
            switch e {
            case let .foo(bar):
                print(bar)
            }
        }
        """,
      expected: """
        func f(e: TheEnum, bar _: String) {
            switch e {
            case let .foo(bar):
                print(bar)
            }
        }
        """,
      findings: [FindingSpec("1️⃣", message: "parameter 'bar' is unused")])
  }

  @Test func parameterUsedInInit() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        init(m: Rotation) {
            let x = sqrt(max(0, m)) / 2
        }
        """,
      expected: """
        init(m: Rotation) {
            let x = sqrt(max(0, m)) / 2
        }
        """,
      findings: [])
  }

  @Test func usedParametersShadowedInAssignment() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        init(r: Double) {
            let r = max(abs(r), epsilon)
        }
        """,
      expected: """
        init(r: Double) {
            let r = max(abs(r), epsilon)
        }
        """,
      findings: [])
  }

  @Test func shadowedIfLetNotMarkedAsUnused() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        func method(_ foo: Int?, _ bar: String?) {
            if let foo = foo, let bar = bar {}
        }
        """,
      expected: """
        func method(_ foo: Int?, _ bar: String?) {
            if let foo = foo, let bar = bar {}
        }
        """,
      findings: [])
  }

  @Test func shorthandIfLetNotMarkedAsUnused() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        func method(_ foo: Int?, _ bar: String?) {
            if let foo, let bar {}
        }
        """,
      expected: """
        func method(_ foo: Int?, _ bar: String?) {
            if let foo, let bar {}
        }
        """,
      findings: [])
  }

  @Test func shadowedClosureNotMarkedUnused() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        func foo(bar: () -> Void) {
            let bar = {
                print("log")
                bar()
            }
            bar()
        }
        """,
      expected: """
        func foo(bar: () -> Void) {
            let bar = {
                print("log")
                bar()
            }
            bar()
        }
        """,
      findings: [])
  }

  @Test func shadowedClosureMarkedUnused() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        func foo(1️⃣bar: () -> Void) {
            let bar = {
                print("log")
            }
            bar()
        }
        """,
      expected: """
        func foo(bar _: () -> Void) {
            let bar = {
                print("log")
            }
            bar()
        }
        """,
      findings: [FindingSpec("1️⃣", message: "parameter 'bar' is unused")])
  }

  @Test func argumentUsedInMacro() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        @Test
        func something(value: String?) throws {
            let value = try #require(value)
            print(value)
        }
        """,
      expected: """
        @Test
        func something(value: String?) throws {
            let value = try #require(value)
            print(value)
        }
        """,
      findings: [])
  }

  // MARK: - Init

  @Test func markUnusedInitArgument() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        init(
            1️⃣bar: Int,
            baz: String
        ) {
            self.baz = baz
        }
        """,
      expected: """
        init(
            bar _: Int,
            baz: String
        ) {
            self.baz = baz
        }
        """,
      findings: [FindingSpec("1️⃣", message: "parameter 'bar' is unused")])
  }

  // MARK: - Subscripts

  @Test func markUnusedSubscriptArgument() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        subscript(1️⃣foo: Int, baz: String) -> String {
            return get(baz)
        }
        """,
      expected: """
        subscript(_: Int, baz: String) -> String {
            return get(baz)
        }
        """,
      findings: [FindingSpec("1️⃣", message: "parameter 'foo' is unused")])
  }

  @Test func markUnusedUnnamedSubscriptArgument() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        subscript(_ 1️⃣foo: Int, baz: String) -> String {
            return get(baz)
        }
        """,
      expected: """
        subscript(_: Int, baz: String) -> String {
            return get(baz)
        }
        """,
      findings: [FindingSpec("1️⃣", message: "parameter 'foo' is unused")])
  }

  @Test func markUnusedNamedSubscriptArgument() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        subscript(foo 1️⃣bar: Int, baz: String) -> String {
            return get(baz)
        }
        """,
      expected: """
        subscript(foo _: Int, baz: String) -> String {
            return get(baz)
        }
        """,
      findings: [FindingSpec("1️⃣", message: "parameter 'bar' is unused")])
  }

  // MARK: - For Loops

  @Test func unusedForLoopVariable() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        for 1️⃣value in array {
            print("hello")
        }
        """,
      expected: """
        for _ in array {
            print("hello")
        }
        """,
      findings: [FindingSpec("1️⃣", message: "for-loop variable 'value' is unused")])
  }

  @Test func usedForLoopVariable() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        for value in array {
            print(value)
        }
        """,
      expected: """
        for value in array {
            print(value)
        }
        """,
      findings: [])
  }

  @Test func unusedForLoopTupleVariable() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        for (key, 1️⃣value) in dictionary {
            print(key)
        }
        """,
      expected: """
        for (key, _) in dictionary {
            print(key)
        }
        """,
      findings: [FindingSpec("1️⃣", message: "for-loop variable 'value' is unused")])
  }

  @Test func unusedForLoopBothTupleVariables() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        for (1️⃣key, 2️⃣value) in dictionary {
            print("hello")
        }
        """,
      expected: """
        for (_, _) in dictionary {
            print("hello")
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "for-loop variable 'key' is unused"),
        FindingSpec("2️⃣", message: "for-loop variable 'value' is unused"),
      ])
  }

  @Test func forLoopVariableAlreadyUnderscore() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        for _ in array {
            print("hello")
        }
        """,
      expected: """
        for _ in array {
            print("hello")
        }
        """,
      findings: [])
  }

  @Test func forLoopVariableUsedInWhereClause() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        for value in array where value > 0 {
            print("positive")
        }
        """,
      expected: """
        for value in array where value > 0 {
            print("positive")
        }
        """,
      findings: [])
  }

  @Test func patternMatchingForLoopNotModified() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        for case let .foo(bar) in array {
            print(bar)
        }
        """,
      expected: """
        for case let .foo(bar) in array {
            print(bar)
        }
        """,
      findings: [])
  }

  @Test func forLoopVariableShadowingFunctionArgument() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        func foo(bar: [String]) {
            for bar in bar {
                print(bar)
            }
        }
        """,
      expected: """
        func foo(bar: [String]) {
            for bar in bar {
                print(bar)
            }
        }
        """,
      findings: [])
  }

  @Test func nestedForLoopOuterVariableUnused() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        for outer in array {
            for inner in outer {
                print(inner)
            }
        }
        """,
      expected: """
        for outer in array {
            for inner in outer {
                print(inner)
            }
        }
        """,
      findings: [])
  }

  @Test func nestedForLoopOuterVariableTrulyUnused() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        for 1️⃣outer in array {
            for inner in otherArray {
                print(inner)
            }
        }
        """,
      expected: """
        for _ in array {
            for inner in otherArray {
                print(inner)
            }
        }
        """,
      findings: [FindingSpec("1️⃣", message: "for-loop variable 'outer' is unused")])
  }

  @Test func forLoopInsideFunctionBody() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        func processItems(_ items: [String]) {
            for 1️⃣item in items {
                print("hello")
            }
        }
        """,
      expected: """
        func processItems(_ items: [String]) {
            for _ in items {
                print("hello")
            }
        }
        """,
      findings: [FindingSpec("1️⃣", message: "for-loop variable 'item' is unused")])
  }

  @Test func guardLetShadowsArgument() {
    assertFormatting(
      UnusedArguments.self,
      input: """
        func getTableInfo(forTable table: String) {
            guard let table = try? db.schema.objectDefinitions(name: table, type: .table).first else { return }
            print(table)
        }
        """,
      expected: """
        func getTableInfo(forTable table: String) {
            guard let table = try? db.schema.objectDefinitions(name: table, type: .table).first else { return }
            print(table)
        }
        """,
      findings: [])
  }

  @Test func argumentUsedInConditionalAssignment() {
    assertFormatting(
      UnusedArguments.self,
      input: """
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
        """,
      expected: """
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
        """,
      findings: [])
  }
}
