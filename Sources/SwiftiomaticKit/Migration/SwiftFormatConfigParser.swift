import Foundation

/// Parsed representation of a `.swiftformat` configuration file
public struct SwiftFormatConfig: Sendable {
  /// Rules explicitly enabled (from `--rules` or `--enable`)
  public var enabledRules: [String] = []
  /// Rules explicitly disabled (from `--disable`)
  public var disabledRules: [String] = []
  /// Indentation setting (from `--indent`)
  public var indent: String?
  /// Maximum line width (from `--maxwidth`)
  public var maxWidth: Int?
  /// Trailing comma setting (from `--commas`)
  public var commas: String?
  /// Swift version (from `--swiftversion`)
  public var swiftVersion: String?
  /// Paths to exclude (from `--exclude`)
  public var excludedPaths: [String] = []
  /// All raw options for reference
  public var rawOptions: [String: String] = [:]
}

/// Parses SwiftFormat `.swiftformat` configuration files
///
/// SwiftFormat config files use `--option value` syntax, one per line.
public enum SwiftFormatConfigParser {
  /// Parse a `.swiftformat` file at the given path
  ///
  /// - Parameters:
  ///   - path: File system path to the `.swiftformat` file.
  /// - Returns: The parsed ``SwiftFormatConfig``.
  public static func parse(at path: String) throws -> SwiftFormatConfig {
    let contents = try String(contentsOfFile: path, encoding: .utf8)
    return parse(contents: contents)
  }

  /// Parse a `.swiftformat` from its text content
  ///
  /// - Parameters:
  ///   - contents: The file contents as a string.
  /// - Returns: The parsed ``SwiftFormatConfig``.
  public static func parse(contents: String) -> SwiftFormatConfig {
    var config = SwiftFormatConfig()

    for line in contents.components(separatedBy: .newlines) {
      let trimmed = line.trimmingCharacters(in: .whitespaces)
      // Skip empty lines and comments
      guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }

      // Parse --option value
      guard trimmed.hasPrefix("--") else { continue }

      let parts = trimmed.split(separator: " ", maxSplits: 1)
      let option = String(parts[0].dropFirst(2))  // remove "--"
      let value = parts.count > 1 ? String(parts[1]).trimmingCharacters(in: .whitespaces) : ""

      config.rawOptions[option] = value

      switch option {
      case "rules":
        config.enabledRules += parseCommaList(value)
      case "enable":
        config.enabledRules += parseCommaList(value)
      case "disable":
        config.disabledRules += parseCommaList(value)
      case "indent":
        config.indent = value
      case "maxwidth":
        config.maxWidth = Int(value)
      case "commas":
        config.commas = value
      case "swiftversion":
        config.swiftVersion = value
      case "exclude":
        config.excludedPaths += parseCommaList(value)
      default:
        break
      }
    }

    return config
  }

  private static func parseCommaList(_ value: String) -> [String] {
    value.split(separator: ",")
      .map { $0.trimmingCharacters(in: .whitespaces) }
      .filter { !$0.isEmpty }
  }
}
