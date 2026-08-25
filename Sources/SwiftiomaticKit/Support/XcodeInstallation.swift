import Foundation

/// Installed copies of Xcode and the toolchain path each one exposes
///
/// A machine often carries a release Xcode and a beta side by side. Both ship their own
/// `swift-format` binary, and both need the symlink that `sm link` writes.
package enum XcodeInstallation {
    /// One installed Xcode
    package struct Toolchain: Sendable, Hashable {
        /// Bundle name, such as `Xcode-beta.app`
        package var name: String

        /// The application bundle
        package var applicationURL: URL

        /// The `swift-format` path inside the bundled toolchain
        package var swiftFormatURL: URL

        /// True when the bundle name marks a prerelease build
        package var isBeta: Bool
    }

    /// Directories that hold an application bundle on macOS
    package static var defaultSearchDirectories: [URL] {
        [
            URL(filePath: "/Applications"),
            FileManager.default.homeDirectoryForCurrentUser.appending(path: "Applications"),
        ]
    }

    /// Path of the toolchain `bin` directory, relative to the application bundle
    private static let toolchainBinPath =
        "Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin"

    /// Find every installed Xcode that carries a bundled toolchain
    ///
    /// A missing directory and an unreadable directory are both skipped. The release Xcode sorts
    /// ahead of every beta so the caller reports the primary installation first.
    ///
    /// - Parameters:
    ///   - directories: Directories to scan for application bundles
    ///   - fileManager: File system to read
    /// - Returns: One entry per bundle, with repeated paths removed
    package static func discover(
        in directories: [URL] = defaultSearchDirectories,
        fileManager: FileManager = .default
    ) -> [Toolchain] {
        var seen = Set<String>()
        var found = [Toolchain]()

        for directory in directories {
            let names = (try? fileManager.contentsOfDirectory(atPath: directory.path))?.sorted()
                ?? []

            for name in names where isXcodeBundleName(name) {
                let application = directory.appending(path: name)
                let bin = application.appending(path: toolchainBinPath)

                var isDirectory: ObjCBool = false
                guard fileManager.fileExists(atPath: bin.path, isDirectory: &isDirectory),
                      isDirectory.boolValue,
                      seen.insert(application.standardizedFileURL.path).inserted else { continue }

                found.append(Toolchain(
                    name: name, applicationURL: application,
                    swiftFormatURL: bin.appending(path: "swift-format"),
                    isBeta: name.lowercased().contains("beta")))
            }
        }
        // release first, then betas in name order
        return found.sorted { lhs, rhs in
            lhs.isBeta == rhs.isBeta ? lhs.name < rhs.name : !lhs.isBeta
        }
    }

    private static func isXcodeBundleName(_ name: String) -> Bool {
        guard name.hasSuffix(".app") else { return false }
        let stem = name.dropLast(4)
        return stem == "Xcode" || stem.hasPrefix("Xcode-") || stem.hasPrefix("Xcode ")
    }
}
