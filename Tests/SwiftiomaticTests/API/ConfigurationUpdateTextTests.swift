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
