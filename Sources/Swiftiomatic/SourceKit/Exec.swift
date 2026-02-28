import Foundation

/// Namespace for utilities to execute a child process.
enum Exec {
    enum Stderr {
        case inherit
        case discard
        case merge
    }

    struct Results {
        let terminationStatus: Int32
        let data: Data
        var string: String? {
            let encoded = String(data: data, encoding: .utf8) ?? ""
            let trimmed = encoded.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
    }

    static func run(
        _ command: String,
        _ arguments: String...,
        currentDirectory: String = FileManager.default.currentDirectoryPath,
        stderr: Stderr = .inherit,
    ) -> Results {
        run(command, arguments, currentDirectory: currentDirectory, stderr: stderr)
    }

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
