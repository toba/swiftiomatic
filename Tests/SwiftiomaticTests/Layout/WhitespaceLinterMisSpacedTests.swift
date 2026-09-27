import SwiftParser
@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

/// Checks all the findings that `WhitespaceLinter` emits for one file with many whitespace
/// defects. The benchmark `WhitespaceLintMisSpacedFile` uses the same input.
@Suite struct WhitespaceLinterMisSpacedTests {
    private static let input = """
        import      SomeModule
        public   class   SomeClass : SomeProtocol
        {
        var someProperty : SomeType {
            get{5}set{doSomething()}
            }
            public
            func
            someFunctionName
            (
            firstArg    : FirstArgument , secondArg :
            SecondArgument){
          doSomeThings()
                           }}

        """

    private static let formatted = """
        import SomeModule
        public class SomeClass: SomeProtocol {
          var someProperty: SomeType {
            get { 5 }
            set { doSomething() }
          }
          public func someFunctionName(
            firstArg: FirstArgument,
            secondArg: SecondArgument
          ) {
            doSomeThings()
          }
        }

        """

    /// Runs the linter and gives each finding as `line:column message`.
    private func lintFindings(input: String, formatted: String, lineLength: Int? = nil) -> [String] {
        var configuration = Configuration.forTesting
        if let lineLength { configuration[LineLength.self] = lineLength }
        var emitted = [Finding]()
        let context = makeTestContext(
            sourceFileSyntax: Parser.parse(source: input),
            configuration: configuration,
            selection: .infinite,
            findingConsumer: { emitted.append($0) }
        )
        WhitespaceLinter(user: input, formatted: formatted, context: context).lint()
        return emitted.map { finding in
            let line = finding.location?.line ?? 0
            let column = finding.location?.column ?? 0
            return "\(line):\(column) \(finding.message.text)"
        }
    }

    @Test func misSpacedFileFindings() {
        let findings = lintFindings(input: Self.input, formatted: Self.formatted)
        #expect(findings == [
            "1:7 remove 5 spaces",
            "2:7 remove 2 spaces",
            "2:15 remove 2 spaces",
            "2:27 remove 1 space",
            "2:42 remove line break",
            "4:1 replace leading whitespace with 2 spaces",
            "4:17 remove 1 space",
            "5:8 add 1 space",
            "5:9 add 1 space",
            "5:10 add 1 space",
            "5:11 add 1 line break",
            "5:14 add 1 space",
            "5:15 add 1 space",
            "5:28 add 1 space",
            "6:1 unindent by 2 spaces",
            "7:1 unindent by 2 spaces",
            "7:11 remove line break",
            "8:9 remove line break",
            "9:21 remove line break",
            "11:13 remove 4 spaces",
            "11:32 remove 1 space",
            "11:34 add 1 line break",
            "11:44 remove 1 space",
            "11:46 remove line break",
            "12:19 add 1 line break",
            "12:20 add 1 space",
            "13:1 indent by 2 spaces",
            "14:1 unindent by 17 spaces",
            "14:21 add 1 line break",
        ])
    }

    /// A short line limit makes the linter report long lines too.
    @Test func misSpacedFileFindingsWithShortLineLimit() {
        let findings = lintFindings(input: Self.input, formatted: Self.formatted, lineLength: 20)
        #expect(findings == [
            "1:1 line is too long",
            "1:7 remove 5 spaces",
            "2:7 remove 2 spaces",
            "2:15 remove 2 spaces",
            "2:27 remove 1 space",
            "2:42 remove line break",
            "4:1 replace leading whitespace with 2 spaces",
            "4:17 remove 1 space",
            "5:1 line is too long",
            "5:8 add 1 space",
            "5:9 add 1 space",
            "5:10 add 1 space",
            "5:14 add 1 space",
            "5:15 add 1 space",
            "5:28 add 1 space",
            "6:1 unindent by 2 spaces",
            "7:1 unindent by 2 spaces",
            "7:11 remove line break",
            "8:9 remove line break",
            "9:21 remove line break",
            "11:13 remove 4 spaces",
            "11:32 remove 1 space",
            "11:34 add 1 line break",
            "11:44 remove 1 space",
            "11:46 remove line break",
            "12:19 add 1 line break",
            "12:20 add 1 space",
            "13:1 indent by 2 spaces",
            "14:1 line is too long",
            "14:1 unindent by 17 spaces",
        ])
    }

    /// Multi-byte text before the whitespace must not move the finding columns.
    @Test func multiByteTextKeepsFindingColumns() {
        let findings = lintFindings(
            input: "let caf\u{E9}  = \"\u{1F600}\"   \nlet b = 1\n",
            formatted: "let caf\u{E9} = \"\u{1F600}\"\nlet b = 1\n"
        )
        #expect(findings == [
            "1:10 remove 1 space",
            "1:20 remove trailing whitespace",
        ])
    }
}
