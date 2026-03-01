import Testing

@testable import Swiftiomatic

extension ParsingHelpersTests {
  // MARK: isConditionalStatement

  @Test func ifConditionContainingClosure() {
    let formatter = Formatter(
      tokenize(
        """
        if let btn = btns.first { !$0.isHidden } {}
        """,
      ),
    )
    #expect(formatter.isConditionalStatement(at: 12))
    #expect(formatter.isConditionalStatement(at: 21))
  }

  @Test func ifConditionContainingClosure2() {
    let formatter = Formatter(
      tokenize(
        """
        if let foo, let btn = btns.first { !$0.isHidden } {}
        """,
      ),
    )
    #expect(formatter.isConditionalStatement(at: 17))
    #expect(formatter.isConditionalStatement(at: 26))
  }

  // MARK: isAccessorKeyword

  @Test func didSet() {
    let formatter = Formatter(tokenize("var foo: Int { didSet {} }"))
    #expect(formatter.isAccessorKeyword(at: 9))
  }

  @Test func didSetWillSet() {
    let formatter = Formatter(
      tokenize(
        """
        var foo: Int {
            didSet {}
            willSet {}
        }
        """,
      ),
    )
    #expect(formatter.isAccessorKeyword(at: 10))
    #expect(formatter.isAccessorKeyword(at: 16))
  }

  @Test func getSet() {
    let formatter = Formatter(
      tokenize(
        """
        var foo: Int {
            get { return _foo }
            set { _foo = newValue }
        }
        """,
      ),
    )
    #expect(formatter.isAccessorKeyword(at: 10))
    #expect(formatter.isAccessorKeyword(at: 21))
  }

  @Test func setGet() {
    let formatter = Formatter(
      tokenize(
        """
        var foo: Int {
            set { _foo = newValue }
            get { return _foo }
        }
        """,
      ),
    )
    #expect(formatter.isAccessorKeyword(at: 10))
    #expect(formatter.isAccessorKeyword(at: 23))
  }

  @Test func genericSubscriptSetGet() {
    let formatter = Formatter(
      tokenize(
        """
        subscript<T>(index: Int) -> T {
            set { _foo[index] = newValue }
            get { return _foo[index] }
        }
        """,
      ),
    )
    #expect(formatter.isAccessorKeyword(at: 18))
    #expect(formatter.isAccessorKeyword(at: 34))
  }

  @Test func initAccessor() {
    let formatter = Formatter(
      tokenize(
        """
        var foo: Int {
            init {}
            get {}
            set {}
        }
        """,
      ),
    )
    #expect(formatter.isAccessorKeyword(at: 10))
    #expect(formatter.isAccessorKeyword(at: 16))
  }

  @Test func notGetter() {
    let formatter = Formatter(
      tokenize(
        """
        func foo() {
            set { print("") }
        }
        """,
      ),
    )
    #expect(!(formatter.isAccessorKeyword(at: 9)))
  }

  @Test func functionInGetterPosition() {
    let formatter = Formatter(
      tokenize(
        """
        var foo: Int {
            `get`()
            return 5
        }
        """,
      ),
    )
    #expect(formatter.isAccessorKeyword(at: 10, checkKeyword: false))
  }

  @Test func notSetterInit() {
    let formatter = Formatter(
      tokenize(
        """
        class Foo {
            init() { print("") }
        }
        """,
      ),
    )
    #expect(!(formatter.isAccessorKeyword(at: 7)))
  }

  // MARK: isEnumCase

  @Test func isEnumCase() {
    let formatter = Formatter(
      tokenize(
        """
        enum Foo {
            case foo, bar
            case baz
        }
        """,
      ),
    )
    #expect(formatter.isEnumCase(at: 7))
    #expect(formatter.isEnumCase(at: 15))
  }

  @Test func isEnumCaseWithValue() {
    let formatter = Formatter(
      tokenize(
        """
        enum Foo {
            case foo, bar(Int)
            case baz
        }
        """,
      ),
    )
    #expect(formatter.isEnumCase(at: 7))
    #expect(formatter.isEnumCase(at: 18))
  }

  @Test func isNotEnumCase() {
    let formatter = Formatter(
      tokenize(
        """
        if case let .foo(bar) = baz {}
        """,
      ),
    )
    #expect(!(formatter.isEnumCase(at: 2)))
  }

  @Test func typoIsNotEnumCase() {
    let formatter = Formatter(
      tokenize(
        """
        if let case .foo(bar) = baz {}
        """,
      ),
    )
    #expect(!(formatter.isEnumCase(at: 4)))
  }

  @Test func mixedCaseTypes() {
    let formatter = Formatter(
      tokenize(
        """
        enum Foo {
            case foo
            case bar(value: [Int])
        }

        func baz() {
            if case .foo = foo,
               case .bar(let value) = bar,
               value.isEmpty {}
        }
        """,
      ),
    )
    #expect(formatter.isEnumCase(at: 7))
    #expect(formatter.isEnumCase(at: 12))
    #expect(!(formatter.isEnumCase(at: 38)))
    #expect(!(formatter.isEnumCase(at: 49)))
  }

  // MARK: modifierOrder

  @Test func modifierOrder() {
    let options = FormatOptions(modifierOrder: ["convenience", "override"])
    let formatter = Formatter([], options: options)
    #expect(
      formatter.preferredModifierOrder == [
        "private", "fileprivate", "internal", "package", "public", "open",
        "private(set)", "fileprivate(set)", "internal(set)", "package(set)", "public(set)",
        "open(set)",
        "final",
        "dynamic",
        "optional", "required",
        "convenience",
        "override",
        "indirect",
        "isolated", "nonisolated", "nonisolated(unsafe)",
        "lazy",
        "weak", "unowned", "unowned(safe)", "unowned(unsafe)",
        "static", "class",
        "borrowing", "consuming", "mutating", "nonmutating",
        "prefix", "infix", "postfix",
        "async",
      ],
    )
  }

  @Test func modifierOrder2() {
    let options = FormatOptions(modifierOrder: [
      "override", "acl", "setterACL", "dynamic", "mutators",
      "lazy", "final", "required", "convenience", "typeMethods", "owned",
    ])
    let formatter = Formatter([], options: options)
    #expect(
      formatter.preferredModifierOrder == [
        "override",
        "private", "fileprivate", "internal", "package", "public", "open",
        "private(set)", "fileprivate(set)", "internal(set)", "package(set)", "public(set)",
        "open(set)",
        "dynamic",
        "indirect",
        "isolated", "nonisolated", "nonisolated(unsafe)",
        "static", "class",
        "borrowing", "consuming", "mutating", "nonmutating",
        "lazy",
        "final",
        "optional", "required",
        "convenience",
        "weak", "unowned", "unowned(safe)", "unowned(unsafe)",
        "prefix", "infix", "postfix",
        "async",
      ],
    )
  }

  // MARK: startOfModifiers

  @Test func startOfModifiers() {
    let formatter = Formatter(
      tokenize(
        """
        class Foo { @objc public required init() {} }
        """,
      ),
    )
    #expect(formatter.startOfModifiers(at: 12, includingAttributes: false) == 8)
  }

  @Test func startOfModifiersIncludingNonisolated() {
    let formatter = Formatter(
      tokenize(
        """
        actor Foo { nonisolated public func foo() {} }
        """,
      ),
    )
    #expect(formatter.startOfModifiers(at: 10, includingAttributes: true) == 6)
  }

  @Test func startOfModifiersIncludingAttributes() {
    let formatter = Formatter(
      tokenize(
        """
        class Foo { @objc public required init() {} }
        """,
      ),
    )
    #expect(formatter.startOfModifiers(at: 12, includingAttributes: true) == 6)
  }

  @Test func startOfPropertyModifiers() {
    let formatter = Formatter(
      tokenize(
        """
        @objc public class override var foo: Int?
        """,
      ),
    )
    #expect(formatter.startOfModifiers(at: 6, includingAttributes: true) == 0)
  }

  @Test func startOfPropertyModifiers2() {
    let formatter = Formatter(
      tokenize(
        """
        @objc(SFFoo) public var foo: Int?
        """,
      ),
    )
    #expect(formatter.startOfModifiers(at: 7, includingAttributes: false) == 5)
  }

  @Test func startOfPropertyModifiers3() {
    let formatter = Formatter(
      tokenize(
        """
        @OuterType.Wrapper var foo: Int?
        """,
      ),
    )
    #expect(formatter.startOfModifiers(at: 4, includingAttributes: true) == 0)
  }

  // MARK: processDeclaredVariables

  @Test func processCommaDelimitedDeclaredVariables() {
    let formatter = Formatter(
      tokenize(
        """
        let foo = bar(), x = y, baz = quux {}
        """,
      ),
    )
    var index = 2
    var names = Set<String>()
    formatter.processDeclaredVariables(at: &index, names: &names)
    #expect(names == ["foo", "x", "baz"])
    #expect(index == 22)
  }

  @Test func processDeclaredVariablesInIfCondition() {
    let formatter = Formatter(
      tokenize(
        """
        if let foo = bar(), x == y, let baz = quux {}
        """,
      ),
    )
    var index = 2
    var names = Set<String>()
    formatter.processDeclaredVariables(at: &index, names: &names)
    #expect(names == ["foo", "baz"])
    #expect(index == 26)
  }

  @Test func processDeclaredVariablesInIfWithParenthetical() {
    let formatter = Formatter(
      tokenize(
        """
        if let foo = bar(), (x == y), let baz = quux {}
        """,
      ),
    )
    var index = 2
    var names = Set<String>()
    formatter.processDeclaredVariables(at: &index, names: &names)
    #expect(names == ["foo", "baz"])
    #expect(index == 28)
  }

  @Test func processDeclaredVariablesInIfWithClosure() {
    let formatter = Formatter(
      tokenize(
        """
        if let foo = bar(), { x == y }(), let baz = quux {}
        """,
      ),
    )
    var index = 2
    var names = Set<String>()
    formatter.processDeclaredVariables(at: &index, names: &names)
    #expect(names == ["foo", "baz"])
    #expect(index == 32)
  }

  @Test func processDeclaredVariablesInIfWithNamedClosureArgument() {
    let formatter = Formatter(
      tokenize(
        """
        if let foo = bar, foo.bar(baz: { $0 }), let baz = quux {}
        """,
      ),
    )
    var index = 2
    var names = Set<String>()
    formatter.processDeclaredVariables(at: &index, names: &names)
    #expect(names == ["foo", "baz"])
    #expect(index == 32)
  }

  @Test func processDeclaredVariablesInIfAfterCase() {
    let formatter = Formatter(
      tokenize(
        """
        if case let .foo(bar, .baz(quux: 5)) = foo, let baz2 = quux2 {}
        """,
      ),
    )
    var index = 2
    var names = Set<String>()
    formatter.processDeclaredVariables(at: &index, names: &names)
    #expect(names == ["bar", "baz2"])
    #expect(index == 33)
  }

  @Test func processDeclaredVariablesInIfWithArrayLiteral() {
    let formatter = Formatter(
      tokenize(
        """
        if let foo = bar(), [x] == y, let baz = quux {}
        """,
      ),
    )
    var index = 2
    var names = Set<String>()
    formatter.processDeclaredVariables(at: &index, names: &names)
    #expect(names == ["foo", "baz"])
    #expect(index == 28)
  }

  @Test func processDeclaredVariablesInIfLetAs() {
    let formatter = Formatter(
      tokenize(
        """
        if let foo = foo as? String, let bar = baz {}
        """,
      ),
    )
    var index = 2
    var names = Set<String>()
    formatter.processDeclaredVariables(at: &index, names: &names)
    #expect(names == ["foo", "bar"])
    #expect(index == 22)
  }

  @Test func processDeclaredVariablesInIfLetWithPostfixOperator() {
    let formatter = Formatter(
      tokenize(
        """
        if let foo = baz?.foo, let bar = baz?.bar {}
        """,
      ),
    )
    var index = 2
    var names = Set<String>()
    formatter.processDeclaredVariables(at: &index, names: &names)
    #expect(names == ["foo", "bar"])
    #expect(index == 23)
  }

  @Test func processCaseDeclaredVariablesInIfLetCommaCase() {
    let formatter = Formatter(
      tokenize(
        """
        if let foo = bar(), case .bar(var baz) = quux {}
        """,
      ),
    )
    var index = 2
    var names = Set<String>()
    formatter.processDeclaredVariables(at: &index, names: &names)
    #expect(names == ["foo", "baz"])
    #expect(index == 25)
  }

  @Test func processCaseDeclaredVariablesInIfCaseLet() {
    let formatter = Formatter(
      tokenize(
        """
        if case let .foo(a: bar, b: baz) = quux {}
        """,
      ),
    )
    var index = 2
    var names = Set<String>()
    formatter.processDeclaredVariables(at: &index, names: &names)
    #expect(names == ["bar", "baz"])
    #expect(index == 23)
  }

  @Test func processTupleDeclaredVariablesInIfLetSyntax() {
    let formatter = Formatter(
      tokenize(
        """
        if let (bar, a: baz) = quux, let x = y {}
        """,
      ),
    )
    var index = 2
    var names = Set<String>()
    formatter.processDeclaredVariables(at: &index, names: &names)
    #expect(names == ["x", "bar", "baz"])
    #expect(index == 25)
  }

  @Test func processTupleDeclaredVariablesInIfLetSyntax2() {
    let formatter = Formatter(
      tokenize(
        """
        if let ((a: bar, baz), (x, y)) = quux {}
        """,
      ),
    )
    var index = 2
    var names = Set<String>()
    formatter.processDeclaredVariables(at: &index, names: &names)
    #expect(names == ["bar", "baz", "x", "y"])
    #expect(index == 26)
  }

  @Test func processAwaitVariableInForLoop() {
    let formatter = Formatter(
      tokenize(
        """
        for await foo in DoubleGenerator() {
            print(foo)
        }
        """,
      ),
    )
    var index = 0
    var names = Set<String>()
    formatter.processDeclaredVariables(at: &index, names: &names)
    #expect(names == ["foo"])
    #expect(index == 4)
  }

  @Test func processParametersInInit() {
    let formatter = Formatter(
      tokenize(
        """
        init(actor: Int, bar: String) {}
        """,
      ),
    )
    var index = 2
    var names = Set<String>()
    formatter.processDeclaredVariables(at: &index, names: &names)
    #expect(names == ["actor", "bar"])
    #expect(index == 11)
  }

  @Test func processGuardCaseLetVariables() {
    let formatter = Formatter(
      tokenize(
        """
        guard case let Foo.bar(foo) = baz
        else { return }
        """,
      ),
    )
    var index = 2
    var names = Set<String>()
    formatter.processDeclaredVariables(at: &index, names: &names)
    #expect(names == ["foo"])
    #expect(index == 15)
  }

  @Test func processLetDictionaryLiteralVariables() {
    let formatter = Formatter(
      tokenize(
        """
        let foo = [bar: 1, baz: 2]
        print(foo)
        """,
      ),
    )
    var index = 2
    var names = Set<String>()
    formatter.processDeclaredVariables(at: &index, names: &names)
    #expect(names == ["foo"])
    #expect(index == 17)
  }

  @Test func processLetStringLiteralFollowedByPrint() {
    let formatter = Formatter(
      tokenize(
        """
        let bar = "bar"
        print(bar)
        """,
      ),
    )
    var index = 2
    var names = Set<String>()
    formatter.processDeclaredVariables(at: &index, names: &names)
    #expect(names == ["bar"])
    #expect(index == 8)
  }

  @Test func processLetNumericLiteralFollowedByPrint() {
    let formatter = Formatter(
      tokenize(
        """
        let bar = 5
        print(bar)
        """,
      ),
    )
    var index = 2
    var names = Set<String>()
    formatter.processDeclaredVariables(at: &index, names: &names)
    #expect(names == ["bar"])
    #expect(index == 6)
  }

  @Test func processLetBooleanLiteralFollowedByPrint() {
    let formatter = Formatter(
      tokenize(
        """
        let bar = true
        print(bar)
        """,
      ),
    )
    var index = 2
    var names = Set<String>()
    formatter.processDeclaredVariables(at: &index, names: &names)
    #expect(names == ["bar"])
    #expect(index == 6)
  }

  @Test func processLetNilLiteralFollowedByPrint() {
    let formatter = Formatter(
      tokenize(
        """
        let bar: Bar? = nil
        print(bar)
        """,
      ),
    )
    var index = 2
    var names = Set<String>()
    formatter.processDeclaredVariables(at: &index, names: &names)
    #expect(names == ["bar"])
    #expect(index == 10)
  }

}
