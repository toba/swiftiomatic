@testable import ConfigurationKit
import Foundation
@testable import SwiftiomaticKit
import Testing

@Suite
struct ConfigurationUpdateTextTests {

  // MARK: - Helpers

  private func parse(_ json: String) throws -> [String: JSONValue] {
    let decoder = JSONDecoder()
    decoder.allowsJSON5 = true
    let data = json.data(using: .utf8)!
    let value = try decoder.decode(JSONValue.self, from: data)
    guard case .object(let dict) = value else {
      Issue.record("Expected JSON object")
      return [:]
    }
    return dict
  }

  private func defaultsDict() throws -> [String: JSONValue] {
    let data = try JSONEncoder().encode(Configuration())
    return try JSONDecoder().decode([String: JSONValue].self, from: data)
  }

  // MARK: - Removal

  @Test func removesUnknownGroupedRule() throws {
    let original = """
      {
        "version": 6,
        "wrap": {
          "preferIsEmpty": { "lint": "warn" },
          "fakeRule": { "lint": "warn" }
        }
      }
      """

    let diff = Configuration.UpdateDiff(
      toAdd: [],
      toRemove: ["wrap.fakeRule"],
      misplaced: []
    )

    let result = try Configuration.applyUpdateText(
      diff, to: original, defaults: try defaultsDict()
    )

    #expect(!result.contains("fakeRule"))
    // Sibling preserved.
    #expect(result.contains("\"preferIsEmpty\": { \"lint\": \"warn\" }"))
    // Trailing comma on preferIsEmpty removed since it's now last child.
    #expect(!result.contains("\"warn\" },\n  }"))
    // Reparses cleanly.
    _ = try parse(result)
  }

  @Test func removesUnknownUngroupedRuleAtRoot() throws {
    let original = """
      {
        "version": 6,
        "fakeUngrouped": { "lint": "warn" },
        "lineLength": 100
      }
      """

    let diff = Configuration.UpdateDiff(
      toAdd: [],
      toRemove: ["fakeUngrouped"],
      misplaced: []
    )

    let result = try Configuration.applyUpdateText(
      diff, to: original, defaults: try defaultsDict()
    )

    #expect(!result.contains("fakeUngrouped"))
    #expect(result.contains("\"version\": 6"))
    #expect(result.contains("\"lineLength\": 100"))
    _ = try parse(result)
  }

  @Test func removingLastChildFixesPreviousSiblingComma() throws {
    let original = """
      {
        "wrap": {
          "first": { "lint": "warn" },
          "fakeLast": { "lint": "warn" }
        }
      }
      """

    let diff = Configuration.UpdateDiff(
      toAdd: [],
      toRemove: ["wrap.fakeLast"],
      misplaced: []
    )

    let result = try Configuration.applyUpdateText(
      diff, to: original, defaults: try defaultsDict()
    )

    // No trailing comma on the now-last `first` member.
    let firstLine = result.split(separator: "\n").first(where: { $0.contains("\"first\"") })!
    #expect(!firstLine.hasSuffix(","))
    _ = try parse(result)
  }

  // MARK: - Order preservation

  @Test func preservesExistingKeyOrderOnAdd() throws {
    let original = """
      {
        "version": 6,
        "wrap": {
          "z_existing": { "lint": "warn" },
          "a_existing": { "lint": "warn" }
        }
      }
      """

    let diff = Configuration.UpdateDiff(
      toAdd: ["wrap.aaaNewRule"],
      toRemove: [],
      misplaced: []
    )

    let defaults: [String: JSONValue] = [
      "wrap": .object(["aaaNewRule": .object(["lint": .string("warn")])])
    ]

    let result = try Configuration.applyUpdateText(diff, to: original, defaults: defaults)

    // z_existing must still come before a_existing (no reordering).
    let zIdx = result.range(of: "z_existing")!.lowerBound
    let aIdx = result.range(of: "a_existing")!.lowerBound
    #expect(zIdx < aIdx)
    // New rule appended at end.
    let newIdx = result.range(of: "aaaNewRule")!.lowerBound
    #expect(aIdx < newIdx)
    _ = try parse(result)
  }

  // MARK: - Comments

  @Test func preservesLineComments() throws {
    let original = """
      // Project config
      {
        "version": 6,
        // wrap settings
        "wrap": {
          "fakeRule": { "lint": "warn" }
        }
      }
      """

    let diff = Configuration.UpdateDiff(
      toAdd: [],
      toRemove: ["wrap.fakeRule"],
      misplaced: []
    )

    let result = try Configuration.applyUpdateText(
      diff, to: original, defaults: try defaultsDict()
    )

    #expect(result.contains("// Project config"))
    #expect(result.contains("// wrap settings"))
    _ = try parse(result)
  }

  // MARK: - Misplaced

  @Test func misplacedRulePreservesValueAtNewLocation() throws {
    let original = """
      {
        "version": 6,
        "wrap": {
          "preferIsEmpty": { "lint": "warn", "rewrite": false }
        }
      }
      """

    let diff = Configuration.UpdateDiff(
      toAdd: [],
      toRemove: [],
      misplaced: [
        .init(
          foundAt: "wrap.preferIsEmpty",
          correctAt: "idioms.preferIsEmpty",
          value: .object([
            "lint": .string("warn"),
            "rewrite": .bool(false),
          ])
        )
      ]
    )

    let result = try Configuration.applyUpdateText(
      diff, to: original, defaults: try defaultsDict()
    )

    // Removed from wrap, present in idioms with same value.
    let dict = try parse(result)
    if case .object(let wrap) = dict["wrap"] {
      #expect(wrap["preferIsEmpty"] == nil)
    }
    if case .object(let idioms) = dict["idioms"] {
      #expect(
        idioms["preferIsEmpty"]
          == .object(["lint": .string("warn"), "rewrite": .bool(false)])
      )
    } else {
      Issue.record("idioms group not created")
    }
    // Existing version line preserved verbatim.
    #expect(result.contains("\"version\": 6"))
  }

  // MARK: - Length-sort placement

  /// Returns the index at which `key` first appears in `source`, or `nil` if absent.
  private func indexOf(_ key: String, in source: String) -> String.Index? {
    source.range(of: "\"\(key)\"")?.lowerBound
  }

  @Test func newRuleLandsInLengthSortedMiddle() throws {
    // Existing keys length 5 (`short`) and 15 (`reallyLongRule1`). New key
    // length 10 (`midLenRule`) belongs between them.
    let original = """
      {
        "wrap": {
          "short": { "lint": "warn" },
          "reallyLongRule1": { "lint": "warn" }
        }
      }
      """

    let diff = Configuration.UpdateDiff(
      toAdd: ["wrap.midLenRule"],
      toRemove: [],
      misplaced: []
    )
    let defaults: [String: JSONValue] = [
      "wrap": .object(["midLenRule": .object(["lint": .string("warn")])])
    ]

    let result = try Configuration.applyUpdateText(diff, to: original, defaults: defaults)

    let shortIdx = indexOf("short", in: result)!
    let midIdx = indexOf("midLenRule", in: result)!
    let longIdx = indexOf("reallyLongRule1", in: result)!
    #expect(shortIdx < midIdx)
    #expect(midIdx < longIdx)
    _ = try parse(result)
  }

  @Test func newRuleShorterThanAllExistingLandsFirst() throws {
    let original = """
      {
        "wrap": {
          "midLenRule": { "lint": "warn" },
          "reallyLongRule1": { "lint": "warn" }
        }
      }
      """

    let diff = Configuration.UpdateDiff(
      toAdd: ["wrap.short"],
      toRemove: [],
      misplaced: []
    )
    let defaults: [String: JSONValue] = [
      "wrap": .object(["short": .object(["lint": .string("warn")])])
    ]

    let result = try Configuration.applyUpdateText(diff, to: original, defaults: defaults)

    let shortIdx = indexOf("short", in: result)!
    let midIdx = indexOf("midLenRule", in: result)!
    let longIdx = indexOf("reallyLongRule1", in: result)!
    #expect(shortIdx < midIdx)
    #expect(midIdx < longIdx)
    _ = try parse(result)
  }

  @Test func newRuleLongerThanAllExistingLandsLast() throws {
    let original = """
      {
        "wrap": {
          "short": { "lint": "warn" },
          "midLenRule": { "lint": "warn" }
        }
      }
      """

    let diff = Configuration.UpdateDiff(
      toAdd: ["wrap.reallyLongRule1"],
      toRemove: [],
      misplaced: []
    )
    let defaults: [String: JSONValue] = [
      "wrap": .object(["reallyLongRule1": .object(["lint": .string("warn")])])
    ]

    let result = try Configuration.applyUpdateText(diff, to: original, defaults: defaults)

    let shortIdx = indexOf("short", in: result)!
    let midIdx = indexOf("midLenRule", in: result)!
    let longIdx = indexOf("reallyLongRule1", in: result)!
    #expect(shortIdx < midIdx)
    #expect(midIdx < longIdx)
    _ = try parse(result)
  }

  @Test func multipleNewRulesInterleaveByLength() throws {
    // Existing length 5 and 20. Add three new of varying lengths; all should
    // land in length-sorted order among themselves and the existing siblings.
    let original = """
      {
        "wrap": {
          "short": { "lint": "warn" },
          "extremelyVeryLongRule": { "lint": "warn" }
        }
      }
      """

    let diff = Configuration.UpdateDiff(
      toAdd: ["wrap.eightLen", "wrap.twelveCharsX", "wrap.twelveCharsY"],
      toRemove: [],
      misplaced: []
    )
    let defaults: [String: JSONValue] = [
      "wrap": .object([
        "eightLen": .object(["lint": .string("warn")]),
        "twelveCharsX": .object(["lint": .string("warn")]),
        "twelveCharsY": .object(["lint": .string("warn")]),
      ])
    ]

    let result = try Configuration.applyUpdateText(diff, to: original, defaults: defaults)

    let i5 = indexOf("short", in: result)!
    let i8 = indexOf("eightLen", in: result)!
    let i12x = indexOf("twelveCharsX", in: result)!
    let i12y = indexOf("twelveCharsY", in: result)!
    let i20 = indexOf("extremelyVeryLongRule", in: result)!
    #expect(i5 < i8)
    #expect(i8 < i12x)
    #expect(i12x < i12y)
    #expect(i12y < i20)
    _ = try parse(result)
  }

  @Test func newGroupChildrenAreLengthSorted() throws {
    let original = """
      {
        "version": 6
      }
      """

    let diff = Configuration.UpdateDiff(
      toAdd: ["idioms.midLenRule", "idioms.short", "idioms.extremelyVeryLongRule"],
      toRemove: [],
      misplaced: []
    )
    let defaults: [String: JSONValue] = [
      "idioms": .object([
        "midLenRule": .object(["lint": .string("warn")]),
        "short": .object(["lint": .string("warn")]),
        "extremelyVeryLongRule": .object(["lint": .string("warn")]),
      ])
    ]

    let result = try Configuration.applyUpdateText(diff, to: original, defaults: defaults)

    let iShort = indexOf("short", in: result)!
    let iMid = indexOf("midLenRule", in: result)!
    let iLong = indexOf("extremelyVeryLongRule", in: result)!
    #expect(iShort < iMid)
    #expect(iMid < iLong)
    _ = try parse(result)
  }

  @Test func createsNewGroupWhenAbsent() throws {
    let original = """
      {
        "version": 6
      }
      """

    let diff = Configuration.UpdateDiff(
      toAdd: ["idioms.preferIsEmpty"],
      toRemove: [],
      misplaced: []
    )

    let defaults: [String: JSONValue] = [
      "idioms": .object([
        "preferIsEmpty": .object(["lint": .string("warn")])
      ])
    ]

    let result = try Configuration.applyUpdateText(diff, to: original, defaults: defaults)

    let dict = try parse(result)
    if case .object(let idioms) = dict["idioms"] {
      #expect(idioms["preferIsEmpty"] != nil)
    } else {
      Issue.record("idioms group not created")
    }
    // Existing version unchanged.
    #expect(result.contains("\"version\": 6"))
  }
}
