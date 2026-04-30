import Foundation
import PackagePlugin

@main
struct GeneratePipelinesPlugin: BuildToolPlugin {
    func createBuildCommands(
        context: PluginContext,
        target: Target
    ) async throws -> [Command] {
        guard let sourceTarget = target as? SourceModuleTarget else {
            return []
        }

        let generator = try context.tool(named: "Generator")
        let outputDir = context.pluginWorkDirectoryURL

        // Pipelines and rule registry generation scan rule files. Token
        // stream stub generation is handled by GeneratePlugin.
        let packageDir = context.package.directoryURL
        let kitDir =
            packageDir
            .appending(path: "Sources/SwiftiomaticKit")

        let inputDirectories = [
            kitDir.appending(path: "Rules"),
        ]

        let inputFiles = sourceTarget.sourceFiles
            .filter { file in
                inputDirectories.contains { dir in
                    file.url.path().hasPrefix(dir.path())
                }
            }
            .map(\.url)

        let outputFiles = [
            outputDir.appending(path: "Pipelines+Generated.swift"),
            outputDir.appending(path: "ConfigurationRegistry+Generated.swift"),
            outputDir.appending(path: "ConfigurationSchema+Generated.swift"),
        ]

        return [
            .buildCommand(
                displayName: "Generate pipelines and rule registry",
                executable: generator.url,
                arguments: [
                    packageDir.path(),
                    outputDir.path(),
                    "--skip-schema",
                    "--mode", "pipelines",
                ],
                inputFiles: inputFiles,
                outputFiles: outputFiles
            )
        ]
    }
}
