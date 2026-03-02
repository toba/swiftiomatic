import Foundation
import PackagePlugin

@main
struct FormatPlugin {
    func format(tool: PluginContext.Tool, targetDirectories: [String]) throws {
        let exec = tool.url
        var arguments = ["format"]
        arguments.append(contentsOf: targetDirectories)

        let process = try Process.run(exec, arguments: arguments)
        process.waitUntilExit()

        if process.terminationReason == .exit && process.terminationStatus == 0 {
            print("Formatted the source code.")
        } else {
            let problem = "\(process.terminationReason):\(process.terminationStatus)"
            Diagnostics.error("swiftiomatic format failed: \(problem)")
        }
    }
}

extension FormatPlugin: CommandPlugin {
    func performCommand(
        context: PluginContext,
        arguments: [String]
    ) async throws {
        let tool = try context.tool(named: "swiftiomatic")

        var argExtractor = ArgumentExtractor(arguments)
        let targetNames = argExtractor.extractOption(named: "target")
        let targets = targetNames.isEmpty
            ? context.package.targets
            : try context.package.targets(named: targetNames)

        let sourceTargets = targets.compactMap { $0 as? SourceModuleTarget }

        try format(
            tool: tool,
            targetDirectories: sourceTargets.map { $0.directoryURL.path() }
        )
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension FormatPlugin: XcodeCommandPlugin {
    func performCommand(context: XcodeProjectPlugin.XcodePluginContext, arguments: [String]) throws {
        let tool = try context.tool(named: "swiftiomatic")
        try format(
            tool: tool,
            targetDirectories: [context.xcodeProject.directoryURL.path()]
        )
    }
}
#endif
