@testable import ConfigurationKit
import Foundation
@testable import SwiftiomaticKit
import Testing

@Suite
struct ConfigurationUpdateTests {

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

  // MARK: - Missing rules

  @Test func detectsMissingRules() throws {
    let root = try parse("""
      { "version": 6 }
      """)

    let diff = Configuration.computeUpdate(for: root)

    #expect(diff.toAdd.contains("idioms.preferIsEmpty"))
    #expect(diff.toAdd.contains("redundancies.semicolons"))
    #expect(diff.toRemove.isEmpty)
    #expect(diff.misplaced.isEmpty)
  }

  // MARK: - Unknown / removed rules

  @Test func detectsUnknownGroupedRule() throws {
    let root = try parse("""
      {
        "wrap": {
          "fakeRule": { "lint": "warn" }
        }
      }
      """)

    let diff = Configuration.computeUpdate(for: root)

    #expect(diff.toRemove.contains("wrap.fakeRule"))
    #expect(diff.misplaced.isEmpty)
  }

  @Test func detectsUnknownUngroupedRule() throws {
    let root = try parse("""
      { "fakeUngroupedRule": { "lint": "warn" } }
      """)

    let diff = Configuration.computeUpdate(for: root)

    #expect(diff.toRemove.contains("fakeUngroupedRule"))
    #expect(diff.misplaced.isEmpty)
  }

  // MARK: - Misplaced rules

  @Test func detectsMisplacedRuleInWrongGroup() throws {
    // preferIsEmpty belongs in `idioms`, not `wrap`.
    let root = try parse("""
      {
        "wrap": {
          "preferIsEmpty": { "lint": "warn", "rewrite": false }
        }
      }
      """)

    let diff = Configuration.computeUpdate(for: root)

    let entry = try #require(diff.misplaced.first)
    #expect(entry.foundAt == "wrap.preferIsEmpty")
    #expect(entry.correctAt == "idioms.preferIsEmpty")
    #expect(diff.toRemove.isEmpty)
    #expect(!diff.toAdd.contains("idioms.preferIsEmpty"))
  }

  @Test func detectsRulePlacedInWrongGroup() throws {
    // emptyExtensions belongs to `declarations`; placing it in `wrap` is misplaced.
    let root = try parse("""
      {
        "wrap": {
          "emptyExtensions": { "lint": "warn" }
        }
      }
      """)

    let diff = Configuration.computeUpdate(for: root)

    let entry = try #require(diff.misplaced.first)
    #expect(entry.foundAt == "wrap.emptyExtensions")
    #expect(entry.correctAt == "declarations.emptyExtensions")
  }

  @Test func detectsGroupedRulePlacedAtRoot() throws {
    let root = try parse("""
      { "preferIsEmpty": { "lint": "warn", "rewrite": false } }
      """)

    let diff = Configuration.computeUpdate(for: root)

    let entry = try #require(diff.misplaced.first)
    #expect(entry.foundAt == "preferIsEmpty")
    #expect(entry.correctAt == "idioms.preferIsEmpty")
  }

  // MARK: - Apply preserves misplaced values

  @Test func applyMovesMisplacedRulePreservingValues() throws {
    var root = try parse("""
      {
        "wrap": {
          "preferIsEmpty": { "lint": "warn", "rewrite": false }
        }
      }
      """)
    let originalValue: JSONValue? = {
      guard case .object(let d) = root["wrap"] else { return nil }
      return d["preferIsEmpty"]
    }()

    let diff = Configuration.computeUpdate(for: root)
    Configuration.apply(diff, to: &root, defaults: try defaultsDict())

    // Original location no longer has it.
    if case .object(let wrapDict) = root["wrap"] {
      #expect(wrapDict["preferIsEmpty"] == nil)
    }

    // New location has the user's original value, not the default.
    guard case .object(let idiomsDict) = root["idioms"] else {
      Issue.record("idioms group missing after apply")
      return
    }
    #expect(idiomsDict["preferIsEmpty"] == originalValue)
  }

  @Test func applyRemovesUnknownRules() throws {
    var root = try parse("""
      {
        "wrap": {
          "fakeRule": { "lint": "warn" }
        },
        "fakeUngroupedRule": { "lint": "warn" }
      }
      """)

    let diff = Configuration.computeUpdate(for: root)
    Configuration.apply(diff, to: &root, defaults: try defaultsDict())

    if case .object(let wrapDict) = root["wrap"] {
      #expect(wrapDict["fakeRule"] == nil)
    }
    #expect(root["fakeUngroupedRule"] == nil)
  }

  @Test func applyAddsMissingRulesWithDefaults() throws {
    var root: [String: JSONValue] = ["version": .int(6)]

    let diff = Configuration.computeUpdate(for: root)
    Configuration.apply(diff, to: &root, defaults: try defaultsDict())

    let postDiff = Configuration.computeUpdate(for: root)
    #expect(postDiff.toAdd.isEmpty)
    #expect(postDiff.toRemove.isEmpty)
    #expect(postDiff.misplaced.isEmpty)
  }

  // MARK: - Idempotence

  @Test func defaultConfigurationIsUpToDate() throws {
    let data = try JSONEncoder().encode(Configuration())
    let root = try JSONDecoder().decode([String: JSONValue].self, from: data)

    let diff = Configuration.computeUpdate(for: root)

    #expect(!diff.hasChanges)
  }
}
