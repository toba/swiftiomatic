import Foundation
import ArgumentParser
import SwiftiomaticKit

extension SwiftiomaticCommand {
    struct Link: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Symlink sm into Xcode's toolchain as swift-format",
            discussion: """
                Replaces Xcode's bundled swift-format binary with a symlink to the installed \
                sm binary (/opt/homebrew/bin/sm) so Xcode's "Format with swift-format" menu \
                item and SPM format/lint plugins use Swiftiomatic. Every Xcode found in \
                /Applications and ~/Applications is linked, including a beta installed beside \
                the release. Requires sudo because the target lives inside Xcode.app. Re-run \
                after Xcode updates.
                """
        )

        @Option(name: .long, help: "Path to the sm binary to link from.")
        var source = "/opt/homebrew/bin/sm"

        @Option(
            name: .long,
            help: """
                Path to install the symlink at. Repeat to link several paths. \
                Replaces the search of /Applications and ~/Applications.
                """
        )
        var target: [String] = []

        @Flag(name: .long, help: "Link the release Xcode only and leave every beta alone.")
        var skipBeta = false

        func run() throws {
            let fm = FileManager.default

            guard fm.isExecutableFile(atPath: source) else {
                printError("source binary not found or not executable: \(source)")
                throw ExitCode.failure
            }

            let targets = target.isEmpty ? try discoveredTargets() : target
            var failures = 0

            for target in targets {
                if linkTarget(target) {
                    print("Linked \(target) → \(source)")
                } else {
                    failures += 1
                }
            }

            guard failures == 0 else { throw ExitCode.failure }
        }

        private func discoveredTargets() throws -> [String] {
            let toolchains = XcodeInstallation.discover()
                .filter { !skipBeta || !$0.isBeta }

            guard !toolchains.isEmpty else {
                printError(
                    "no Xcode installation found in /Applications or ~/Applications — "
                        + "pass --target <path> to link one directly"
                )
                throw ExitCode.failure
            }
            return toolchains.map(\.swiftFormatURL.path)
        }

        /// Write one symlink and report whether it landed
        private func linkTarget(_ target: String) -> Bool {
            let process = Process()
            process.executableURL = URL(filePath: "/bin/ln")
            process.arguments = ["-sf", source, target]

            do {
                try process.run()
            } catch {
                printError("failed to run /bin/ln for \(target): \(error.localizedDescription)")
                return false
            }
            process.waitUntilExit()

            guard process.terminationStatus == 0 else {
                if geteuid() != 0 {
                    printError("failed to write \(target) — re-run with: sudo sm link")
                } else {
                    printError("ln exited with status \(process.terminationStatus) for \(target)")
                }
                return false
            }
            return true
        }

        private func printError(_ message: String) {
            FileHandle.standardError.write(Data("error: \(message)\n".utf8))
        }
    }
}
