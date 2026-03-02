import Foundation
import PackagePlugin

@main
struct LintPlugin {
    func lint(tool: PluginContext.Tool, targetDirectories: [String]) throws {
        let exec = tool.url
        var arguments = ["analyze"]
        arguments.append(contentsOf: targetDirectories)
        arguments.append(contentsOf: ["--format", "xcode"])

        let process = try Process.run(exec, arguments: arguments)
        process.waitUntilExit()

        if process.terminationReason == .exit && process.terminationStatus == 0 {
            print("Linted the source code.")
        } else {
            let problem = "\(process.terminationReason):\(process.terminationStatus)"
            Diagnostics.error("swiftiomatic analyze failed: \(problem)")
        }
    }
}

extension LintPlugin: CommandPlugin {
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

        try lint(
            tool: tool,
            targetDirectories: sourceTargets.map { $0.directoryURL.path() }
        )
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension LintPlugin: XcodeCommandPlugin {
    func performCommand(context: XcodeProjectPlugin.XcodePluginContext, arguments: [String]) throws {
        let tool = try context.tool(named: "swiftiomatic")
        try lint(
            tool: tool,
            targetDirectories: [context.xcodeProject.directoryURL.path()]
        )
    }
}
#endif
