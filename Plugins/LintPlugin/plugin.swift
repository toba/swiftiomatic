import Foundation
import PackagePlugin

@main
struct LintPlugin {
    func lint(tool: PluginContext.Tool, targetDirectories: [String], configurationFilePath: String?)
        throws
    {
        var arguments: [String] = ["lint"]
        arguments.append(contentsOf: targetDirectories)
        arguments.append(contentsOf: ["--recursive", "--parallel", "--strict"])

        if let configurationFilePath {
            arguments.append(contentsOf: ["--configuration", configurationFilePath])
        }

        let process = try Process.run(tool.url, arguments: arguments)
        process.waitUntilExit()

        if process.terminationReason == .exit && process.terminationStatus == 0 {
            print("Linted the source code.")
        } else {
            let problem = "\(process.terminationReason):\(process.terminationStatus)"
            Diagnostics.error("sm invocation failed: \(problem)")
        }
    }
}

extension LintPlugin: CommandPlugin {
    func performCommand(
        context: PluginContext,
        arguments: [String]
    ) async throws {
        let smTool = try context.tool(named: "sm")

        var argExtractor = ArgumentExtractor(arguments)
        let targetNames = argExtractor.extractOption(named: "target")
        let targetsToFormat =
            targetNames.isEmpty
            ? context.package.targets : try context.package.targets(named: targetNames)
        let configurationFilePath = argExtractor.extractOption(named: "configuration").first
        let sourceCodeTargets = targetsToFormat.compactMap { $0 as? SourceModuleTarget }

        try lint(
            tool: smTool,
            targetDirectories: sourceCodeTargets.map { $0.directoryURL.path() },
            configurationFilePath: configurationFilePath
        )
    }
}

#if canImport(XcodeProjectPlugin)
    import XcodeProjectPlugin

    extension LintPlugin: XcodeCommandPlugin {
        func performCommand(context: XcodeProjectPlugin.XcodePluginContext, arguments: [String])
            throws
        {
            let smTool = try context.tool(named: "sm")
            var argExtractor = ArgumentExtractor(arguments)
            let configurationFilePath = argExtractor.extractOption(named: "configuration").first

            try lint(
                tool: smTool,
                targetDirectories: [context.xcodeProject.directoryURL.path()],
                configurationFilePath: configurationFilePath
            )
        }
    }
#endif
