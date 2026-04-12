import Foundation
import SwiftiomaticSyntax

/// A single inline comment replacement
public struct InlineCommentChange: Equatable, Sendable {
  /// The file path where the change was made
  public let file: String
  /// The 1-based line number
  public let line: Int
  /// The original comment text
  public let before: String
  /// The replacement comment text
  public let after: String
}

/// Result of migrating inline comments across source files
public struct InlineCommentMigrationResult: Sendable {
  /// All changes made (or that would be made in dry-run mode)
  public var changes: [InlineCommentChange] = []
  /// Warnings about unmapped rule IDs found in comments
  public var warnings: [MigrationWarning] = []
  /// Number of files modified
  public var filesModified: Int = 0
}

/// Migrates `swiftlint:` and `swiftformat:` inline comments to `sm:` equivalents
public enum InlineCommentMigrator {
  /// Regex matching swiftlint/swiftformat disable/enable comments
  ///
  /// Captures:
  /// 1. The tool prefix (`swiftlint` or `swiftformat`)
  /// 2. The action and optional modifier (`disable`, `enable`, `disable:next`, etc.)
  /// 3. The rule IDs and optional trailing comment
  nonisolated(unsafe) private static let commentPattern =
    #/\/\/\s*(swiftlint|swiftformat):(disable|enable|disable:next|disable:this|disable:previous|enable:next|enable:this|enable:previous)\s+(.+)/#

  /// Migrate inline comments in the given source files
  ///
  /// - Parameters:
  ///   - paths: Paths to files or directories to scan.
  ///   - dryRun: If `true`, report changes without modifying files.
  /// - Returns: The migration result with all changes and warnings.
  public static func migrate(
    paths: [String],
    dryRun: Bool = false,
  ) -> InlineCommentMigrationResult {
    let files = FileDiscovery.findSwiftFiles(in: paths)
    var result = InlineCommentMigrationResult()

    for file in files {
      guard let contents = try? String(contentsOfFile: file, encoding: .utf8) else {
        continue
      }

      let (migrated, changes, warnings) = migrateContents(contents, file: file)

      if !changes.isEmpty {
        result.changes.append(contentsOf: changes)
        result.warnings.append(contentsOf: warnings)
        result.filesModified += 1

        if !dryRun {
          try? migrated.write(toFile: file, atomically: true, encoding: .utf8)
        }
      }
    }

    return result
  }

  /// Migrate inline comments in a single string of source code
  ///
  /// - Parameters:
  ///   - contents: The source code string.
  ///   - file: The file path (for reporting).
  /// - Returns: A tuple of (migrated source, changes, warnings).
  public static func migrateContents(
    _ contents: String,
    file: String = "<input>",
  ) -> (String, [InlineCommentChange], [MigrationWarning]) {
    let lines = contents.components(separatedBy: "\n")
    var outputLines: [String] = []
    var changes: [InlineCommentChange] = []
    var warnings: [MigrationWarning] = []

    for (index, line) in lines.enumerated() {
      let lineNumber = index + 1

      guard let match = line.firstMatch(of: commentPattern) else {
        outputLines.append(line)
        continue
      }

      let tool = String(match.output.1)
      let action = String(match.output.2)
      let rest = String(match.output.3)

      // Map the action — swiftlint and sm use the same modifiers
      let smAction = action

      // Parse rule IDs and optional trailing comment
      let (ruleIDs, trailingComment) = parseRuleIDsAndComment(rest)

      // Map rule IDs
      var mappedIDs: [String] = []
      for ruleID in ruleIDs {
        if ruleID == "all" {
          mappedIDs.append("all")
          continue
        }

        let mapping: MappedRule =
          if tool == "swiftlint" {
            RuleMapping.swiftlint(ruleID)
          } else {
            RuleMapping.swiftformat(ruleID)
          }

        switch mapping {
        case .exact(let id):
          mappedIDs.append(id)
        case .renamed(_, let new):
          mappedIDs.append(new)
        case .removed:
          // Drop removed rules from the comment
          warnings.append(
            MigrationWarning(
              source: tool == "swiftlint" ? "SwiftLint" : "SwiftFormat",
              identifier: ruleID,
              message: "Rule removed — dropped from comment at \(file):\(lineNumber)",
            ))
        case .unmapped:
          // Keep unmapped rules as-is with a warning
          mappedIDs.append(ruleID)
          warnings.append(
            MigrationWarning(
              source: tool == "swiftlint" ? "SwiftLint" : "SwiftFormat",
              identifier: ruleID,
              message:
                "No Swiftiomatic equivalent — kept as-is at \(file):\(lineNumber)",
            ))
        }
      }

      // If all rules were removed, drop the entire comment line
      if mappedIDs.isEmpty {
        // Keep the line but without the comment if there's code before it
        let beforeComment =
          line[line.startIndex..<match.output.0.startIndex]
          .trimmingCharacters(in: .whitespaces)
        if beforeComment.isEmpty {
          // Entire line is the comment — skip it
          changes.append(
            InlineCommentChange(
              file: file, line: lineNumber, before: line, after: "",
            ))
          continue
        } else {
          outputLines.append(beforeComment)
          changes.append(
            InlineCommentChange(
              file: file, line: lineNumber, before: line, after: beforeComment,
            ))
          continue
        }
      }

      // Reconstruct the comment
      var newComment = "// sm:\(smAction) \(mappedIDs.joined(separator: " "))"
      if let trailing = trailingComment {
        newComment += " - \(trailing)"
      }

      // Replace in the line
      let prefix = String(line[line.startIndex..<match.output.0.startIndex])
      let newLine = prefix + newComment
      outputLines.append(newLine)

      if newLine != line {
        changes.append(
          InlineCommentChange(
            file: file, line: lineNumber, before: line, after: newLine,
          ))
      }
    }

    return (outputLines.joined(separator: "\n"), changes, warnings)
  }

  /// Parse rule IDs and optional trailing comment from the rest of the comment
  ///
  /// SwiftLint format: `rule1 rule2 - Optional comment`
  private static func parseRuleIDsAndComment(
    _ text: String,
  ) -> (ruleIDs: [String], trailingComment: String?) {
    let parts = text.components(separatedBy: " - ")
    let ruleText: String
    let trailingComment: String?

    if parts.count > 1 {
      ruleText = parts[0]
      trailingComment = parts.dropFirst().joined(separator: " - ")
    } else {
      ruleText = text
      trailingComment = nil
    }

    let ruleIDs = ruleText.split(separator: " ")
      .map { $0.trimmingCharacters(in: .whitespaces) }
      .filter { !$0.isEmpty }

    return (ruleIDs, trailingComment)
  }
}
