import Foundation
import Synchronization

private let outputLock = Mutex(())

/// Thread-safe console output utilities.
package enum Console {
    /// A thread-safe version of Swift's standard `print()`.
    ///
    /// - parameter object: Object to print.
    static func print(_ object: some Sendable) {
        outputLock.withLock { _ in
            Swift.print(object)
        }
    }

    /// A thread-safe, newline-terminated version of `fputs(..., stderr)`.
    ///
    /// - parameter string: String to print.
    static func printError(_ string: String) {
        outputLock.withLock { _ in
            fflush(stdout)
            fputs(string + "\n", stderr)
        }
    }

    // MARK: - Test Capture

    @TaskLocal package static var captureContinuation: AsyncStream<String>.Continuation?

    /// Hook used to capture all messages normally printed to stdout and return them back to the caller.
    ///
    /// > Warning: Shall only be used in tests to verify console output.
    ///
    /// - parameter runner: The code to run. Messages printed during the execution are collected.
    ///
    /// - returns: The collected messages produced while running the code in the runner.
    @MainActor
    package static func captureConsole(runner: @Sendable () throws -> Void) async rethrows -> String {
        let (stream, continuation) = AsyncStream.makeStream(of: String.self)
        try $captureContinuation.withValue(continuation, operation: runner)
        continuation.finish()
        return await stream.reduce(into: "") { @Sendable in $0 += $0.isEmpty ? $1 : "\n\($1)" }
    }

    /// A thread-safe, newline-terminated version of `fatalError(...)` that doesn't leak
    /// the source path from the compiled binary.
    static func fatalError(_ string: String, file: StaticString = #file, line: UInt = #line) -> Never {
        outputLock.withLock { _ in
            fflush(stdout)
            let file = URL(filePath: "\(file)").lastPathComponent
            fputs("\(string): file \(file), line \(line)\n", stderr)
        }

        abort()
    }
}
