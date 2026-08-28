import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct SingleLineBodiesCommentTests: RuleTesting {
    private var inlineConfig: Configuration {
        var config = Configuration.forTesting(enabledRule: LayoutSingleLineBodies.key)
        config[LayoutSingleLineBodies.self] = {
            var c = LayoutSingleLineBodiesConfiguration()
            c.mode = .inline
            return c
        }()
        return config
    }

    // MARK: - Comment preservation (issue fry-ger)

    @Test func computedPropertyWithTrailingCommentNotInlined() {
        // Inlining would drop the `// sm:ignore ...` comment, losing the suppression directive.
        assertUnchanged(
            LayoutSingleLineBodies.self,
            source: """
                var body: String {
                    String(decoding: data, as: UTF8.self) // sm:ignore useFailableStringInit
                }
                """,
            configuration: inlineConfig)
    }

    @Test func computedPropertyWithTrailingPlainCommentNotInlined() {
        assertUnchanged(
            LayoutSingleLineBodies.self,
            source: """
                var name: String {
                    "hello" // a friendly greeting
                }
                """,
            configuration: inlineConfig)
    }

    @Test func functionWithTrailingCommentNotInlined() {
        assertUnchanged(
            LayoutSingleLineBodies.self,
            source: """
                func answer() -> Int {
                    42 // the answer
                }
                """,
            configuration: inlineConfig)
    }

    @Test func guardWithTrailingCommentNotInlined() {
        assertUnchanged(
            LayoutSingleLineBodies.self,
            source: """
                guard let foo = bar else {
                    return // bail out
                }
                """,
            configuration: inlineConfig)
    }

    @Test func ifWithLeadingCommentNotInlined() {
        assertUnchanged(
            LayoutSingleLineBodies.self,
            source: """
                if foo {
                    // important
                    return bar
                }
                """,
            configuration: inlineConfig)
    }

    // MARK: - Comment after a literal's opening bracket

    @Test func arrayLiteralWithCommentAfterOpeningBracketNotInlined() {
        assertUnchanged(
            LayoutSingleLineBodies.self,
            source: """
                let primes = [  // the first three primes
                    2,
                    3,
                    5,
                ]
                """,
            configuration: inlineConfig)
    }

    @Test func dictionaryLiteralWithCommentAfterOpeningBracketNotInlined() {
        assertUnchanged(
            LayoutSingleLineBodies.self,
            source: """
                let names = [  // keyed by rank
                    1: "one",
                    2: "two",
                ]
                """,
            configuration: inlineConfig)
    }

    // MARK: - Comment above a getter's single statement

    @Test func computedPropertyWithCommentAboveStatementNotInlined() {
        assertUnchanged(
            LayoutSingleLineBodies.self,
            source: """
                var name: String {
                    // a friendly greeting
                    "hello"
                }
                """,
            configuration: inlineConfig)
    }

    @Test func subscriptWithCommentAboveStatementNotInlined() {
        assertUnchanged(
            LayoutSingleLineBodies.self,
            source: """
                subscript(i: Int) -> Int {
                    // always the same
                    i
                }
                """,
            configuration: inlineConfig)
    }

    // MARK: - Comment before a repeat block's while keyword

    @Test func repeatWithCommentBeforeWhileNotInlined() {
        assertUnchanged(
            LayoutSingleLineBodies.self,
            source: """
                repeat {
                    x += 1
                }
                // keep going until the limit
                while x < 10
                """,
            configuration: inlineConfig)
    }

    @Test func repeatWithTrailingCommentBeforeWhileNotInlined() {
        assertUnchanged(
            LayoutSingleLineBodies.self,
            source: """
                repeat {
                    x += 1
                }  // the limit is exclusive
                while x < 10
                """,
            configuration: inlineConfig)
    }

    // MARK: - Comment before the opening brace

    @Test func ifWithTrailingCommentOnLastConditionNotInlined() {
        // Inlining moves the brace up onto the comment line, which buries the body in the comment.
        assertUnchanged(
            LayoutSingleLineBodies.self,
            source: """
                if prefetchKey == key,
                   let rows = prefetch.rows // nil for "through" associations
                {
                    return rows
                }
                """,
            configuration: inlineConfig)
    }

    @Test func ifWithCommentOnItsOwnLineBeforeBraceNotInlined() {
        assertUnchanged(
            LayoutSingleLineBodies.self,
            source: """
                if foo,
                   bar
                // why the brace is down here
                {
                    return baz
                }
                """,
            configuration: inlineConfig)
    }

    @Test func guardWithTrailingCommentAfterElseNotInlined() {
        assertUnchanged(
            LayoutSingleLineBodies.self,
            source: """
                guard let foo = bar,
                      let baz = foo.qux else // nothing to do until it loads
                {
                    return
                }
                """,
            configuration: inlineConfig)
    }

    @Test func guardWithElseOnItsOwnLineAfterACommentStillInlines() {
        // The comment ends the condition line, and the brace moves up onto the else line, not past
        // it.
        assertFormatting(
            LayoutSingleLineBodies.self,
            input: """
                guard let foo = bar,
                      let baz = foo.qux // nil until loaded
                else
                1️⃣{
                    return
                }
                """,
            expected: """
                guard let foo = bar,
                      let baz = foo.qux // nil until loaded
                else { return }
                """,
            findings: [
                FindingSpec("1️⃣", message: "place conditional body on same line as declaration")
            ],
            configuration: inlineConfig)
    }

    @Test func whileWithTrailingCommentOnConditionNotInlined() {
        assertUnchanged(
            LayoutSingleLineBodies.self,
            source: """
                while !fifo.isEmpty // drains left to right
                {
                    fifo.removeFirst()
                }
                """,
            configuration: inlineConfig)
    }

    @Test func functionWithTrailingCommentOnSignatureNotInlined() {
        assertUnchanged(
            LayoutSingleLineBodies.self,
            source: """
                func answer() -> Int // always 42
                {
                    42
                }
                """,
            configuration: inlineConfig)
    }

    @Test func computedPropertyWithTrailingCommentOnTypeNotInlined() {
        assertUnchanged(
            LayoutSingleLineBodies.self,
            source: """
                var name: String // cached by the caller
                {
                    "hello"
                }
                """,
            configuration: inlineConfig)
    }

    @Test func closureWithTrailingCommentBeforeBraceNotInlined() {
        assertUnchanged(
            LayoutSingleLineBodies.self,
            source: """
                prepareDependencies // set up the test database
                {
                    $0.defaultDatabase = try! AppDatabase.actual.connection
                }
                """,
            configuration: inlineConfig)
    }

    @Test func braceOnOwnLineWithoutCommentStillInlines() {
        assertFormatting(
            LayoutSingleLineBodies.self,
            input: """
                if prefetchKey == key,
                   let rows = prefetch.rows
                1️⃣{
                    return rows
                }
                """,
            expected: """
                if prefetchKey == key,
                   let rows = prefetch.rows { return rows }
                """,
            findings: [
                FindingSpec("1️⃣", message: "place conditional body on same line as declaration")
            ],
            configuration: inlineConfig)
    }

    // MARK: - Closures

    @Test func multiLineTrailingClosureInlines() {
        assertFormatting(
            LayoutSingleLineBodies.self,
            input: """
                prepareDependencies 1️⃣{
                    $0.defaultDatabase = try! AppDatabase.actual.connection
                }
                """,
            expected: """
                prepareDependencies { $0.defaultDatabase = try! AppDatabase.actual.connection }
                """,
            findings: [FindingSpec("1️⃣", message: "place closure body on same line")],
            configuration: inlineConfig)
    }

    @Test func multiLineClosureWithSignatureInlines() {
        assertFormatting(
            LayoutSingleLineBodies.self,
            input: """
                let f = 1️⃣{ x in
                    return x + 1
                }
                """,
            expected: """
                let f = { x in return x + 1 }
                """,
            findings: [FindingSpec("1️⃣", message: "place closure body on same line")],
            configuration: inlineConfig)
    }

    @Test func alreadyInlineClosureUnchanged() {
        assertUnchanged(
            LayoutSingleLineBodies.self,
            source: """
                array.map { $0 * 2 }
                """,
            configuration: inlineConfig)
    }

    @Test func multiStatementClosureNotInlined() {
        assertUnchanged(
            LayoutSingleLineBodies.self,
            source: """
                run {
                    let x = 1
                    print(x)
                }
                """,
            configuration: inlineConfig)
    }

    @Test func closureTooLongNotInlined() {
        var config = inlineConfig
        config[LineLength.self] = 40
        assertUnchanged(
            LayoutSingleLineBodies.self,
            source: """
                run {
                    doSomethingVeryLongThatWontFitOnALine()
                }
                """,
            configuration: config)
    }

    @Test func closureWithCommentNotInlined() {
        assertUnchanged(
            LayoutSingleLineBodies.self,
            source: """
                run {
                    // important
                    doIt()
                }
                """,
            configuration: inlineConfig)
    }

    @Test func closureAfterIgnoreCommentInlines() {
        assertFormatting(
            LayoutSingleLineBodies.self,
            input: """
                // sm:ignore:next noForceTry
                prepareDependencies 1️⃣{
                    $0.defaultDatabase = try! AppDatabase.actual.connection
                }
                """,
            expected: """
                // sm:ignore:next noForceTry
                prepareDependencies { $0.defaultDatabase = try! AppDatabase.actual.connection }
                """,
            findings: [FindingSpec("1️⃣", message: "place closure body on same line")],
            configuration: inlineConfig)
    }
}
