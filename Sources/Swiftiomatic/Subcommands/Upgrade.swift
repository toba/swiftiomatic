import Foundation
import ArgumentParser

extension SwiftiomaticCommand {
    struct Upgrade: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Upgrade sm via Homebrew",
            discussion: """
                Runs 'brew update' (so fresh releases are visible) followed by 'brew upgrade sm'. \
                After upgrading, checks whether Xcode's toolchain symlink still points at the \
                Homebrew sm binary; if not, suggests re-running 'sudo sm link'.
                """
        )

        @Flag(name: .long, inversion: .prefixedNo, help: "Run 'brew update' before upgrading.")
        var update: Bool = true

        @Option(name: .long, help: "Path to the brew binary.")
        var brew = "/opt/homebrew/bin/brew"

        @Option(name: .long, help: "Path to the installed sm symlink to inspect for version changes.")
        var smPath = "/opt/homebrew/bin/sm"

        func run() throws {
            let fm = FileManager.default

            guard fm.isExecutableFile(atPath: brew) else {
                printError("brew not found at \(brew) — sm upgrade only supports Homebrew installs")
                throw ExitCode.failure
            }

            let beforeVersion = resolveCellarVersion(for: smPath)

            if update {
                print("Running: brew update")
                let status = try runStreaming(brew, ["update"])
                guard status == 0 else {
                    printError("brew update exited with status \(status)")
                    throw ExitCode(status)
                }
            }

            print("Running: brew upgrade sm")
            let upgradeStatus = try runStreaming(brew, ["upgrade", "sm"])
            // brew upgrade exits non-zero in some "already up-to-date" paths historically; tolerate
            // by checking whether the version actually changed below. But surface real errors.
            if upgradeStatus != 0 {
                // Print but don't bail yet — fall through to version check.
                printError("brew upgrade sm exited with status \(upgradeStatus)")
            }

            let afterVersion = resolveCellarVersion(for: smPath)

            switch (beforeVersion, afterVersion) {
            case let (.some(before), .some(after)) where before == after:
                print("\nsm is already at the latest version (\(after)).")
            case let (.some(before), .some(after)):
                print("\nUpgraded sm: \(before) → \(after)")
            case let (_, .some(after)):
                print("\nsm version: \(after)")
            default:
                print("\nUnable to determine installed sm version from \(smPath)")
            }

            checkToolchainLink()

            if upgradeStatus != 0 && beforeVersion == afterVersion {
                throw ExitCode(upgradeStatus)
            }
        }

        // MARK: - Helpers

        /// Reads the symlink chain for `path` and extracts the Cellar version segment, if any.
        /// e.g. /opt/homebrew/bin/sm -> ../Cellar/sm/0.26.11/bin/sm  =>  "0.26.11"
        private func resolveCellarVersion(for path: String) -> String? {
            let resolved = URL(fileURLWithPath: path).resolvingSymlinksInPath().path
            let components = resolved.split(separator: "/", omittingEmptySubsequences: true).map(String.init)
            guard let cellarIdx = components.firstIndex(of: "Cellar"),
                  cellarIdx + 2 < components.count,
                  components[cellarIdx + 1] == "sm"
            else { return nil }
            return components[cellarIdx + 2]
        }

        @discardableResult
        private func runStreaming(_ executable: String, _ arguments: [String]) throws -> Int32 {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = arguments
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus
        }

        /// Captures stdout from a short-lived command. Returns nil if the command fails to run
        /// or exits non-zero.
        private func runCapturing(_ executable: String, _ arguments: [String]) -> String? {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = arguments
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = Pipe()
            do {
                try process.run()
            } catch {
                return nil
            }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { return nil }
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        /// Checks `xcrun --find swift-format` and warns if the resolved binary isn't the Homebrew sm.
        private func checkToolchainLink() {
            guard let xcrunPath = runCapturing("/usr/bin/xcrun", ["--find", "swift-format"]) else {
                print("\nNote: 'xcrun --find swift-format' did not resolve. Run 'sudo sm link' to install the Xcode toolchain symlink.")
                return
            }
            let resolved = URL(fileURLWithPath: xcrunPath).resolvingSymlinksInPath().path
            let expected = URL(fileURLWithPath: smPath).resolvingSymlinksInPath().path
            if resolved == expected {
                print("Xcode toolchain symlink: OK (swift-format → \(smPath))")
            } else {
                print("""

                    Xcode's swift-format does NOT point at sm:
                      xcrun --find swift-format → \(xcrunPath)
                      resolves to              → \(resolved)
                      expected                 → \(expected)
                    Re-run: sudo sm link
                    """)
            }
        }

        private func printError(_ message: String) {
            FileHandle.standardError.write(Data("error: \(message)\n".utf8))
        }
    }
}
