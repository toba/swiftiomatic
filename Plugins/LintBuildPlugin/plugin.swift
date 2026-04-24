import Foundation
import PackagePlugin

@main
struct LintBuildPlugin: BuildToolPlugin {
    func createBuildCommands(
        context: PluginContext,
        target: Target
    ) async throws -> [Command] {
        guard let sourceTarget = target as? SourceModuleTarget else {
            return []
        }

        let sm = try context.tool(named: "sm")

        // Look for a configuration file in the package root.
        let configURL = context.package.directoryURL
            .appending(path: "swiftiomatic.json")
        let configExists = FileManager.default.fileExists(atPath: configURL.path())

        var arguments: [String] = ["lint", "--parallel"]

        if configExists {
            arguments.append(contentsOf: ["--configuration", configURL.path()])
        }

        arguments.append(sourceTarget.directoryURL.path())

        return [
            .prebuildCommand(
                displayName: "Lint \(target.name)",
                executable: sm.url,
                arguments: arguments,
                outputFilesDirectory: context.pluginWorkDirectoryURL
            )
        ]
    }
}

#if canImport(XcodeProjectPlugin)
    import XcodeProjectPlugin

    extension LintBuildPlugin: XcodeBuildToolPlugin {
        func createBuildCommands(
            context: XcodeProjectPlugin.XcodePluginContext,
            target: XcodeProjectPlugin.XcodeTarget
        ) throws -> [Command] {
            let sm = try context.tool(named: "sm")

            let configURL = context.xcodeProject.directoryURL
                .appending(path: "swiftiomatic.json")
            let configExists = FileManager.default.fileExists(atPath: configURL.path())

            var arguments: [String] = ["lint", "--parallel"]

            if configExists {
                arguments.append(contentsOf: ["--configuration", configURL.path()])
            }

            // For Xcode projects, lint the input files belonging to this target.
            let sourceFiles = target.inputFiles.filter { $0.type == .source }
            arguments.append(contentsOf: sourceFiles.map { $0.url.path() })

            return [
                .prebuildCommand(
                    displayName: "Lint \(target.displayName)",
                    executable: sm.url,
                    arguments: arguments,
                    outputFilesDirectory: context.pluginWorkDirectoryURL
                )
            ]
        }
    }
#endif
