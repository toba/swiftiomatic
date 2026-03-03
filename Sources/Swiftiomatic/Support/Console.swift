import Foundation
import Synchronization

private let outputLock = Mutex(())

/// Thread-safe console output utilities
public enum Console {
    /// A thread-safe version of Swift's standard `print()`
    ///
    /// - Parameters:
    ///   - object: Object to print.
    static func print(_ object: some Sendable) {
        outputLock.withLock { _ in
            Swift.print(object)
        }
    }

    /// A thread-safe, newline-terminated version of `fputs(..., stderr)`
    ///
    /// - Parameters:
    ///   - string: String to print.
    static func printError(_ string: String) {
        outputLock.withLock { _ in
            fflush(stdout)
            fputs(string + "\n", stderr)
        }
    }

    // MARK: - Test Capture

    /// Continuation for the active capture stream, set via ``captureConsole(runner:)``
    @TaskLocal public static var captureContinuation: AsyncStream<String>.Continuation?

    /// Captures all messages normally printed to stdout and returns them to the caller
    ///
    /// > Warning: Shall only be used in tests to verify console output.
    ///
    /// - Parameters:
    ///   - runner: The code to run. Messages printed during the execution are collected.
    /// - Returns: The collected messages produced while running the code in the runner.
    @MainActor
    public static func captureConsole(runner: @Sendable () throws -> Void) async rethrows
        -> String
    {
        let (stream, continuation) = AsyncStream.makeStream(of: String.self)
        try $captureContinuation.withValue(continuation, operation: runner)
        continuation.finish()
        return await stream.reduce(into: "") { @Sendable in $0 += $0.isEmpty ? $1 : "\n\($1)" }
    }

    /// A thread-safe `fatalError` replacement that strips the source path from the compiled binary
    ///
    /// - Parameters:
    ///   - string: The error message to print to stderr.
    ///   - file: The source file path (defaults to the caller's file).
    ///   - line: The source line number (defaults to the caller's line).
    static func fatalError(_ string: String, file: StaticString = #file,
                           line: UInt = #line) -> Never
    {
        outputLock.withLock { _ in
            fflush(stdout)
            let file = URL(filePath: "\(file)").lastPathComponent
            fputs("\(string): file \(file), line \(line)\n", stderr)
        }

        abort()
    }
}
