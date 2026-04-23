import ArgumentParser
import Foundation
import SwiftiomaticKit

extension SwiftiomaticCommand {
  struct Update: ParsableCommand {
    nonisolated(unsafe) static var configuration = CommandConfiguration(
      abstract: "Update the configuration file to match the current rule registry",
      discussion: """
        Compares rule entries in swiftiomatic.json against the built-in rule registry. \
        Removes entries for rules that no longer exist and adds entries for new rules \
        (with their default values). All other settings and values are preserved.
        """
    )

    @OptionGroup()
    var configurationOptions: ConfigurationOptions

    func run() throws {
      // 1. Find and read the configuration file.
      let (configURL, data) = try findConfiguration()

      // 2. Parse as JSONValue to inspect keys.
      let decoder = JSONDecoder()
      decoder.allowsJSON5 = true
      let rootValue = try decoder.decode(JSONValue.self, from: data)

      guard case .object(var rootDict) = rootValue else {
        printError("Configuration file is not a JSON object")
        throw ExitCode.failure
      }

      // 3. Compute diff.
      let validKeys = Configuration.allRuleQualifiedKeys
      let fileKeys = extractRuleKeys(from: rootDict)

      let toAdd = validKeys.subtracting(fileKeys).sorted()
      let toRemove = fileKeys.subtracting(validKeys).sorted()

      guard !toAdd.isEmpty || !toRemove.isEmpty else {
        print("Configuration is up to date.")
        return
      }

      // 4. Show planned changes.
      if !toRemove.isEmpty {
        print("Rules to remove:")
        for key in toRemove { print("  - \(key)") }
      }
      if !toAdd.isEmpty {
        print("Rules to add (with defaults):")
        for key in toAdd { print("  + \(key)") }
      }

      print("\nType \"yes\" to apply changes:")
      guard readLine()?.trimmingCharacters(in: .whitespaces).lowercased() == "yes" else {
        print("Cancelled.")
        return
      }

      // 5. Get default values for new rules from a default Configuration.
      let defaultJSON = try encodeDefaultConfiguration()

      // 6. Apply removals.
      for key in toRemove {
        let parts = key.split(separator: ".", maxSplits: 1).map(String.init)
        if parts.count == 2, case .object(var groupDict) = rootDict[parts[0]] {
          groupDict.removeValue(forKey: parts[1])
          rootDict[parts[0]] = .object(groupDict)
        } else {
          rootDict.removeValue(forKey: key)
        }
      }

      // 7. Apply additions.
      for key in toAdd {
        let parts = key.split(separator: ".", maxSplits: 1).map(String.init)

        if parts.count == 2 {
          // Grouped rule.
          let groupName = parts[0]
          let ruleName = parts[1]
          let value = extractRuleValue(qualifiedKey: key, shortKey: ruleName, from: defaultJSON)

          if case .object(var groupDict) = rootDict[groupName] {
            groupDict[ruleName] = value
            rootDict[groupName] = .object(groupDict)
          } else {
            // Group doesn't exist yet — create it.
            rootDict[groupName] = .object([ruleName: value])
          }
        } else {
          // Ungrouped rule.
          let value = extractRuleValue(qualifiedKey: key, shortKey: key, from: defaultJSON)
          rootDict[key] = value
        }
      }

      // 8. Serialize and write.
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
      let output = try encoder.encode(JSONValue.object(rootDict))

      guard var jsonString = String(data: output, encoding: .utf8) else {
        printError("Failed to encode JSON as UTF-8")
        throw ExitCode.failure
      }

      jsonString = compactSmallObjects(in: jsonString, maxWidth: 100)

      try jsonString.write(to: configURL, atomically: true, encoding: .utf8)

      // 9. Report.
      if !toRemove.isEmpty {
        print("Removed \(toRemove.count) rule\(toRemove.count == 1 ? "" : "s").")
      }
      if !toAdd.isEmpty {
        print("Added \(toAdd.count) rule\(toAdd.count == 1 ? "" : "s").")
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
