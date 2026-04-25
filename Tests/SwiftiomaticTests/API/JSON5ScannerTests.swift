@testable import SwiftiomaticKit
import Testing

@Suite
struct JSON5ScannerTests {

  // MARK: - Basic structure

  @Test func parsesEmptyObject() throws {
    let layout = try JSON5Scanner.parseDocument("{}")
    #expect(layout.members.isEmpty)
  }

  @Test func parsesTwoMembers() throws {
    let source = """
      {
        "a": 1,
        "b": 2
      }
      """
    let layout = try JSON5Scanner.parseDocument(source)
    #expect(layout.members.count == 2)
    #expect(layout.members.map(\.key) == ["a", "b"])
  }

  @Test func memberValueRangeIsExact() throws {
    let source = #"{ "a": 42 }"#
    let layout = try JSON5Scanner.parseDocument(source)
    let m = layout.members[0]
    #expect(source[m.valueRange] == "42")
  }

  @Test func memberFullRangeCoversIndentAndTrailingNewline() throws {
    let source = """
      {
        "a": 1,
        "b": 2
      }
      """
    let layout = try JSON5Scanner.parseDocument(source)
    let first = layout.members[0]
    let extracted = String(source[first.fullRange])
    // Should include the leading two spaces and the trailing newline.
    #expect(extracted == "  \"a\": 1,\n")
  }

  // MARK: - Nesting

  @Test func parsesNestedObjectAndExposesChildren() throws {
    let source = """
      {
        "wrap": {
          "preferIsEmpty": { "lint": "warn" },
          "lineBreaks": { "lint": "warn" }
        }
      }
      """
    let layout = try JSON5Scanner.parseDocument(source)
    let wrap = try #require(layout.members.first?.nested)
    #expect(wrap.members.map(\.key) == ["preferIsEmpty", "lineBreaks"])
    // Trailing comma on first child, none on the last.
    #expect(wrap.members[0].trailingComma != nil)
    #expect(wrap.members[1].trailingComma == nil)
  }

  // MARK: - Comments

  @Test func skipsLineComments() throws {
    let source = """
      // top comment
      {
        // inline comment
        "a": 1, // trailing
        "b": 2
      }
      """
    let layout = try JSON5Scanner.parseDocument(source)
    #expect(layout.members.map(\.key) == ["a", "b"])
  }

  @Test func skipsBlockComments() throws {
    let source = """
      {
        /* block */ "a": 1,
        "b": /* inline */ 2
      }
      """
    let layout = try JSON5Scanner.parseDocument(source)
    #expect(layout.members.map(\.key) == ["a", "b"])
  }

  // MARK: - JSON5 lexicon

  @Test func parsesSingleQuotedStrings() throws {
    let source = "{ 'a': 'hello world' }"
    let layout = try JSON5Scanner.parseDocument(source)
    #expect(layout.members[0].key == "a")
  }

  @Test func parsesUnquotedIdentifierKey() throws {
    let source = "{ a: 1, b_2: 2 }"
    let layout = try JSON5Scanner.parseDocument(source)
    #expect(layout.members.map(\.key) == ["a", "b_2"])
  }

  @Test func parsesTrailingCommaInObject() throws {
    let source = """
      {
        "a": 1,
        "b": 2,
      }
      """
    let layout = try JSON5Scanner.parseDocument(source)
    #expect(layout.members.count == 2)
    // Both have trailing commas now.
    #expect(layout.members[1].trailingComma != nil)
  }

  @Test func parsesHexAndSpecialNumbers() throws {
    let source = "{ a: 0xFF, b: -Infinity, c: NaN, d: +1.5e3 }"
    let layout = try JSON5Scanner.parseDocument(source)
    #expect(layout.members.map(\.key) == ["a", "b", "c", "d"])
  }

  @Test func parsesArrayValuesIncludingTrailingComma() throws {
    let source = """
      {
        "a": [1, 2, 3,],
        "b": []
      }
      """
    let layout = try JSON5Scanner.parseDocument(source)
    #expect(layout.members.map(\.key) == ["a", "b"])
  }

  // MARK: - String edge cases

  @Test func handlesStringWithEmbeddedClosingBraceAndEscapes() throws {
    let source = #"{ "a": "}}}", "b": "with \"quotes\" and \n" }"#
    let layout = try JSON5Scanner.parseDocument(source)
    #expect(layout.members.map(\.key) == ["a", "b"])
    // Value range for "a" exactly covers the quoted string.
    let a = layout.members[0]
    #expect(source[a.valueRange] == #""}}}""#)
  }

  // MARK: - Trailing-comma round-trip

  @Test func memberWithTrailingCommaHasCommaInRange() throws {
    let source = #"{ "a": 1, "b": 2 }"#
    let layout = try JSON5Scanner.parseDocument(source)
    let a = layout.members[0]
    let comma = try #require(a.trailingComma)
    #expect(source[comma] == ",")
  }

  // MARK: - Indent capture

  @Test func capturesIndentForNestedChildren() throws {
    let source = """
      {
          "wrap": {
              "preferIsEmpty": { "lint": "warn" }
          }
      }
      """
    let layout = try JSON5Scanner.parseDocument(source)
    let nested = try #require(layout.members.first?.nested)
    let child = nested.members[0]
    #expect(child.indent == "        ")
  }
}
