import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct SingleLineBodiesInlineTests: RuleTesting {
    private var inlineConfig: Configuration {
        var config = Configuration.forTesting(enabledRule: LayoutSingleLineBodies.key)
        config[LayoutSingleLineBodies.self] = {
            var c = LayoutSingleLineBodiesConfiguration()
            c.mode = .inline
            return c
        }()
        return config
    }

    // MARK: - Functions

    @Test func multiLineFunctionInlines() {
        assertFormatting(
            LayoutSingleLineBodies.self,
            input: """
                func foo() 1️⃣{
                    return 42
                }
                """,
            expected: """
                func foo() { return 42 }
                """,
            findings: [
                FindingSpec("1️⃣", message: "place function body on same line as declaration")
            ],
            configuration: inlineConfig)
    }

    @Test func alreadyInlineFunctionUnchanged() {
        assertUnchanged(
            LayoutSingleLineBodies.self,
            source: """
                func foo() { return 42 }
                """,
            configuration: inlineConfig)
    }

    @Test func emptyFunctionBodyUnchanged() {
        assertUnchanged(
            LayoutSingleLineBodies.self,
            source: """
                func foo() {}
                """,
            configuration: inlineConfig)
    }

    @Test func multiStatementFunctionNotInlined() {
        assertUnchanged(
            LayoutSingleLineBodies.self,
            source: """
                func foo() {
                    let x = 1
                    return x
                }
                """,
            configuration: inlineConfig)
    }

    @Test func functionTooLongNotInlined() {
        var config = inlineConfig
        config[LineLength.self] = 30
        assertUnchanged(
            LayoutSingleLineBodies.self,
            source: """
                func doSomethingLong() {
                    return someVeryLongExpression
                }
                """,
            configuration: config)
    }

    @Test func functionFitsInlines() {
        var config = inlineConfig
        config[LineLength.self] = 40
        assertFormatting(
            LayoutSingleLineBodies.self,
            input: """
                func foo() 1️⃣{
                    return 42
                }
                """,
            expected: """
                func foo() { return 42 }
                """,
            findings: [
                FindingSpec("1️⃣", message: "place function body on same line as declaration")
            ],
            configuration: config)
    }

    @Test func functionWithWrappedWhereClauseWrapsBody() {
        assertFormatting(
            LayoutSingleLineBodies.self,
            input: """
                func jsonArrayLength<Element: Codable>() -> some QueryExpression<Int>
                    where QueryValue == [Element].JSONRepresentation
                1️⃣{ QueryFunction("json_array_length", self) }
                """,
            expected: """
                func jsonArrayLength<Element: Codable>() -> some QueryExpression<Int>
                    where QueryValue == [Element].JSONRepresentation
                {
                    QueryFunction("json_array_length", self)
                }
                """,
            findings: [FindingSpec("1️⃣", message: "wrap function body onto a new line")],
            configuration: inlineConfig)
    }

    @Test func functionWithInlineWhereClauseStillInlines() {
        assertFormatting(
            LayoutSingleLineBodies.self,
            input: """
                func foo<T>() where T: Equatable 1️⃣{
                    return 42
                }
                """,
            expected: """
                func foo<T>() where T: Equatable { return 42 }
                """,
            findings: [
                FindingSpec("1️⃣", message: "place function body on same line as declaration")
            ],
            configuration: inlineConfig)
    }

    // MARK: - Initializers

    @Test func initInlines() {
        assertFormatting(
            LayoutSingleLineBodies.self,
            input: """
                init() 1️⃣{
                    value = 0
                }
                """,
            expected: """
                init() { value = 0 }
                """,
            findings: [
                FindingSpec("1️⃣", message: "place function body on same line as declaration")
            ],
            configuration: inlineConfig)
    }

    // MARK: - Guard statements

    @Test func guardInlines() {
        assertFormatting(
            LayoutSingleLineBodies.self,
            input: """
                guard let foo = bar else 1️⃣{
                    return
                }
                """,
            expected: """
                guard let foo = bar else { return }
                """,
            findings: [
                FindingSpec("1️⃣", message: "place conditional body on same line as declaration")
            ],
            configuration: inlineConfig)
    }

    /// A body too long for the line the layout can give it
    ///
    /// The conditions wrap and `else` drops to the statement's own indent, so the fold is measured
    /// from column 0. The body still overflows there, which refuses the fold.
    @Test func guardTooLongNotInlined() {
        var config = inlineConfig
        config[LineLength.self] = 25
        assertUnchanged(
            LayoutSingleLineBodies.self,
            source: """
                guard let foo = bar else {
                    return reallyLongValue
                }
                """,
            configuration: config)
    }

    // MARK: - If statements

    @Test func simpleIfInlines() {
        assertFormatting(
            LayoutSingleLineBodies.self,
            input: """
                if foo 1️⃣{
                    return bar
                }
                """,
            expected: """
                if foo { return bar }
                """,
            findings: [
                FindingSpec("1️⃣", message: "place conditional body on same line as declaration")
            ],
            configuration: inlineConfig)
    }

    @Test func ifElseNotInlined() {
        // if/else chains are too complex to inline
        assertUnchanged(
            LayoutSingleLineBodies.self,
            source: """
                if foo {
                    return bar
                } else {
                    return baz
                }
                """,
            configuration: inlineConfig)
    }

    /// A folded body under a condition list the layout aligns
    ///
    /// `AlignWrappedConditions` puts the second condition under the first, so the folded body still
    /// reads as the statement's body rather than as part of the condition.
    @Test func multiLineConditionWithBraceOnOwnLineInlines() {
        var config = inlineConfig
        config[AlignWrappedConditions.self] = true
        assertFormatting(
            LayoutSingleLineBodies.self,
            input: """
                if let funcCall = parent.as(FunctionCallExprSyntax.self),
                   funcCall.calledExpression.id == node.id
                1️⃣{
                    return false
                }
                """,
            expected: """
                if let funcCall = parent.as(FunctionCallExprSyntax.self),
                   funcCall.calledExpression.id == node.id { return false }
                """,
            findings: [
                FindingSpec("1️⃣", message: "place conditional body on same line as declaration")
            ],
            configuration: config)
    }

    @Test func multiLineConditionWithBraceOnLastConditionLineInlines() {
        var config = inlineConfig
        config[AlignWrappedConditions.self] = true
        assertFormatting(
            LayoutSingleLineBodies.self,
            input: """
                if let funcCall = parent.as(FunctionCallExprSyntax.self),
                   funcCall.calledExpression.id == node.id 1️⃣{
                    return false
                }
                """,
            expected: """
                if let funcCall = parent.as(FunctionCallExprSyntax.self),
                   funcCall.calledExpression.id == node.id { return false }
                """,
            findings: [
                FindingSpec("1️⃣", message: "place conditional body on same line as declaration")
            ],
            configuration: config)
    }

    @Test func multiLineConditionWithTryAndBraceOnOwnLineInlines() {
        assertFormatting(
            LayoutSingleLineBodies.self,
            input: """
                if let existing = try? String(contentsOf: url, encoding: .utf8),
                   existing == content
                1️⃣{
                    return
                }
                """,
            expected: """
                if let existing = try? String(contentsOf: url, encoding: .utf8),
                   existing == content { return }
                """,
            findings: [
                FindingSpec("1️⃣", message: "place conditional body on same line as declaration")
            ],
            configuration: inlineConfig)
    }

    @Test func misalignedMultiLineIfConditionNotInlined() {
        assertUnchanged(
            LayoutSingleLineBodies.self,
            source: """
                if FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory),
                    isDirectory.boolValue
                {
                    directory.appendPathComponent("placeholder")
                }
                """,
            configuration: inlineConfig)
    }

    /// A condition list the layout wraps to two columns
    ///
    /// `BreakBeforeGuardConditions` is off, so the first condition holds the `guard` line and the
    /// second wraps to the continuation indent below it. A body folded onto that list reads as part
    /// of the second condition, which refuses the fold.
    @Test func misalignedMultiLineGuardConditionNotInlined() {
        var config = inlineConfig
        config[BreakBeforeGuardConditions.self] = false
        assertUnchanged(
            LayoutSingleLineBodies.self,
            source: """
                guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory),
                    isDirectory.boolValue
                else {
                    return
                }
                """,
            configuration: config)
    }

    @Test func multiLineConditionTooLongNotInlined() {
        var config = inlineConfig
        config[LineLength.self] = 50
        assertUnchanged(
            LayoutSingleLineBodies.self,
            source: """
                if let funcCall = parent.as(FunctionCallExprSyntax.self),
                   funcCall.calledExpression.id == node.id
                {
                    return someVeryLongValueThatWontFitOnTheLine
                }
                """,
            configuration: config)
    }

    // MARK: - Loops

    @Test func forLoopInlines() {
        assertFormatting(
            LayoutSingleLineBodies.self,
            input: """
                for foo in bar 1️⃣{
                    print(foo)
                }
                """,
            expected: """
                for foo in bar { print(foo) }
                """,
            findings: [FindingSpec("1️⃣", message: "place loop body on same line as declaration")],
            configuration: inlineConfig)
    }

    @Test func forLoopInlinesAtExactLineLengthBoundary() {
        // Collapsed form is exactly 29 chars; lineLength is 29, so it should fit.
        var config = inlineConfig
        config[LineLength.self] = 29
        assertFormatting(
            LayoutSingleLineBodies.self,
            input: """
                for x in y 1️⃣{
                    doSomething(z)
                }
                """,
            expected: """
                for x in y { doSomething(z) }
                """,
            findings: [FindingSpec("1️⃣", message: "place loop body on same line as declaration")],
            configuration: config)
    }

    @Test func whileLoopInlines() {
        assertFormatting(
            LayoutSingleLineBodies.self,
            input: """
                while condition 1️⃣{
                    doWork()
                }
                """,
            expected: """
                while condition { doWork() }
                """,
            findings: [FindingSpec("1️⃣", message: "place loop body on same line as declaration")],
            configuration: inlineConfig)
    }

    @Test func misalignedMultiLineWhileConditionNotInlined() {
        assertUnchanged(
            LayoutSingleLineBodies.self,
            source: """
                while FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory),
                    isDirectory.boolValue
                {
                    directory.appendPathComponent("placeholder")
                }
                """,
            configuration: inlineConfig)
    }

    @Test func repeatWhileInlines() {
        assertFormatting(
            LayoutSingleLineBodies.self,
            input: """
                repeat 1️⃣{
                    doWork()
                } while condition
                """,
            expected: """
                repeat { doWork() } while condition
                """,
            findings: [FindingSpec("1️⃣", message: "place loop body on same line as declaration")],
            configuration: inlineConfig)
    }

    // MARK: - Properties

    @Test func computedPropertyInlines() {
        assertFormatting(
            LayoutSingleLineBodies.self,
            input: """
                var bar: String 1️⃣{
                    "bar"
                }
                """,
            expected: """
                var bar: String { "bar" }
                """,
            findings: [
                FindingSpec("1️⃣", message: "place property body on same line as declaration")
            ],
            configuration: inlineConfig)
    }

    @Test func computedPropertyTooLongNotInlined() {
        var config = inlineConfig
        config[LineLength.self] = 20
        assertUnchanged(
            LayoutSingleLineBodies.self,
            source: """
                var bar: String {
                    "a long string value"
                }
                """,
            configuration: config)
    }

    @Test func didSetBodyInlines() {
        assertFormatting(
            LayoutSingleLineBodies.self,
            input: """
                var value: Int = 0 {
                    didSet 1️⃣{
                        print("changed")
                    }
                }
                """,
            expected: """
                var value: Int = 0 {
                    didSet { print("changed") }
                }
                """,
            findings: [FindingSpec("1️⃣", message: "place observer body on same line as accessor")],
            configuration: inlineConfig)
    }

    @Test func willSetBodyInlines() {
        assertFormatting(
            LayoutSingleLineBodies.self,
            input: """
                var value: Int = 0 {
                    willSet 1️⃣{
                        print("will change")
                    }
                }
                """,
            expected: """
                var value: Int = 0 {
                    willSet { print("will change") }
                }
                """,
            findings: [FindingSpec("1️⃣", message: "place observer body on same line as accessor")],
            configuration: inlineConfig)
    }

    @Test func observerBodyAlreadyInlineUnchanged() {
        assertUnchanged(
            LayoutSingleLineBodies.self,
            source: """
                var value: Int = 0 {
                    didSet { print("changed") }
                }
                """,
            configuration: inlineConfig)
    }

    @Test func observerBodyTooLongNotInlined() {
        var config = inlineConfig
        config[LineLength.self] = 30
        assertUnchanged(
            LayoutSingleLineBodies.self,
            source: """
                var value: Int = 0 {
                    didSet {
                        outputBuffer.isEnabled = disabledPosition == nil
                    }
                }
                """,
            configuration: config)
    }

    @Test func observerMultiStatementNotInlined() {
        assertUnchanged(
            LayoutSingleLineBodies.self,
            source: """
                var value: Int = 0 {
                    didSet {
                        print("old: \\(oldValue)")
                        print("new: \\(value)")
                    }
                }
                """,
            configuration: inlineConfig)
    }

    // MARK: - get/set accessor blocks

    @Test func getSetSingleStatementAccessorsInline() {
        assertFormatting(
            LayoutSingleLineBodies.self,
            input: """
                var key: String 1️⃣{
                    get { id }
                    set { id = newValue }
                }
                """,
            expected: """
                var key: String { get { id } set { id = newValue } }
                """,
            findings: [
                FindingSpec("1️⃣", message: "place property body on same line as declaration")
            ],
            configuration: inlineConfig)
    }

    @Test func getSetMultilineBodiesInline() {
        assertFormatting(
            LayoutSingleLineBodies.self,
            input: """
                var key: String 1️⃣{
                    get {
                        id
                    }
                    set {
                        id = newValue
                    }
                }
                """,
            expected: """
                var key: String { get { id } set { id = newValue } }
                """,
            findings: [
                FindingSpec("1️⃣", message: "place property body on same line as declaration")
            ],
            configuration: inlineConfig)
    }

    @Test func getSetTooLongNotInlined() {
        var config = inlineConfig
        config[LineLength.self] = 30
        assertUnchanged(
            LayoutSingleLineBodies.self,
            source: """
                var key: String {
                    get { id }
                    set { id = newValue }
                }
                """,
            configuration: config)
    }

    @Test func getSetMultiStatementNotInlined() {
        assertUnchanged(
            LayoutSingleLineBodies.self,
            source: """
                var key: String {
                    get { id }
                    set {
                        log()
                        id = newValue
                    }
                }
                """,
            configuration: inlineConfig)
    }

    // MARK: - Indented context

    @Test func indentedFunctionInlines() {
        assertFormatting(
            LayoutSingleLineBodies.self,
            input: """
                class Foo {
                    func bar() 1️⃣{
                        return 42
                    }
                }
                """,
            expected: """
                class Foo {
                    func bar() { return 42 }
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "place function body on same line as declaration")
            ],
            configuration: inlineConfig)
    }

    @Test func indentedComputedPropertyInlines() {
        assertFormatting(
            LayoutSingleLineBodies.self,
            input: """
                struct Foo {
                    var bar: String 1️⃣{
                        "bar"
                    }
                }
                """,
            expected: """
                struct Foo {
                    var bar: String { "bar" }
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "place property body on same line as declaration")
            ],
            configuration: inlineConfig)
    }

    // MARK: - Subscripts

    @Test func subscriptInlines() {
        assertFormatting(
            LayoutSingleLineBodies.self,
            input: """
                subscript(index: Int) -> Int 1️⃣{
                    array[index]
                }
                """,
            expected: """
                subscript(index: Int) -> Int { array[index] }
                """,
            findings: [
                FindingSpec("1️⃣", message: "place function body on same line as declaration")
            ],
            configuration: inlineConfig)
    }

    // MARK: - Collection literals

    @Test func wrappedArrayLiteralInlines() {
        // Issue zbo-eta: in inline mode, a wrapped array literal whose joined form fits should
        // collapse to a single line and drop the trailing comma.
        assertFormatting(
            LayoutSingleLineBodies.self,
            input: """
                let a = 1️⃣[
                    "id",
                    "type",
                    "within_id",
                    "position",
                    "name",
                    "value",
                    "value_type",
                ]
                """,
            expected: """
                let a = ["id", "type", "within_id", "position", "name", "value", "value_type"]
                """,
            findings: [
                FindingSpec("1️⃣", message: "place collection literal on same line as declaration")
            ],
            configuration: inlineConfig)
    }

    @Test func wrappedArrayLiteralStaysWrappedWhenItDoesntFit() {
        var config = inlineConfig
        config[LineLength.self] = 40
        assertUnchanged(
            LayoutSingleLineBodies.self,
            source: """
                let a = [
                    "alpha", "beta", "gamma",
                    "delta", "epsilon", "zeta",
                ]
                """,
            configuration: config)
    }

    @Test func wrappedDictionaryLiteralInlines() {
        assertFormatting(
            LayoutSingleLineBodies.self,
            input: """
                let m = 1️⃣[
                    "a": 1,
                    "b": 2,
                    "c": 3,
                ]
                """,
            expected: """
                let m = ["a": 1, "b": 2, "c": 3]
                """,
            findings: [
                FindingSpec("1️⃣", message: "place collection literal on same line as declaration")
            ],
            configuration: inlineConfig)
    }

    @Test func dictionaryLiteralWithWhitespaceAroundColonInlines() {
        // Issue hqy-zcl: trivia between key and `:` and between `:` and value must be cleared when
        // collapsing, mirroring the array variant's full reset of element trivia.
        assertFormatting(
            LayoutSingleLineBodies.self,
            input: """
                let m = 1️⃣[
                    "a"
                        : 1,
                    "b"   :   2,
                ]
                """,
            expected: """
                let m = ["a": 1, "b": 2]
                """,
            findings: [
                FindingSpec("1️⃣", message: "place collection literal on same line as declaration")
            ],
            configuration: inlineConfig)
    }

    @Test func alreadyInlineArrayUnchanged() {
        assertUnchanged(
            LayoutSingleLineBodies.self,
            source: """
                let a = ["x", "y", "z"]
                """,
            configuration: inlineConfig)
    }

    @Test func emptyArrayUnchanged() {
        assertUnchanged(
            LayoutSingleLineBodies.self,
            source: """
                let a: [Int] = []
                """,
            configuration: inlineConfig)
    }
}
