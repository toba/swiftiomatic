import ArgumentParser
import Foundation
import SwiftiomaticKit

extension SwiftiomaticCommand {
  struct Update: ParsableCommand {
    nonisolated(unsafe) static var configuration = CommandConfiguration(
      abstract: "Update the configuration file to match the current rule registry",
      discussion: """
        Compares rule entries in swiftiomatic.json against the built-in rule registry. \
        Removes entries for rules that no longer exist, adds entries for new rules \
        (with their default values), and warns about rules placed in the wrong group — \
        moving them to the correct location while preserving the user's customized values. \
        All other settings and values are preserved.
        """
    )

    @OptionGroup()
    var configurationOptions: ConfigurationOptions

    func run() throws {
      let (configURL, data) = try findConfiguration()

      let decoder = JSONDecoder()
      decoder.allowsJSON5 = true
      let rootValue = try decoder.decode(JSONValue.self, from: data)

      guard case .object(var rootDict) = rootValue else {
        printError("Configuration file is not a JSON object")
        throw ExitCode.failure
      }

      let diff = Configuration.computeUpdate(for: rootDict)

      guard diff.hasChanges else {
        print("Configuration is up to date.")
        return
      }

      if !diff.misplaced.isEmpty {
        print("Misplaced rules (will be moved, preserving your values):")
        for entry in diff.misplaced {
          print("  ! \(entry.foundAt) → \(entry.correctAt)")
        }
      }
      if !diff.toRemove.isEmpty {
        print("Unknown rules to remove:")
        for key in diff.toRemove { print("  - \(key)") }
      }
      if !diff.toAdd.isEmpty {
        print("Rules to add (with defaults):")
        for key in diff.toAdd { print("  + \(key)") }
      }

      print("\nType \"yes\" to apply changes:")
      guard readLine()?.trimmingCharacters(in: .whitespaces).lowercased() == "yes" else {
        print("Cancelled.")
        return
      }

      let defaultJSON = try encodeDefaultConfiguration()
      Configuration.apply(diff, to: &rootDict, defaults: defaultJSON)

      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
      let output = try encoder.encode(JSONValue.object(rootDict))

      guard var jsonString = String(data: output, encoding: .utf8) else {
        printError("Failed to encode JSON as UTF-8")
        throw ExitCode.failure
      }

      jsonString = compactSmallObjects(in: jsonString, maxWidth: 100)

      try jsonString.write(to: configURL, atomically: true, encoding: .utf8)

      if !diff.misplaced.isEmpty {
        print("Moved \(diff.misplaced.count) rule\(diff.misplaced.count == 1 ? "" : "s").")
      }
      if !diff.toRemove.isEmpty {
        print("Removed \(diff.toRemove.count) rule\(diff.toRemove.count == 1 ? "" : "s").")
      }
      if !diff.toAdd.isEmpty {
        print("Added \(diff.toAdd.count) rule\(diff.toAdd.count == 1 ? "" : "s").")
      }
      print("Updated \(configURL.path)")
    }

    // MARK: - Helpers

    private func findConfiguration() throws -> (URL, Data) {
      let configURL: URL

      if let explicit = configurationOptions.configuration {
        let url = URL(fileURLWithPath: explicit)
        guard FileManager.default.isReadableFile(atPath: url.path) else {
          printError("Configuration file not found: \(explicit)")
          throw ExitCode.failure
        }
        configURL = url
      } else {
        let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
        guard let found = Configuration.url(forConfigurationFileApplyingTo: cwd) else {
          printError("No swiftiomatic.json found in current directory or parents")
          throw ExitCode.failure
        }
        configURL = found
      }

      let data = try Data(contentsOf: configURL)
      return (configURL, data)
    }

    /// Extracts all rule qualified keys present in the JSON.
    private func extractRuleKeys(from root: [String: JSONValue]) -> Set<String> {
      let metaKeys = Configuration.allSettingAndMetaKeys
      let groupNames = Configuration.groupKeyNames
      var keys = Set<String>()

      for (key, value) in root {
        if metaKeys.contains(key) { continue }

        if groupNames.contains(key), case .object(let groupDict) = value,
          let groupKey = ConfigurationGroup.Key(rawValue: key)
        {
          // Grouped: settings vs rules.
          let settingKeys = Configuration.settingKeys(inGroup: groupKey)
          for ruleKey in groupDict.keys where !settingKeys.contains(ruleKey) {
            keys.insert("\(key).\(ruleKey)")
          }
        } else {
          // Root-level rule.
          keys.insert(key)
        }
      }

      return keys
    }

    /// Encodes a default Configuration to JSONValue dict.
    private func encodeDefaultConfiguration() throws -> [String: JSONValue] {
      let config = Configuration()
      let data = try JSONEncoder().encode(config)
      let value = try JSONDecoder().decode([String: JSONValue].self, from: data)
      return value
    }

    /// Extracts a rule's default value from the encoded default Configuration.
    private func extractRuleValue(
      qualifiedKey: String,
      shortKey: String,
      from defaultJSON: [String: JSONValue]
    ) -> JSONValue {
      let parts = qualifiedKey.split(separator: ".", maxSplits: 1).map(String.init)

      if parts.count == 2 {
        // Grouped rule — look inside the group object.
        if case .object(let groupDict) = defaultJSON[parts[0]] {
          return groupDict[shortKey] ?? .object([:])
        }
      } else {
        // Ungrouped rule.
        if let value = defaultJSON[shortKey] {
          return value
        }
      }

      return .object([:])
    }

    /// Collapses multi-line JSON objects onto a single line when they fit
    /// within `maxWidth` columns and contain only scalar values.
    /// Mirrors `Configuration+Dump.swift` logic.
    private func compactSmallObjects(in json: String, maxWidth: Int) -> String {
      let lines = json.components(separatedBy: "\n")
      var result: [String] = []
      var i = 0

      while i < lines.count {
        let line = lines[i]
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        if trimmed.hasSuffix("{") && trimmed.contains("\"") {
          var objectLines = [line]
          var depth = 1
          var j = i + 1
          var hasNestedObject = false

          while j < lines.count && depth > 0 {
            let inner = lines[j].trimmingCharacters(in: .whitespaces)
            if inner.contains("{") { depth += 1; hasNestedObject = true }
            if inner.contains("}") { depth -= 1 }
            objectLines.append(lines[j])
            j += 1
          }

          if !hasNestedObject && depth == 0 {
            let compact = compactObject(objectLines)
            if compact.count <= maxWidth {
              result.append(compact)
              i = j
              continue
            }
          }
        }

        result.append(line)
        i += 1
      }

      return result.joined(separator: "\n")
    }

    private func compactObject(_ lines: [String]) -> String {
      guard let first = lines.first else { return "" }

      let indent = first.prefix(while: { $0 == " " })
      let keyPart = first.trimmingCharacters(in: .whitespaces)
      let keyPrefix = String(keyPart.dropLast()).trimmingCharacters(in: .whitespaces)

      var pairs: [String] = []
      for line in lines.dropFirst().dropLast() {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let clean = trimmed.hasSuffix(",") ? String(trimmed.dropLast()) : trimmed
        if !clean.isEmpty { pairs.append(clean) }
      }

      let lastLine = lines.last!.trimmingCharacters(in: .whitespaces)
      let trailingComma = lastLine.hasSuffix(",") ? "," : ""

      let interior = pairs.joined(separator: ", ")
      return "\(indent)\(keyPrefix) { \(interior) }\(trailingComma)"
    }

    private func printError(_ message: String) {
      FileHandle.standardError.write(Data("error: \(message)\n".utf8))
    }
  }
}
