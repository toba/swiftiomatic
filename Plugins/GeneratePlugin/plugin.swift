import Foundation
import PackagePlugin

@main
struct GeneratePlugin: BuildToolPlugin {
    func createBuildCommands(
        context: PluginContext,
        target: Target
    ) async throws -> [Command] {
        guard let sourceTarget = target as? SourceModuleTarget else {
            return []
        }

        let generator = try context.tool(named: "Generator")
        let outputDir = context.pluginWorkDirectoryURL

        // Collect input files from the three directories the generator scans.
        let packageDir = context.package.directoryURL
        let kitDir =
            packageDir
            .appending(path: "Sources/SwiftiomaticKit")

        let inputDirectories = [
            kitDir.appending(path: "Syntax/Rules"),
            kitDir.appending(path: "Layout/Rules"),
            kitDir.appending(path: "Layout/Tokens"),
        ]

        let inputFiles = sourceTarget.sourceFiles
            .filter { file in
                inputDirectories.contains { dir in
                    file.url.path().hasPrefix(dir.path())
                }
            }
            .map(\.url)

        // The four generated Swift files.
        let outputFiles = [
            outputDir.appending(path: "Pipelines+Generated.swift"),
            outputDir.appending(path: "ConfigurationRegistry+Generated.swift"),
            outputDir.appending(path: "TokenStream+Generated.swift"),
            outputDir.appending(path: "ConfigurationSchema+Generated.swift"),
        ]

        return [
            .buildCommand(
                displayName: "Generate SwiftiomaticKit pipelines and registry",
                executable: generator.url,
                arguments: [
                    packageDir.path(),
                    outputDir.path(),
                    "--skip-schema",
                ],
                inputFiles: inputFiles,
                outputFiles: outputFiles
            )
        ]
    }
}
