import ArgumentParser
import Foundation

extension SwiftiomaticCommand {
  struct Link: ParsableCommand {
    static let configuration = CommandConfiguration(
      abstract: "Symlink sm into Xcode's toolchain as swift-format",
      discussion: """
        Replaces Xcode's bundled swift-format binary with a symlink to the installed \
        sm binary (/opt/homebrew/bin/sm) so Xcode's "Format with swift-format" menu \
        item and SPM format/lint plugins use Swiftiomatic. Requires sudo because the \
        target lives inside Xcode.app. Re-run after Xcode updates.
        """
    )

    @Option(name: .long, help: "Path to the sm binary to link from.")
    var source: String = "/opt/homebrew/bin/sm"

    @Option(name: .long, help: "Path to install the symlink at.")
    var target: String = "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift-format"

    func run() throws {
      let fm = FileManager.default

      guard fm.isExecutableFile(atPath: source) else {
        printError("source binary not found or not executable: \(source)")
        throw ExitCode.failure
      }

      let process = Process()
      process.executableURL = URL(fileURLWithPath: "/bin/ln")
      process.arguments = ["-sf", source, target]

      try process.run()
      process.waitUntilExit()

      guard process.terminationStatus == 0 else {
        if geteuid() != 0 {
          printError("failed to write symlink — re-run with: sudo sm link")
        } else {
          printError("ln exited with status \(process.terminationStatus)")
        }
        throw ExitCode(process.terminationStatus)
      }

      print("Linked \(target) → \(source)")
    }

    private func printError(_ message: String) {
      FileHandle.standardError.write(Data("error: \(message)\n".utf8))
    }
  }
}
