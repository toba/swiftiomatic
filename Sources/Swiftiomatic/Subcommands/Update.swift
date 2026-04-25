import ArgumentParser
import Foundation
import SwiftiomaticKit

extension SwiftiomaticCommand {
  struct Update: ParsableCommand {
    static let configuration = CommandConfiguration(
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

      guard let originalSource = String(data: data, encoding: .utf8) else {
        printError("Configuration file is not valid UTF-8")
        throw ExitCode.failure
      }

      let decoder = JSONDecoder()
      decoder.allowsJSON5 = true
      let rootValue = try decoder.decode(JSONValue.self, from: data)

      guard case .object(let rootDict) = rootValue else {
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
      let updated = try Configuration.applyUpdateText(
        diff,
        to: originalSource,
        defaults: defaultJSON
      )

      try updated.write(to: configURL, atomically: true, encoding: .utf8)

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

    /// Encodes a default Configuration to a `JSONValue` dict so additions
    /// can pull canonical default values for newly-recognized rules.
    private func encodeDefaultConfiguration() throws -> [String: JSONValue] {
      let config = Configuration()
      let data = try JSONEncoder().encode(config)
      let value = try JSONDecoder().decode([String: JSONValue].self, from: data)
      return value
    }

    private func printError(_ message: String) {
      FileHandle.standardError.write(Data("error: \(message)\n".utf8))
    }
  }
}
