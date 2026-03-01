import Foundation

/// Partially filters compiler arguments from `xcodebuild` to something that SourceKit/Clang will accept
///
/// - Parameters:
///   - args: Compiler arguments, as parsed from `xcodebuild`.
///
/// - Returns: A tuple of partially filtered compiler arguments in `.0`, and whether or not there are
///   more flags to remove in `.1`.
private func partiallyFilter(arguments args: [String]) -> ([String], Bool) {
    guard let indexOfFlagToRemove = args.firstIndex(of: "-output-file-map") else {
        return (args, false)
    }
    var args = args
    args.remove(at: args.index(after: indexOfFlagToRemove))
    args.remove(at: indexOfFlagToRemove)
    return (args, true)
}

extension [String] {
    /// Compiler arguments filtered for SourceKit/Clang compatibility
    ///
    /// Strips the leading `swiftc` invocation, removes unsupported flags like
    /// `-output-file-map` and `-parseable-output`, unescapes shell metacharacters,
    /// and forces debug mode (`-Onone`, `-DDEBUG=1`).
    var filteringCompilerArguments: [String] {
        var args = self
        if args.first == "swiftc" {
            args.removeFirst()
        }

        // https://github.com/realm/SwiftLint/issues/3365
        args = args.map { $0.replacingOccurrences(of: "\\=", with: "=") }
        args = args.map { $0.replacingOccurrences(of: "\\ ", with: " ") }
        args.append(contentsOf: ["-D", "DEBUG"])
        var shouldContinueToFilterArguments = true
        while shouldContinueToFilterArguments {
            (args, shouldContinueToFilterArguments) = partiallyFilter(arguments: args)
        }

        return args.filter { arg in
            ![
                "-parseable-output",
                "-incremental",
                "-serialize-diagnostics",
                "-emit-dependencies",
                "-use-frontend-parseable-output",
            ].contains(arg)
        }.map { arg in
            if arg == "-O" {
                return "-Onone"
            }
            if arg == "-DNDEBUG=1" {
                return "-DDEBUG=1"
            }
            return arg
        }
    }
}
