import Foundation
import PackagePlugin

@main
struct GeneratePlugin: BuildToolPlugin {
    func createBuildCommands(
        context: PluginContext,
        target: Target
    ) async throws -> [Command] {
        guard let sourceTarget = target as? SourceModuleTarget else { return [] }

        let generator = try context.tool(named: "Generator")
        let outputDir = context.pluginWorkDirectoryURL

        let packageDir = context.package.directoryURL
        let kitDir =
            packageDir
            .appending(path: "Sources/SwiftiomaticKit")

        let inputDirectories = [
            kitDir.appending(path: "Rules"),
            kitDir.appending(path: "Layout/Tokens"),
        ]

        let inputFiles = sourceTarget.sourceFiles
            .filter { file in
                inputDirectories.contains { dir in file.url.path().hasPrefix(dir.path()) }
            }
            .map(\.url)

        // The dispatch audit reads the two hand-written dispatchers, so a call removed from either
        // one has to re-run the command.
        let dispatcherFiles = [
            kitDir.appending(path: "Syntax/Rewriter/SourceFile.swift"),
            kitDir.appending(path: "Layout/LayoutWriter.swift"),
        ]

        let outputFiles = [
            outputDir.appending(path: "Pipelines+Generated.swift"),
            outputDir.appending(path: "RewritePipeline+Generated.swift"),
            outputDir.appending(path: "ConfigurationRegistry+Generated.swift"),
            outputDir.appending(path: "TokenStream+Generated.swift"),
            outputDir.appending(path: "ConfigurationSchema+Generated.swift"),
        ]

        return [
            .buildCommand(
                displayName: "Generate SwiftiomaticKit pipelines and registry",
                executable: generator.url,
                arguments: [packageDir.path(), outputDir.path(), "--skip-schema"],
                inputFiles: inputFiles + dispatcherFiles,
                outputFiles: outputFiles
            )
        ]
    }
}
