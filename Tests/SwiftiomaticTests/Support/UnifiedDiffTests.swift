import Foundation
import Testing

@testable import SwiftiomaticKit

@Suite struct UnifiedDiffTests {
  @Test func identicalContentReturnsNil() {
    let content = "line 1\nline 2\nline 3\n"
    let result = UnifiedDiff.generate(
      original: content, modified: content, filePath: "test.swift"
    )
    #expect(result == nil)
  }

  @Test func singleLineChange() throws {
    let original = "func foo() {\n  let x = 1\n}\n"
    let modified = "func foo() {\n  let x = 2\n}\n"
    let diff = UnifiedDiff.generate(
      original: original, modified: modified, filePath: "test.swift"
    )

    let result = try #require(diff)
    #expect(result.contains("--- a/test.swift"))
    #expect(result.contains("+++ b/test.swift"))
    #expect(result.contains("-  let x = 1"))
    #expect(result.contains("+  let x = 2"))
  }

  @Test func insertedLines() throws {
    let original = "line 1\nline 3\n"
    let modified = "line 1\nline 2\nline 3\n"
    let diff = UnifiedDiff.generate(
      original: original, modified: modified, filePath: "test.swift"
    )

    let result = try #require(diff)
    #expect(result.contains("+line 2"))
    #expect(!result.contains("-line"))
  }

  @Test func removedLines() throws {
    let original = "line 1\nline 2\nline 3\n"
    let modified = "line 1\nline 3\n"
    let diff = UnifiedDiff.generate(
      original: original, modified: modified, filePath: "test.swift"
    )

    let result = try #require(diff)
    #expect(result.contains("-line 2"))
    #expect(!result.contains("+line"))
  }

  @Test func hunkHeaderShowsCorrectLineNumbers() throws {
    let original = "a\nb\nc\n"
    let modified = "a\nB\nc\n"
    let diff = UnifiedDiff.generate(
      original: original, modified: modified, filePath: "test.swift"
    )

    let result = try #require(diff)
    // 4 lines including trailing empty from split; change at line 2 with 3-line context covers all
    #expect(result.contains("@@ -1,4 +1,4 @@"))
  }

  @Test func multipleHunksForDistantChanges() throws {
    // Create content with changes far apart (more than 2*contextLines apart)
    let oldLines = (1...20).map { "line \($0)" }
    var newLines = oldLines
    newLines[1] = "CHANGED 2"  // line 2
    newLines[18] = "CHANGED 19"  // line 19

    let original = oldLines.joined(separator: "\n") + "\n"
    let modified = newLines.joined(separator: "\n") + "\n"
    let diff = UnifiedDiff.generate(
      original: original, modified: modified, filePath: "test.swift"
    )

    let result = try #require(diff)
    // Should have two separate @@ hunks
    let hunkCount = result.components(separatedBy: "@@").count
    // Each hunk has opening @@...@@, so for 2 hunks: "@@...@@\n...@@...@@\n..." = 5 parts
    #expect(hunkCount >= 5)
  }

  @Test func contextLinesAroundChanges() throws {
    let original = "1\n2\n3\n4\n5\n6\n7\n8\n9\n10\n"
    let modified = "1\n2\n3\n4\nFIVE\n6\n7\n8\n9\n10\n"
    let diff = UnifiedDiff.generate(
      original: original, modified: modified, filePath: "test.swift",
      contextLines: 2
    )

    let result = try #require(diff)
    // With contextLines=2, should show lines 3-7 (2 before change, 2 after)
    #expect(result.contains(" 3"))
    #expect(result.contains(" 4"))
    #expect(result.contains("-5"))
    #expect(result.contains("+FIVE"))
    #expect(result.contains(" 6"))
    #expect(result.contains(" 7"))
    // Line 1 should NOT be in the output (too far from change)
    #expect(!result.contains(" 1\n"))
  }

  @Test func jsonEncodingRoundTrips() throws {
    let diffs = [
      UnifiedDiff.FileDiff(file: "a.swift", diff: "--- a/a.swift\n+++ b/a.swift\n"),
      UnifiedDiff.FileDiff(file: "b.swift", diff: "--- a/b.swift\n+++ b/b.swift\n"),
    ]
    let json = try UnifiedDiff.formatJSON(diffs)
    let data = try #require(json.data(using: .utf8))
    let decoded = try JSONDecoder().decode([UnifiedDiff.FileDiff].self, from: data)

    #expect(decoded.count == 2)
    #expect(decoded[0].file == "a.swift")
    #expect(decoded[1].file == "b.swift")
  }

  @Test func emptyFileToContent() throws {
    let diff = UnifiedDiff.generate(
      original: "", modified: "new content\n", filePath: "test.swift"
    )

    let result = try #require(diff)
    #expect(result.contains("+new content"))
  }

  @Test func contentToEmptyFile() throws {
    let diff = UnifiedDiff.generate(
      original: "old content\n", modified: "", filePath: "test.swift"
    )

    let result = try #require(diff)
    #expect(result.contains("-old content"))
  }
}
