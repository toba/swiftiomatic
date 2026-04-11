import Foundation

/// Namespace for synchronous child-process execution utilities
enum Exec {
  /// How to handle the child process's standard error stream
  enum Stderr {
    /// Inherit the parent's stderr (default)
    case inherit
    /// Redirect stderr to `/dev/null`
    case discard
    /// Merge stderr into stdout
    case merge
  }

  /// The captured output and exit status of a completed child process
  struct Results {
    /// The process termination status, or `-1` if the process failed to launch
    let terminationStatus: Int32
    /// The raw bytes captured from stdout (and stderr when ``Stderr/merge`` is used)
    let data: Data
    /// The UTF-8 decoded, whitespace-trimmed output, or `nil` if empty
    var string: String? {
      let encoded = String(data: data, encoding: .utf8) ?? ""
      let trimmed = encoded.trimmingCharacters(in: .whitespacesAndNewlines)
      return trimmed.isEmpty ? nil : trimmed
    }
  }

  /// Execute a command with variadic arguments
  ///
  /// - Parameters:
  ///   - command: The absolute path to the executable.
  ///   - arguments: The command-line arguments.
  ///   - currentDirectory: The working directory for the child process.
  ///   - stderr: How to handle the child's stderr stream.
  static func run(
    _ command: String,
    _ arguments: String...,
    currentDirectory: String = FileManager.default.currentDirectoryPath,
    stderr: Stderr = .inherit,
  ) -> Results {
    run(command, arguments, currentDirectory: currentDirectory, stderr: stderr)
  }

  /// Execute a command with an array of arguments
  ///
  /// - Parameters:
  ///   - command: The absolute path to the executable.
  ///   - arguments: The command-line arguments.
  ///   - currentDirectory: The working directory for the child process.
  ///   - stderr: How to handle the child's stderr stream.
  static func run(
    _ command: String,
    _ arguments: [String] = [],
    currentDirectory: String = FileManager.default.currentDirectoryPath,
    stderr: Stderr = .inherit,
  ) -> Results {
    let process = Process()
    process.arguments = arguments

    let pipe = Pipe()
    process.standardOutput = pipe

    switch stderr {
    case .discard:
      process.standardError = FileHandle(forWritingAtPath: "/dev/null")!
    case .merge:
      process.standardError = pipe
    case .inherit:
      break
    }

    do {
      process.executableURL = URL(fileURLWithPath: command)
      process.currentDirectoryURL = URL(fileURLWithPath: currentDirectory)
      try process.run()
    } catch {
      return Results(terminationStatus: -1, data: Data())
    }

    let file = pipe.fileHandleForReading
    let data = file.readDataToEndOfFile()
    process.waitUntilExit()
    return Results(terminationStatus: process.terminationStatus, data: data)
  }
}
