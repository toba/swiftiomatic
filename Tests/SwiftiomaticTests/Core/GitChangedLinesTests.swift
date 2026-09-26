import Testing
import Foundation
import Synchronization
@testable import SwiftiomaticKit

@Suite struct GitChangedLinesTests {
    // MARK: - Hunk header parser

    @Test func hunkWithCountsGivesNewSideRange() {
        let diff = """
            diff --git a/A.swift b/A.swift
            index 1111111..2222222 100644
            --- a/A.swift
            +++ b/A.swift
            @@ -3,2 +3,4 @@ struct A {
            -old
            -old
            +new
            +new
            +new
            +new
            """
        #expect(DiffHunks.newSideRanges(fromUnifiedDiff: diff) == [3...6])
    }

    @Test func missingCountMeansOneLine() {
        let diff = """
            @@ -7 +7 @@
            -a
            +b
            @@ -10,0 +11 @@ func f() {
            +c
            """
        #expect(DiffHunks.newSideRanges(fromUnifiedDiff: diff) == [7...7, 11...11])
    }

    @Test func pureDeletionGivesNoRange() {
        let diff = """
            @@ -4,3 +3,0 @@
            -a
            -b
            -c
            @@ -20,1 +18,2 @@
            -d
            +e
            +f
            """
        #expect(DiffHunks.newSideRanges(fromUnifiedDiff: diff) == [18...19])
    }

    @Test func newFileGivesWholeRange() {
        let diff = """
            diff --git a/N.swift b/N.swift
            new file mode 100644
            --- /dev/null
            +++ b/N.swift
            @@ -0,0 +1,12 @@
            +line
            """
        #expect(DiffHunks.newSideRanges(fromUnifiedDiff: diff) == [1...12])
    }

    @Test func emptyDiffAndContentLinesGiveNoRange() {
        #expect(DiffHunks.newSideRanges(fromUnifiedDiff: "").isEmpty)
        // A content line that looks like a header does not start with "@@ ".
        #expect(DiffHunks.newSideRanges(fromUnifiedDiff: "+@@ -1 +1,5 @@\n\\ No newline").isEmpty)
    }

    // MARK: - Per-file plumbing

    /// A fake git that records each call and answers from a table.
    final class FakeGit: Sendable {
        let calls = Mutex<[[String]]>([])
        let answer: @Sendable ([String]) -> GitChangedLines.CommandResult

        init(_ answer: @escaping @Sendable ([String]) -> GitChangedLines.CommandResult) {
            self.answer = answer
        }

        func run(_ arguments: [String]) -> GitChangedLines.CommandResult {
            calls.withLock { $0.append(arguments) }
            return answer(arguments)
        }
    }

    @Test func trackedFileUsesDiffHunksFromItsDirectory() throws {
        let git = FakeGit { arguments in
            arguments.contains("diff")
                ? .init(status: 0, output: "@@ -1 +1,2 @@\n+a\n+b\n@@ -9,0 +10 @@\n+c\n")
                : .init(status: 0, output: "")
        }
        let changes = GitChangedLines(ref: "main", runner: git.run)

        #expect(
            try changes.changedLines(forFile: "/repo/Sources/A.swift").get() == [1...2, 10...10])
        let first = try #require(git.calls.withLock { $0.first })
        #expect(
            first == [
                "-C", "/repo/Sources", "diff", "-U0", "--no-color", "--no-ext-diff", "main", "--",
                "A.swift",
            ])
    }

    @Test func fileWithoutDiffHasNoRanges() throws {
        let git = FakeGit { _ in .init(status: 0, output: "") }
        let changes = GitChangedLines(ref: "HEAD", runner: git.run)

        #expect(try changes.changedLines(forFile: "/repo/B.swift").get().isEmpty)
        #expect(
            try ChangeStatus(
                line: 3, changedLines: changes.changedLines(forFile: "/repo/B.swift").get())
                == .existing)
    }

    @Test func untrackedFileIsFullyChanged() throws {
        let git = FakeGit { arguments in
            arguments.contains("ls-files")
                ? .init(status: 1, output: "error: pathspec did not match")
                : .init(status: 0, output: "")
        }
        let changes = GitChangedLines(ref: "HEAD", runner: git.run)
        let ranges = try changes.changedLines(forFile: "/repo/New.swift").get()

        #expect(ranges == GitChangedLines.wholeFile)
        #expect(ChangeStatus(line: 400, changedLines: ranges) == .introduced)
    }

    @Test func gitFailureIsAnError() {
        let git = FakeGit { _ in .init(status: 128, output: "fatal: bad revision 'nope'") }
        let changes = GitChangedLines(ref: "nope", runner: git.run)

        #expect(throws: GitChangedLines.Failure.self) {
            try changes.changedLines(forFile: "/repo/C.swift").get()
        }
    }

    @Test func resultsAreCachedPerFile() throws {
        let git = FakeGit { _ in .init(status: 0, output: "@@ -1 +1 @@\n") }
        let changes = GitChangedLines(ref: "HEAD", runner: git.run)

        _ = changes.changedLines(forFile: "/repo/D.swift")
        _ = changes.changedLines(forFile: "/repo/D.swift")
        #expect(git.calls.withLock { $0.count } == 1)
    }

    @Test func relativePathResolvesAgainstWorkingDirectory() throws {
        let git = FakeGit { _ in .init(status: 0, output: "") }
        let changes = GitChangedLines(ref: "HEAD", runner: git.run)
        _ = changes.changedLines(forFile: "Sources/E.swift")

        let expectedDirectory = URL(fileURLWithPath: "Sources/E.swift").deletingLastPathComponent()
            .path
        let first = try #require(git.calls.withLock { $0.first })
        #expect(first[1] == expectedDirectory)
        #expect(first.last == "E.swift")
    }
}
