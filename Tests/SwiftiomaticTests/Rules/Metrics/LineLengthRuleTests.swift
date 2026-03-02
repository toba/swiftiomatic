import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct LineLengthRuleTests {
  private static let longString = String(repeating: "a", count: 121)

  private let longFunctionDeclarations = [
    Example(
      """
      public func superDuperLongFunctionDeclaration(a: String, b: String, \
      c: String, d: String, e: String, f: String, g: String, h: String, i: String, \
      j: String, k: String, l: String, m: String, n: String, o: String, p: String, \
      q: String, r: String, s: String, t: String, u: String, v: String, w: String, \
      x: String, y: String, z: String) {}

      """,
    ),
    Example(
      """
      func superDuperLongFunctionDeclaration(a: String, b: String, \
      c: String, d: String, e: String, f: String, g: String, h: String, i: String, \
      j: String, k: String, l: String, m: String, n: String, o: String, p: String, \
      q: String, r: String, s: String, t: String, u: String, v: String, w: String, \
      x: String, y: String, z: String) {}

      """,
    ),
    Example(
      """
      struct S {
          public init(a: String, b: String, c: String, d: String, e: String, f: String, \
                      g: String, h: String, i: String, j: String, k: String, l: String, \
                      m: String, n: String, o: String, p: String, q: String, r: String, \
                      s: String, t: String, u: String, v: String, w: String, x: String, \
                      y: String, z: String) throws {
              // ...
          }
      }
      """,
    ),
    Example(
      """
      struct S {
          subscript(a: String, b: String, c: String, d: String, e: String, f: String, \
                    g: String, h: String, i: String, j: String, k: String, l: String, \
                    m: String, n: String, o: String, p: String, q: String, r: String, \
                    s: String, t: String, u: String, v: String, w: String, x: String, \
                    y: String, z: String) -> Int {
              // ...
              return 0
          }
      }
      """,
    ),
  ]
  private let longFunctionCalls = [
    Example(
      """
      superDuperLongFunctionCall(a: "A", b: "B", c: "C", d: "D", e: "E", f: "F", \
      g: "G", h: "H", i: "I", j: "J", k: "K", l: "L", m: "M", n: "N", o: "O", p: "P", \
      q: "Q", r: "R", s: "S", t: "T", u: "U", v: "V", w: "W", x: "X", y: "Y", z: "Z")
      """,
    ),
    Example(
      """
      func test() {
          let _ = superDuperLongFunctionCall(a: "A", b: "B", c: "C", d: "D", e: "E", f: "F", \
          g: "G", h: "H", i: "I", j: "J", k: "K", l: "L", m: "M", n: "N", o: "O", p: "P", \
          q: "Q", r: "R", s: "S", t: "T", u: "U", v: "V", w: "W", x: "X", y: "Y", z: "Z")
      }
      """,
    ),
  ]

  private let longComment = Example(String(repeating: "/", count: 121) + "\n")
  private let longBlockComment = Example("/*" + String(repeating: " ", count: 121) + "*/\n")
  private let longRealBlockComment = Example(
    """
    /*
    \(LineLengthRuleTests.longString)
    */

    """,
  )
  private let declarationWithTrailingLongComment = Example(
    "let foo = 1 " + String(repeating: "/", count: 121) + "\n",
  )
  private let interpolatedString = Example(
    "print(\"\\(value)" + String(repeating: "A", count: 113) + "\" )\n",
  )
  private let plainString = Example("print(\"" + LineLengthRuleTests.longString + ")\"\n")

  private let multilineString = Example(
    """
    let multilineString = \"\"\"
    \(LineLengthRuleTests.longString)
    \"\"\"

    """,
  )
  private let tripleStringSingleLine = Example(
    "let tripleString = \"\"\"\(LineLengthRuleTests.longString)\"\"\"\n",
  )
  private let poundStringSingleLine = Example(
    "let poundString = #\"\(LineLengthRuleTests.longString)\"#\n",
  )
  private let multilineStringWithExpression = Example(
    """
    let multilineString = \"\"\"
    \(LineLengthRuleTests.longString)

    \"\"\"; let a = 1
    """,
  )
  private let multilineStringWithNewlineExpression = Example(
    """
    let multilineString = \"\"\"
    \(LineLengthRuleTests.longString)

    \"\"\"
    ; let a = 1
    """,
  )
  private let multilineStringFail = Example(
    """
    let multilineString = "A" +
    "\(LineLengthRuleTests.longString)"

    """,
  )
  private let multilineStringWithFunction = Example(
    """
    let multilineString = \"\"\"
    \(LineLengthRuleTests.longString)
    \"\"\".functionCall()
    """,
  )

  // Regex literal examples
  private let regexLiteral = Example(
    """
    let emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$|^\(LineLengthRuleTests
            .longString)$/

    """,
  )
  private let regexLiteralWithCapture = Example(
    """
    let urlRegex = /^(https?:\\/\\/)?(www\\.)?([a-zA-Z0-9.-]+\\.[a-zA-Z]{2,})(\\/\(LineLengthRuleTests
            .longString))?$/

    """,
  )
  private let regexLiteralMultiline = Example(
    """
    let complexRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$|^very\\.long\\.regex\\.pattern\\.here\\.with\\.many\\.dots\\.and\\.extra\\.text$/

    """,
  )
  private let regexLiteralFail = Example(
    """
    let longRegexString = "\(LineLengthRuleTests.longString)"

    """,
  )

  @Test func lineLength() async {
    await verifyRule(
      LineLengthRule.configuration,
      commentDoesNotViolate: false,
      stringDoesNotViolate: false,
    )
  }

  @Test func lineLengthWithIgnoreFunctionDeclarationsEnabled() async {
    let baseExamples = TestExamples(from: LineLengthRule.configuration)
    let description = baseExamples.with(
      nonTriggeringExamples: baseExamples.nonTriggeringExamples + longFunctionDeclarations,
      triggeringExamples: longFunctionCalls,
    )

    await verifyRule(
      description,
      ruleConfiguration: ["ignores_function_declarations": true],
      commentDoesNotViolate: false,
      stringDoesNotViolate: false,
    )
  }

  @Test func lineLengthWithIgnoreCommentsEnabled() async {
    let triggeringExamples = longFunctionDeclarations + [declarationWithTrailingLongComment]
    let nonTriggeringExamples = [longComment, longBlockComment, longRealBlockComment]

    let description = TestExamples(from: LineLengthRule.configuration).with(
      nonTriggeringExamples: nonTriggeringExamples,
      triggeringExamples: triggeringExamples,
    )

    await verifyRule(
      description, ruleConfiguration: ["ignores_comments": true],
      commentDoesNotViolate: false, stringDoesNotViolate: false, skipCommentTests: true,
    )
  }

  @Test func lineLengthWithIgnoreURLsEnabled() async {
    let url = "https://github.com/realm/SwiftLint"
    let triggeringLines = [Example(String(repeating: "/", count: 121) + "\(url)\n")]
    let nonTriggeringLines = [
      Example("\(url) " + String(repeating: "/", count: 118) + " \(url)\n"),
      Example("\(url)/" + String(repeating: "a", count: 120)),
    ]

    let baseExamples = TestExamples(from: LineLengthRule.configuration)
    let nonTriggeringExamples = baseExamples.nonTriggeringExamples + nonTriggeringLines
    let triggeringExamples = baseExamples.triggeringExamples + triggeringLines

    let description = baseExamples.with(
      nonTriggeringExamples: nonTriggeringExamples,
      triggeringExamples: triggeringExamples,
    )

    await verifyRule(
      description, ruleConfiguration: ["ignores_urls": true],
      commentDoesNotViolate: false, stringDoesNotViolate: false,
    )
  }

  @Test func lineLengthWithIgnoreInterpolatedStringsTrue() async {
    let triggeringLines = [plainString]
    let nonTriggeringLines = [interpolatedString]

    let baseExamples = TestExamples(from: LineLengthRule.configuration)
    let nonTriggeringExamples = baseExamples.nonTriggeringExamples + nonTriggeringLines
    let triggeringExamples = baseExamples.triggeringExamples + triggeringLines

    let description = baseExamples.with(
      nonTriggeringExamples: nonTriggeringExamples,
      triggeringExamples: triggeringExamples,
    )

    await verifyRule(
      description, ruleConfiguration: ["ignores_interpolated_strings": true],
      commentDoesNotViolate: false, stringDoesNotViolate: false,
    )
  }

  @Test func lineLengthWithIgnoreMultilineStringsTrue() async {
    let triggeringLines = [
      multilineStringFail,
      tripleStringSingleLine,
      poundStringSingleLine,
    ]
    let nonTriggeringLines = [
      multilineString,
      multilineStringWithExpression,
      multilineStringWithNewlineExpression,
      multilineStringWithFunction,
    ]

    let baseExamples = TestExamples(from: LineLengthRule.configuration)
    let nonTriggeringExamples = baseExamples.nonTriggeringExamples + nonTriggeringLines
    let triggeringExamples = baseExamples.triggeringExamples + triggeringLines

    let description = baseExamples.with(
      nonTriggeringExamples: nonTriggeringExamples,
      triggeringExamples: triggeringExamples,
    )

    await verifyRule(
      description, ruleConfiguration: ["ignores_multiline_strings": true],
      commentDoesNotViolate: false, stringDoesNotViolate: false,
    )
  }

  @Test func lineLengthWithIgnoreInterpolatedStringsFalse() async {
    let triggeringLines = [plainString, interpolatedString]

    let baseExamples = TestExamples(from: LineLengthRule.configuration)
    let nonTriggeringExamples = baseExamples.nonTriggeringExamples
    let triggeringExamples = baseExamples.triggeringExamples + triggeringLines

    let description = baseExamples.with(
      nonTriggeringExamples: nonTriggeringExamples,
      triggeringExamples: triggeringExamples,
    )

    await verifyRule(
      description, ruleConfiguration: ["ignores_interpolated_strings": false],
      commentDoesNotViolate: false, stringDoesNotViolate: false,
    )
  }

  @Test func lineLengthWithExcludedLinesPatterns() async {
    let nonTriggeringLines = [plainString, interpolatedString]

    let baseExamples = TestExamples(from: LineLengthRule.configuration)
    let nonTriggeringExamples = baseExamples.nonTriggeringExamples + nonTriggeringLines
    let triggeringExamples = baseExamples.triggeringExamples

    let description = baseExamples.with(
      nonTriggeringExamples: nonTriggeringExamples,
      triggeringExamples: triggeringExamples,
    )

    await verifyRule(
      description,
      ruleConfiguration: ["excluded_lines_patterns": ["^print"]],
      commentDoesNotViolate: false,
      stringDoesNotViolate: false,
    )
  }

  @Test func lineLengthWithEmptyExcludedLinesPatterns() async {
    let triggeringLines = [plainString, interpolatedString]

    let baseExamples = TestExamples(from: LineLengthRule.configuration)
    let nonTriggeringExamples = baseExamples.nonTriggeringExamples
    let triggeringExamples = baseExamples.triggeringExamples + triggeringLines

    let description = baseExamples.with(
      nonTriggeringExamples: nonTriggeringExamples,
      triggeringExamples: triggeringExamples,
    )

    await verifyRule(
      description,
      ruleConfiguration: ["excluded_lines_patterns": []],
      commentDoesNotViolate: false,
      stringDoesNotViolate: false,
    )
  }

  @Test func lineLengthWithIgnoreRegexLiteralsTrue() async {
    let triggeringLines = [
      regexLiteralFail,
      plainString,
    ]
    let nonTriggeringLines = [
      regexLiteral,
      regexLiteralWithCapture,
      regexLiteralMultiline,
    ]

    let baseExamples = TestExamples(from: LineLengthRule.configuration)
    let nonTriggeringExamples = baseExamples.nonTriggeringExamples + nonTriggeringLines
    let triggeringExamples = baseExamples.triggeringExamples + triggeringLines

    let description = baseExamples.with(
      nonTriggeringExamples: nonTriggeringExamples,
      triggeringExamples: triggeringExamples,
    )

    await verifyRule(
      description,
      ruleConfiguration: ["ignores_regex_literals": true],
      commentDoesNotViolate: false,
      stringDoesNotViolate: false,
    )
  }
}
