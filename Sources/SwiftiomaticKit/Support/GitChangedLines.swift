import Foundation
import Synchronization

/// Reads the changed lines out of a unified diff.
public enum DiffHunks {
    /// Returns the new-side line ranges of each hunk header in a unified diff.
    ///
    /// A hunk header has the form `@@ -a,b +c,d @@`. The new side starts at line `c` and has `d`
    /// lines. When `,d` is missing, the count is 1. When `d` is 0, the hunk is a pure deletion and
    /// gives no range. The function ignores all lines that do not start with `@@ `.
    ///
    /// - Parameter diff: The output of `git diff`, typically with `-U0`.
    /// - Returns: The 1-based new-side line ranges, in diff order.
    public static func newSideRanges(fromUnifiedDiff diff: String) -> [ClosedRange<Int>] {
        var ranges: [ClosedRange<Int>] = []

        for line in diff.split(separator: "\n", omittingEmptySubsequences: true) {
            guard line.hasPrefix("@@ "),
                  let plus = line.split(separator: " ").dropFirst().first(where: {
                      $0.hasPrefix("+")
                  }) else { continue }

            let parts = plus.dropFirst().split(separator: ",", maxSplits: 1)
            guard let start = parts.first.flatMap({ Int($0) }) else { continue }
            let count = parts.count > 1 ? Int(parts[1]) ?? 0 : 1
            guard count > 0, start > 0 else { continue }

            ranges.append(start...(start + count - 1))
        }
        return ranges
    }
}

/// Finds the lines of each file that changed since a git reference.
///
/// For each file, the type runs `git -C <dir> diff -U0 <ref> -- <file>` and reads the hunk headers.
/// An untracked file counts as fully changed. The type keeps the result for each file, so git runs
/// one time per file.
public final class GitChangedLines: Sendable {
    /// The exit status and the combined output of one git command.
    public struct CommandResult: Sendable {
        public var status: Int32
        public var output: String

        public init(status: Int32, output: String) {
            self.status = status
            self.output = output
        }
    }

    /// A git command failed, so the changed lines of a file are not known.
    public struct Failure: Error, Sendable, CustomStringConvertible {
        /// The file whose changed lines are not known.
        public var file: String

        /// The output of git.
        public var message: String

        public var description: String { "Unable to find the changed lines of \(file): \(message)" }
    }

    /// Runs git with the given arguments. The arguments do not include `git` itself.
    public typealias Runner = @Sendable ([String]) -> CommandResult

    /// The range that marks every line of a file as changed.
    public static let wholeFile: [ClosedRange<Int>] = [1...Int.max]

    /// The git reference to compare against.
    public let ref: String

    private let runner: Runner
    private let results = Mutex<[String: Result<[ClosedRange<Int>], Failure>]>([:])

    /// Creates a changed-line finder for a git reference.
    ///
    /// - Parameters:
    ///   - ref: The git reference, such as `main` or `HEAD~3`.
    ///   - runner: The function that runs git. The default runs `/usr/bin/env git`.
    public init(ref: String, runner: @escaping Runner = GitChangedLines.runGit) {
        self.ref = ref
        self.runner = runner
    }

    /// Returns the changed 1-based line ranges of a file.
    ///
    /// An empty array means that the file did not change. A relative path resolves against the
    /// current working directory.
    public func changedLines(forFile path: String) -> Result<[ClosedRange<Int>], Failure> {
        if let known = results.withLock({ $0[path] }) { return known }

        let result = compute(path)
        results.withLock { $0[path] = result }
        return result
    }

    private func compute(_ path: String) -> Result<[ClosedRange<Int>], Failure> {
        let url = URL(fileURLWithPath: path)
        let directory = url.deletingLastPathComponent().path
        let name = url.lastPathComponent

        let diff = runner([
            "-C", directory, "diff", "-U0", "--no-color", "--no-ext-diff", ref, "--", name,
        ])
        guard diff.status == 0 else {
            return .failure(Failure(file: path, message: diff.output.trimmed))
        }

        let ranges = DiffHunks.newSideRanges(fromUnifiedDiff: diff.output)
        guard ranges.isEmpty, diff.output.trimmed.isEmpty else { return .success(ranges) }

        // An empty diff means that the file did not change, or that git does not track it.
        let tracked = runner(["-C", directory, "ls-files", "--error-unmatch", "--", name])
        return .success(tracked.status == 0 ? [] : Self.wholeFile)
    }

    /// Runs `git` from the search path and returns its exit status and combined output.
    public static func runGit(_ arguments: [String]) -> CommandResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["git"] + arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
        } catch {
            return CommandResult(status: -1, output: "\(error)")
        }
        // Read before the wait, so a large diff does not fill the pipe and block git.
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return .init(
            status: process.terminationStatus,
            output: String(decoding: data, as: UTF8.self)
        )
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
