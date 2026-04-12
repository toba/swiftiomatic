import Foundation

/// Generates unified diffs between original and modified file content.
public enum UnifiedDiff {
  /// A single file's diff result for JSON output.
  public struct FileDiff: Codable, Sendable {
    public let file: String
    public let diff: String

    public init(file: String, diff: String) {
      self.file = file
      self.diff = diff
    }
  }

  private enum EditOp {
    case keep(String)
    case remove(String)
    case insert(String)

    var isChange: Bool {
      switch self {
      case .keep: false
      case .remove, .insert: true
      }
    }
  }

  /// Generate a unified diff between original and modified content.
  /// Returns `nil` if the contents are identical.
  public static func generate(
    original: String,
    modified: String,
    filePath: String,
    contextLines: Int = 3
  ) -> String? {
    guard original != modified else { return nil }

    let oldLines = original.split(separator: "\n", omittingEmptySubsequences: false)
      .map(String.init)
    let newLines = modified.split(separator: "\n", omittingEmptySubsequences: false)
      .map(String.init)

    let ops = editScript(from: oldLines, to: newLines)
    guard ops.contains(where: \.isChange) else { return nil }

    let hunks = formatHunks(ops: ops, contextLines: contextLines)
    guard !hunks.isEmpty else { return nil }

    return "--- a/\(filePath)\n+++ b/\(filePath)\n" + hunks.joined()
  }

  /// Encode an array of file diffs as pretty-printed JSON.
  public static func formatJSON(_ diffs: [FileDiff]) throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(diffs)
    return String(data: data, encoding: .utf8) ?? "[]"
  }

  // MARK: - Private

  private static func editScript(from old: [String], to new: [String]) -> [EditOp] {
    let diff = new.difference(from: old)
    guard !diff.isEmpty else { return old.map { .keep($0) } }

    var removedFromOld = Set<Int>()
    var insertedInNew = Set<Int>()

    for change in diff {
      switch change {
      case .remove(let offset, _, _):
        removedFromOld.insert(offset)
      case .insert(let offset, _, _):
        insertedInNew.insert(offset)
      }
    }

    var ops: [EditOp] = []
    var oi = 0
    var ni = 0

    while oi < old.count || ni < new.count {
      if oi < old.count, removedFromOld.contains(oi) {
        ops.append(.remove(old[oi]))
        oi += 1
      } else if ni < new.count, insertedInNew.contains(ni) {
        ops.append(.insert(new[ni]))
        ni += 1
      } else if oi < old.count, ni < new.count {
        ops.append(.keep(old[oi]))
        oi += 1
        ni += 1
      } else if oi < old.count {
        ops.append(.remove(old[oi]))
        oi += 1
      } else {
        ops.append(.insert(new[ni]))
        ni += 1
      }
    }

    return ops
  }

  private static func formatHunks(ops: [EditOp], contextLines: Int) -> [String] {
    let changeIndices = ops.indices.filter { ops[$0].isChange }
    guard let first = changeIndices.first else { return [] }

    // Group into hunk ranges with context
    var ranges: [(start: Int, end: Int)] = []
    var start = max(0, first - contextLines)
    var end = min(ops.count - 1, first + contextLines)

    for i in 1..<changeIndices.count {
      let nextStart = max(0, changeIndices[i] - contextLines)
      if nextStart <= end + 1 {
        end = min(ops.count - 1, changeIndices[i] + contextLines)
      } else {
        ranges.append((start, end))
        start = nextStart
        end = min(ops.count - 1, changeIndices[i] + contextLines)
      }
    }
    ranges.append((start, end))

    return ranges.map { range in
      // Compute starting line numbers by counting ops before this range
      var oldLine = 1
      var newLine = 1
      for i in 0..<range.start {
        switch ops[i] {
        case .keep: oldLine += 1; newLine += 1
        case .remove: oldLine += 1
        case .insert: newLine += 1
        }
      }

      var oldCount = 0
      var newCount = 0
      var body = ""

      for i in range.start...range.end {
        switch ops[i] {
        case .keep(let line):
          body += " \(line)\n"
          oldCount += 1
          newCount += 1
        case .remove(let line):
          body += "-\(line)\n"
          oldCount += 1
        case .insert(let line):
          body += "+\(line)\n"
          newCount += 1
        }
      }

      return "@@ -\(oldLine),\(oldCount) +\(newLine),\(newCount) @@\n\(body)"
    }
  }
}
