import Foundation
import Synchronization

private let outputLock = Mutex(())

/// A thread-safe version of Swift's standard `print()`.
///
/// - parameter object: Object to print.
func queuedPrint(_ object: some Sendable) {
    outputLock.withLock { _ in
        print(object)
    }
}

/// A thread-safe, newline-terminated version of `fputs(..., stderr)`.
///
/// - parameter string: String to print.
func queuedPrintError(_ string: String) {
    outputLock.withLock { _ in
        fflush(stdout)
        fputs(string + "\n", stderr)
    }
}

/// A thread-safe, newline-terminated version of `fatalError(...)` that doesn't leak
/// the source path from the compiled binary.
func queuedFatalError(_ string: String, file: StaticString = #file, line: UInt = #line) -> Never {
    outputLock.withLock { _ in
        fflush(stdout)
        let file = URL(filePath: "\(file)").lastPathComponent
        fputs("\(string): file \(file), line \(line)\n", stderr)
    }

    abort()
}
