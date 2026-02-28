import Foundation

extension Configuration {
    /// Tracks the root directory and which config files were explicitly loaded,
    /// so nested directory config discovery can avoid re-applying them.
    struct FileGraph: Hashable {
        let rootDirectory: String
        private let loadedConfigFiles: Set<String>

        init(rootDirectory: String, loadedConfigFiles: Set<String> = []) {
            self.rootDirectory = rootDirectory
            self.loadedConfigFiles = loadedConfigFiles
        }

        /// Returns `true` if the config file at `path` was already loaded as part of
        /// the initial configuration, so it should not be applied again as a nested config.
        func includesFile(atPath path: String) -> Bool {
            loadedConfigFiles.contains(path)
        }

        // MARK: - Building Configuration from Files

        /// Parses the given config file paths, merges them left-to-right, and returns
        /// the resulting configuration.
        static func resultingConfiguration(
            configFiles: [String],
            rootDirectory: String,
            enableAllRules: Bool,
            onlyRule: [String],
            cachePath: String?,
        ) throws -> (configuration: Configuration, loadedFiles: Set<String>) {
            var loadedFiles = Set<String>()

            // Parse each config file into its dict + root directory
            let configData: [(configurationDict: [String: Any], rootDirectory: String)] =
                try configFiles.map { filePath in
                    let absolutePath = filePath
                        .absolutePathRepresentation(rootDirectory: rootDirectory)

                    guard !absolutePath.isEmpty,
                          FileManager.default.fileExists(atPath: absolutePath)
                    else {
                        let isInitial = configFiles.first == filePath
                        throw isInitial
                            ? Issue.initialFileNotFound(path: absolutePath)
                            : Issue.fileNotFound(path: absolutePath)
                    }

                    let contents = try String(contentsOfFile: absolutePath, encoding: .utf8)
                    let dict = try YamlParser.parse(contents)
                    loadedFiles.insert(absolutePath)

                    let fileRoot = absolutePath.bridge().deletingLastPathComponent
                    return (configurationDict: dict, rootDirectory: fileRoot)
                }

            // Merge configs left-to-right (first is base, rest override)
            let firstData = configData.first ?? (configurationDict: [:], rootDirectory: "")
            let restData = Array(configData.dropFirst())

            var firstConfiguration = try Configuration(
                dict: firstData.configurationDict,
                enableAllRules: enableAllRules,
                onlyRule: onlyRule,
                cachePath: cachePath,
            )
            firstConfiguration.fileGraph = FileGraph(rootDirectory: rootDirectory)
            firstConfiguration.makeIncludedAndExcludedPaths(
                relativeTo: rootDirectory,
                previousBasePath: firstData.rootDirectory,
            )

            let merged = try restData.reduce(firstConfiguration) { parent, data in
                var child = try Configuration(
                    parentConfiguration: parent,
                    dict: data.configurationDict,
                    enableAllRules: enableAllRules,
                    onlyRule: onlyRule,
                    cachePath: cachePath,
                )
                child.fileGraph = FileGraph(rootDirectory: data.rootDirectory)
                return parent.merged(withChild: child, rootDirectory: rootDirectory)
            }

            return (configuration: merged, loadedFiles: loadedFiles)
        }
    }
}
