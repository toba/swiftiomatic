import Benchmark
import SwiftParser
@testable import SwiftiomaticKit

/// Timing for `WhitespaceLinter`, which compares the user's text against the formatted text
///
/// This runs on the stdin path Xcode uses, so its cost lands in the editor's format latency rather
/// than in a batch run.
func registerWhitespaceBenchmarks() {
    Benchmark(
        "WhitespaceLintMisSpacedFile",
        configuration: .init(thresholds: Tolerance.noisy)
    ) { benchmark in
        let sourceFileSyntax = Parser.parse(source: unformattedInput)
        let context = Fixture.context(for: sourceFileSyntax)
        benchmark.startMeasurement()
        WhitespaceLinter(user: unformattedInput, formatted: formattedOutput, context: context)
            .lint()
    }
}

private let repeatCount = 20

private let unformattedInput = String(
    repeating: """
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

        """,
    count: repeatCount
)

private let formattedOutput = String(
    repeating: """
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

        """,
    count: repeatCount
)
