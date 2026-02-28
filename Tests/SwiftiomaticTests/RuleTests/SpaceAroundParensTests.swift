import Testing
@testable import Swiftiomatic

@Suite struct SpaceAroundParensTests {
    static let cases: [FormatCase] = [
        // Add space after access modifier
        FormatCase("spaceAfterSet",
            input: "private(set)var foo: Int",
            output: "private(set) var foo: Int"),
        FormatCase("addSpaceBetweenParenAndClass",
            input: "@objc(XYZFoo)class foo",
            output: "@objc(XYZFoo) class foo"),
        FormatCase("addSpaceBetweenConventionAndBlock",
            input: "@convention(block)() -> Void",
            output: "@convention(block) () -> Void"),
        FormatCase("addSpaceBetweenConventionAndEscaping",
            input: "@convention(block)@escaping () -> Void",
            output: "@convention(block) @escaping () -> Void"),
        FormatCase("addSpaceBetweenAutoclosureEscapingAndBlock",
            input: "@autoclosure(escaping)() -> Void",
            output: "@autoclosure(escaping) () -> Void"),

        // No-change for Sendable/MainActor
        FormatCase("addSpaceBetweenSendableAndBlock",
            input: "@Sendable (Action) -> Void"),
        FormatCase("addSpaceBetweenMainActorAndBlock",
            input: "@MainActor (Action) -> Void"),
        FormatCase("addSpaceBetweenMainActorAndBlock2",
            input: "@MainActor (@MainActor (Action) -> Void) async -> Void"),
        FormatCase("addSpaceBetweenMainActorAndClosureParams",
            input: "{ @MainActor (foo: Int) in foo }"),
        FormatCase("spaceBetweenUncheckedAndSendable",
            input: """
            enum Foo: @unchecked Sendable {
                case bar
            }
            """),

        // Remove space before parens
        FormatCase("spaceBetweenParenAndFoo",
            input: "func foo ()",
            output: "func foo()"),
        FormatCase("spaceBetweenParenAndAny",
            input: "func any ()",
            output: "func any()"),
        FormatCase("spaceBetweenParenAndAnyType",
            input: "let foo: any(A & B).Type",
            output: "let foo: any (A & B).Type"),
        FormatCase("spaceBetweenParenAndSomeType",
            input: "func foo() -> some(A & B).Type",
            output: "func foo() -> some (A & B).Type"),
        FormatCase("noSpaceBetweenParenAndInit",
            input: "init ()",
            output: "init()"),
        FormatCase("noSpaceBetweenObjcAndSelector",
            input: "@objc (XYZFoo) class foo",
            output: "@objc(XYZFoo) class foo"),
        FormatCase("noSpaceBetweenHashSelectorAndBrace",
            input: "#selector(foo)"),
        FormatCase("noSpaceBetweenHashKeyPathAndBrace",
            input: "#keyPath (foo.bar)",
            output: "#keyPath(foo.bar)"),
        FormatCase("noSpaceBetweenHashAvailableAndBrace",
            input: "#available (iOS 9.0, *)",
            output: "#available(iOS 9.0, *)"),
        FormatCase("noSpaceBetweenPrivateAndSet",
            input: "private (set) var foo: Int",
            output: "private(set) var foo: Int"),
        FormatCase("spaceBetweenLetAndTuple",
            input: "if let (foo, bar) = baz {}"),
        FormatCase("spaceBetweenIfAndCondition",
            input: "if(a || b) == true {}",
            output: "if (a || b) == true {}"),
        FormatCase("noSpaceBetweenArrayLiteralAndParen",
            input: "[String] ()",
            output: "[String]()"),

        // Capture list + arguments
        FormatCase("addSpaceBetweenCaptureListAndArguments4",
            input: "{ [weak self](foo: @escaping(Bar?) -> Void) -> Baz? in foo }",
            output: "{ [weak self] (foo: @escaping (Bar?) -> Void) -> Baz? in foo }"),
        FormatCase("addSpaceBetweenCaptureListAndArguments5",
            input: "{ [weak self](foo: @autoclosure() -> String) -> Baz? in foo() }",
            output: "{ [weak self] (foo: @autoclosure () -> String) -> Baz? in foo() }"),
        FormatCase("addSpaceBetweenCaptureListAndArguments6",
            input: "{ [weak self](foo: @Sendable() -> String) -> Baz? in foo() }",
            output: "{ [weak self] (foo: @Sendable () -> String) -> Baz? in foo() }"),

        // Escaping/autoclosure spacing
        FormatCase("addSpaceBetweenEscapingAndParenthesizedClosure",
            input: "@escaping(() -> Void)",
            output: "@escaping (() -> Void)"),
        FormatCase("addSpaceBetweenAutoclosureAndParenthesizedClosure",
            input: "@autoclosure(() -> String)",
            output: "@autoclosure (() -> String)"),

        // Keyword-as-identifier
        FormatCase("keywordAsIdentifierParensSpacing",
            input: "if foo.let (foo, bar) {}",
            output: "if foo.let(foo, bar) {}"),

        // inout/escaping/sendable attribute spacing
        FormatCase("spaceAfterInoutParam",
            input: "func foo(bar _: inout(Int, String)) {}",
            output: "func foo(bar _: inout (Int, String)) {}"),
        FormatCase("spaceAfterEscapingAttribute",
            input: "func foo(bar: @escaping() -> Void)",
            output: "func foo(bar: @escaping () -> Void)"),
        FormatCase("spaceAfterAutoclosureAttribute",
            input: "func foo(bar: @autoclosure () -> Void)"),
        FormatCase("spaceAfterSendableAttribute",
            input: "func foo(bar: @Sendable () -> Void)"),

        // Tuple index spacing
        FormatCase("spaceBeforeTupleIndexArgument",
            input: "foo.1 (true)",
            output: "foo.1(true)"),

        // Bracket + paren spacing
        FormatCase("removeSpaceBetweenParenAndBracket",
            input: "let foo = bar[5] ()",
            output: "let foo = bar[5]()"),
        FormatCase("removeSpaceBetweenParenAndBracketInsideClosure",
            input: "let foo = bar { [Int] () }",
            output: "let foo = bar { [Int]() }"),

        // Capture list
        FormatCase("addSpaceBetweenParenAndCaptureList",
            input: "let foo = bar { [self](foo: Int) in foo }",
            output: "let foo = bar { [self] (foo: Int) in foo }"),

        // await/unsafe/consume
        FormatCase("addSpaceBetweenParenAndAwait",
            input: "let foo = await(bar: 5)",
            output: "let foo = await (bar: 5)"),
        FormatCase("addSpaceBetweenParenAndUnsafe",
            input: "unsafe([\"sudo\"] + args).map { unsafe strdup($0) }",
            output: "unsafe ([\"sudo\"] + args).map { unsafe strdup($0) }"),
        FormatCase("removeSpaceBetweenParenAndConsume",
            input: "let foo = consume (bar)",
            output: "let foo = consume(bar)"),

        // @available after func
        FormatCase("noAddSpaceBetweenParenAndAvailableAfterFunc",
            input: """
            func foo()

            @available(macOS 10.13, *)
            func bar()
            """),

        // Typed throws
        FormatCase("noAddSpaceAroundTypedThrowsFunctionType",
            input: "func foo() throws (Bar) -> Baz {}",
            output: "func foo() throws(Bar) -> Baz {}"),

        // isolated/sending/borrowing
        FormatCase("addSpaceBetweenParenAndIsolated",
            input: "func foo(isolation _: isolated(any Actor)) {}",
            output: "func foo(isolation _: isolated (any Actor)) {}"),
        FormatCase("addSpaceBetweenParenAndSending",
            input: "func foo(_: sending(any Foo)) {}",
            output: "func foo(_: sending (any Foo)) {}"),

        // of/as/is tuple spacing
        FormatCase("ofTupleSpacing",
            input: "let foo: [4 of(String, Int)]",
            output: "let foo: [4 of (String, Int)]"),
        FormatCase("ofIdentifierParenSpacing",
            input: "if foo.of(String.self) {}"),
        FormatCase("asTupleCastingSpacing",
            input: "foo as(String, Int)",
            output: "foo as (String, Int)"),
        FormatCase("asOptionalTupleCastingSpacing",
            input: "foo as? (String, Int)"),
        FormatCase("isTupleTestingSpacing",
            input: "if foo is(String, Int) {}",
            output: "if foo is (String, Int) {}"),
        FormatCase("isIdentifierParenSpacing",
            input: "if foo.is(String.self, Int.self) {}"),
        FormatCase("spaceBeforeTupleIndexCall",
            input: "foo.1 (2)",
            output: "foo.1(2)"),
    ]

    @Test(arguments: Self.cases)
    func spaceAroundParens(_ c: FormatCase) {
        testFormatting(for: c.input, c.output, rule: .spaceAroundParens)
    }

    // MARK: - Cases with exclude or options

    @Test func spaceBetweenParenAndAs() {
        let input = """
        (foo.bar) as? String
        """
        testFormatting(for: input, rule: .spaceAroundParens, exclude: [.redundantParens])
    }

    @Test func noSpaceAfterParenAtEndOfFile() {
        let input = """
        (foo.bar)
        """
        testFormatting(for: input, rule: .spaceAroundParens, exclude: [.redundantParens])
    }

    @Test func addSpaceBetweenCaptureListAndArguments() {
        let input = """
        { [weak self](foo) in print(foo) }
        """
        let output = """
        { [weak self] (foo) in print(foo) }
        """
        testFormatting(for: input, output, rule: .spaceAroundParens, exclude: [.redundantParens])
    }

    @Test func addSpaceBetweenCaptureListAndArguments2() {
        let input = """
        { [weak self]() -> Void in }
        """
        let output = """
        { [weak self] () -> Void in }
        """
        testFormatting(
            for: input, output, rule: .spaceAroundParens, exclude: [.redundantVoidReturnType],
        )
    }

    @Test func addSpaceBetweenCaptureListAndArguments3() {
        let input = """
        { [weak self]() throws -> Void in }
        """
        let output = """
        { [weak self] () throws -> Void in }
        """
        testFormatting(
            for: input, output, rule: .spaceAroundParens, exclude: [.redundantVoidReturnType],
        )
    }

    @Test func addSpaceBetweenCaptureListAndArguments7() {
        let input = """
        Foo<Bar>(0) { [weak self]() -> Void in }
        """
        let output = """
        Foo<Bar>(0) { [weak self] () -> Void in }
        """
        testFormatting(
            for: input, output, rule: .spaceAroundParens, exclude: [.redundantVoidReturnType],
        )
    }

    @Test func addSpaceBetweenCaptureListAndArguments8() {
        let input = """
        { [weak self]() throws(Foo) -> Void in }
        """
        let output = """
        { [weak self] () throws(Foo) -> Void in }
        """
        testFormatting(
            for: input, output, rule: .spaceAroundParens, exclude: [.redundantVoidReturnType],
        )
    }

    @Test func spaceBetweenClosingParenAndOpenBrace() {
        let input = """
        func foo(){ foo }
        """
        let output = """
        func foo() { foo }
        """
        testFormatting(for: input, output, rule: .spaceAroundParens, exclude: [.wrapFunctionBodies])
    }

    @Test func noSpaceBetweenClosingBraceAndParens() {
        let input = """
        { block } ()
        """
        let output = """
        { block }()
        """
        testFormatting(for: input, output, rule: .spaceAroundParens, exclude: [.redundantClosure])
    }

    @Test func dontRemoveSpaceBetweenOpeningBraceAndParens() {
        let input = """
        a = (b + c)
        """
        testFormatting(
            for: input, rule: .spaceAroundParens,
            exclude: [.redundantParens],
        )
    }

    @Test func addSpaceBetweenParenAndAwaitForSwift5_5() {
        let input = """
        let foo = await(bar: 5)
        """
        let output = """
        let foo = await (bar: 5)
        """
        testFormatting(
            for: input, output, rule: .spaceAroundParens,
            options: FormatOptions(swiftVersion: "5.5"),
        )
    }

    @Test func noAddSpaceBetweenParenAndAwaitForSwiftLessThan5_5() {
        let input = """
        let foo = await(bar: 5)
        """
        testFormatting(
            for: input, rule: .spaceAroundParens,
            options: FormatOptions(swiftVersion: "5.4.9"),
        )
    }

    @Test func noAddSpaceBetweenParenAndAwaitForSwiftLessThan6_2() {
        let input = """
        unsafe(["sudo"] + args).map { unsafe strdup($0) }
        """
        testFormatting(
            for: input, rule: .spaceAroundParens,
            options: FormatOptions(swiftVersion: "6.1"),
        )
    }

    @Test func addSpaceBetweenParenAndBorrowing() {
        let input = """
        func foo(_: borrowing(any Foo)) {}
        """
        let output = """
        func foo(_: borrowing (any Foo)) {}
        """
        testFormatting(
            for: input, output, rule: .spaceAroundParens,
            exclude: [.noExplicitOwnership],
        )
    }
}
