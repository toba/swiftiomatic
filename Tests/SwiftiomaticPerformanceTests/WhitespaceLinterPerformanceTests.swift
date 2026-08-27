//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import XCTest
import SwiftParser
import SwiftSyntax
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

final class WhitespaceLinterPerformanceTests: PerformanceTestCase {
    func testWhitespaceLinterPerformance() throws {
        let input = String(
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
            count: 20
        )
        let expected = String(
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
            count: 20
        )

        measureIfNotInCI { performWhitespaceLint(input: input, expected: expected) }
    }

    /// Perform whitespace linting by comparing the input text from the user with the expected
    /// formatted text, using the default configuration.
    ///
    /// - Parameters:
    ///   - input: The user's input text.
    ///   - expected: The formatted text.
    private func performWhitespaceLint(input: String, expected: String) {
        let sourceFileSyntax = Parser.parse(source: input)
        let context = makeTestContext(
            sourceFileSyntax: sourceFileSyntax, selection: .infinite, findingConsumer: { _ in })
        let linter = WhitespaceLinter(user: input, formatted: expected, context: context)
        linter.lint()
    }
}
