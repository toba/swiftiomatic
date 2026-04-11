import Testing

@testable import SwiftiomaticKit

@Suite(.rulesRegistered) struct LineLengthRuleTests {
  // MARK: - Helpers

  /// A string of exactly `count` characters (all forward slashes).
  private static func slashes(_ count: Int) -> String {
    String(repeating: "/", count: count)
  }

  /// A string of exactly `count` lowercase 'a' characters.
  private static func aChars(_ count: Int) -> String {
    String(repeating: "a", count: count)
  }

  // MARK: - Non-triggering (default config: warning at 120)

  @Test func lineAtLimitDoesNotTrigger() async {
    // Exactly 120 characters
    await assertNoViolation(LineLengthRule.self, Self.slashes(120))
  }

  // MARK: - Triggering (default config: warning at 120)

  @Test func lineOverLimitTriggers() async {
    // 121 characters exceeds the 120 warning threshold
    await assertViolates(LineLengthRule.self, Self.slashes(121))
  }

  // MARK: - Configuration: ignores_function_declarations

  @Test func longFuncDeclarationIgnoredWhenConfigured() async {
    await assertNoViolation(
      LineLengthRule.self,
      """
      public func superDuperLongFunctionDeclaration(a: String, b: String, \
      c: String, d: String, e: String, f: String, g: String, h: String, i: String, \
      j: String, k: String, l: String, m: String, n: String, o: String, p: String, \
      q: String, r: String, s: String, t: String, u: String, v: String, w: String, \
      x: String, y: String, z: String) {}

      """,
      configuration: ["ignores_function_declarations": true])
  }

  @Test func longFuncWithoutPublicIgnoredWhenConfigured() async {
    await assertNoViolation(
      LineLengthRule.self,
      """
      func superDuperLongFunctionDeclaration(a: String, b: String, \
      c: String, d: String, e: String, f: String, g: String, h: String, i: String, \
      j: String, k: String, l: String, m: String, n: String, o: String, p: String, \
      q: String, r: String, s: String, t: String, u: String, v: String, w: String, \
      x: String, y: String, z: String) {}

      """,
      configuration: ["ignores_function_declarations": true])
  }

  @Test func longInitDeclarationIgnoredWhenConfigured() async {
    await assertNoViolation(
      LineLengthRule.self,
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
      configuration: ["ignores_function_declarations": true])
  }

  @Test func longSubscriptDeclarationIgnoredWhenConfigured() async {
    await assertNoViolation(
      LineLengthRule.self,
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
      configuration: ["ignores_function_declarations": true])
  }

  @Test func longFuncCallStillTriggersWhenDeclarationsIgnored() async {
    // Function calls are NOT function declarations
    await assertViolates(
      LineLengthRule.self,
      """
      superDuperLongFunctionCall(a: "A", b: "B", c: "C", d: "D", e: "E", f: "F", \
      g: "G", h: "H", i: "I", j: "J", k: "K", l: "L", m: "M", n: "N", o: "O", p: "P", \
      q: "Q", r: "R", s: "S", t: "T", u: "U", v: "V", w: "W", x: "X", y: "Y", z: "Z")
      """,
      configuration: ["ignores_function_declarations": true])
  }

  // MARK: - Configuration: ignores_comments

  @Test func longCommentIgnoredWhenConfigured() async {
    await assertNoViolation(
      LineLengthRule.self,
      Self.slashes(121) + "\n",
      configuration: ["ignores_comments": true])
  }

  @Test func longBlockCommentIgnoredWhenConfigured() async {
    await assertNoViolation(
      LineLengthRule.self,
      "/*" + String(repeating: " ", count: 121) + "*/\n",
      configuration: ["ignores_comments": true])
  }

  @Test func longMultiLineBlockCommentIgnoredWhenConfigured() async {
    let longLine = Self.aChars(121)
    await assertNoViolation(
      LineLengthRule.self,
      """
      /*
      \(longLine)
      */

      """,
      configuration: ["ignores_comments": true])
  }

  @Test func declarationWithTrailingLongCommentStillTriggersWithIgnoreComments() async {
    // Line has code AND a long comment -- not a comment-only line
    let source = "let foo = 1 " + Self.slashes(121) + "\n"
    await assertViolates(
      LineLengthRule.self,
      source,
      configuration: ["ignores_comments": true])
  }

  @Test func longFuncDeclarationStillTriggersWithIgnoreComments() async {
    await assertViolates(
      LineLengthRule.self,
      """
      public func superDuperLongFunctionDeclaration(a: String, b: String, \
      c: String, d: String, e: String, f: String, g: String, h: String, i: String, \
      j: String, k: String, l: String, m: String, n: String, o: String, p: String, \
      q: String, r: String, s: String, t: String, u: String, v: String, w: String, \
      x: String, y: String, z: String) {}

      """,
      configuration: ["ignores_comments": true])
  }

  // MARK: - Configuration: ignores_urls

  @Test func lineContainingOnlyUrlIgnoredWhenConfigured() async {
    let url = "https://github.com/realm/SwiftLint"
    // URL at start with trailing chars, total over 120 but URL content stripped
    await assertNoViolation(
      LineLengthRule.self,
      "\(url) " + Self.slashes(118) + " \(url)\n",
      configuration: ["ignores_urls": true])
  }

  @Test func longUrlPathIgnoredWhenConfigured() async {
    let url = "https://github.com/realm/SwiftLint"
    await assertNoViolation(
      LineLengthRule.self,
      "\(url)/" + Self.aChars(120),
      configuration: ["ignores_urls": true])
  }

  @Test func longLineWithUrlStillTriggersWhenNonUrlPartExceedsLimit() async {
    let url = "https://github.com/realm/SwiftLint"
    // Slashes before URL still exceed limit after URL is stripped
    await assertViolates(
      LineLengthRule.self,
      Self.slashes(121) + "\(url)\n",
      configuration: ["ignores_urls": true])
  }

  // MARK: - Configuration: ignores_interpolated_strings

  @Test func interpolatedStringIgnoredWhenConfigured() async {
    let source = "print(\"\\(value)" + Self.aChars(113) + "\" )\n"
    await assertNoViolation(
      LineLengthRule.self,
      source,
      configuration: ["ignores_interpolated_strings": true])
  }

  @Test func plainStringStillTriggersWithIgnoreInterpolated() async {
    let longString = Self.aChars(121)
    let source = "print(\"\(longString))\"" + "\n"
    await assertViolates(
      LineLengthRule.self,
      source,
      configuration: ["ignores_interpolated_strings": true])
  }

  @Test func interpolatedStringTriggersWhenNotIgnored() async {
    let source = "print(\"\\(value)" + Self.aChars(113) + "\" )\n"
    await assertViolates(
      LineLengthRule.self,
      source,
      configuration: ["ignores_interpolated_strings": false])
  }

  @Test func plainStringTriggersWhenNotIgnored() async {
    let longString = Self.aChars(121)
    let source = "print(\"\(longString))\"" + "\n"
    await assertViolates(
      LineLengthRule.self,
      source,
      configuration: ["ignores_interpolated_strings": false])
  }

  // MARK: - Configuration: ignores_multiline_strings

  @Test func multilineStringIgnoredWhenConfigured() async {
    let longString = Self.aChars(121)
    await assertNoViolation(
      LineLengthRule.self,
      """
      let multilineString = \"\"\"
      \(longString)
      \"\"\"

      """,
      configuration: ["ignores_multiline_strings": true])
  }

  @Test func multilineStringWithExpressionIgnoredWhenConfigured() async {
    let longString = Self.aChars(121)
    await assertNoViolation(
      LineLengthRule.self,
      """
      let multilineString = \"\"\"
      \(longString)

      \"\"\"; let a = 1
      """,
      configuration: ["ignores_multiline_strings": true])
  }

  @Test func multilineStringWithNewlineExpressionIgnoredWhenConfigured() async {
    let longString = Self.aChars(121)
    await assertNoViolation(
      LineLengthRule.self,
      """
      let multilineString = \"\"\"
      \(longString)

      \"\"\"
      ; let a = 1
      """,
      configuration: ["ignores_multiline_strings": true])
  }

  @Test func multilineStringWithFunctionCallIgnoredWhenConfigured() async {
    let longString = Self.aChars(121)
    await assertNoViolation(
      LineLengthRule.self,
      """
      let multilineString = \"\"\"
      \(longString)
      \"\"\".functionCall()
      """,
      configuration: ["ignores_multiline_strings": true])
  }

  @Test func concatenatedStringNotTreatedAsMultiline() async {
    let longString = Self.aChars(121)
    // String concatenation with + is NOT a multiline string literal
    await assertViolates(
      LineLengthRule.self,
      """
      let multilineString = "A" +
      "\(longString)"

      """,
      configuration: ["ignores_multiline_strings": true])
  }

  @Test func tripleQuoteSingleLineNotIgnored() async {
    let longString = Self.aChars(121)
    // Single-line triple-quote is not a multiline string literal
    await assertViolates(
      LineLengthRule.self,
      "let tripleString = \"\"\"\(longString)\"\"\"\n",
      configuration: ["ignores_multiline_strings": true])
  }

  @Test func poundStringSingleLineNotIgnored() async {
    let longString = Self.aChars(121)
    await assertViolates(
      LineLengthRule.self,
      "let poundString = #\"\(longString)\"#\n",
      configuration: ["ignores_multiline_strings": true])
  }

  // MARK: - Configuration: excluded_lines_patterns

  @Test func excludedPatternMatchesLine() async {
    let longString = Self.aChars(121)
    // Lines matching ^print are excluded
    await assertNoViolation(
      LineLengthRule.self,
      "print(\"\(longString))\"" + "\n",
      configuration: ["excluded_lines_patterns": ["^print"]])
  }

  @Test func interpolatedStringExcludedByPattern() async {
    let source = "print(\"\\(value)" + Self.aChars(113) + "\" )\n"
    await assertNoViolation(
      LineLengthRule.self,
      source,
      configuration: ["excluded_lines_patterns": ["^print"]])
  }

  @Test func emptyExcludedPatternsDoesNotExclude() async {
    let longString = Self.aChars(121)
    await assertViolates(
      LineLengthRule.self,
      "print(\"\(longString))\"" + "\n",
      configuration: ["excluded_lines_patterns": [] as [String]])
  }

  // MARK: - Configuration: ignores_regex_literals

  @Test func regexLiteralIgnoredWhenConfigured() async {
    let longString = Self.aChars(121)
    await assertNoViolation(
      LineLengthRule.self,
      """
      let emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$|^\(longString)$/

      """,
      configuration: ["ignores_regex_literals": true])
  }

  @Test func regexLiteralWithCaptureIgnoredWhenConfigured() async {
    let longString = Self.aChars(121)
    await assertNoViolation(
      LineLengthRule.self,
      """
      let urlRegex = /^(https?:\\/\\/)?(www\\.)?([a-zA-Z0-9.-]+\\.[a-zA-Z]{2,})(\\/\(longString))?$/

      """,
      configuration: ["ignores_regex_literals": true])
  }

  @Test func longRegexOnSingleLineIgnoredWhenConfigured() async {
    await assertNoViolation(
      LineLengthRule.self,
      """
      let complexRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$|^very\\.long\\.regex\\.pattern\\.here\\.with\\.many\\.dots\\.and\\.extra\\.text$/

      """,
      configuration: ["ignores_regex_literals": true])
  }

  @Test func longStringNotTreatedAsRegexLiteral() async {
    let longString = Self.aChars(121)
    // A string literal is NOT a regex literal
    await assertViolates(
      LineLengthRule.self,
      """
      let longRegexString = "\(longString)"

      """,
      configuration: ["ignores_regex_literals": true])
  }

  @Test func plainStringStillTriggersWithIgnoreRegex() async {
    let longString = Self.aChars(121)
    await assertViolates(
      LineLengthRule.self,
      "print(\"\(longString))\"" + "\n",
      configuration: ["ignores_regex_literals": true])
  }
}
