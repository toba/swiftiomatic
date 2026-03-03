import Yams
import Foundation

private struct SwiftPMCommand: Codable {
    let tool: String
    let module: String?
    let sources: [String]?
    let args: [String]?
    let importPaths: [String]?

    enum CodingKeys: String, CodingKey {
        case tool
        case module = "module-name"
        case sources
        case args = "other-args"
        case importPaths = "import-paths"
    }
}

private struct SwiftPMNode: Codable {}

private struct SwiftPMNodes: Codable {
    let nodes: [String: SwiftPMNode]
}

/// Parser for Swift Package Manager's `.build/debug.yaml` compilation database
///
/// Extracts per-file compiler arguments needed for SourceKit requests.
struct SwiftPMCompilationDB: Codable {
    private let commands: [String: SwiftPMCommand]

    /// Discover compiler arguments from an SPM project root
    ///
    /// Reads `.build/debug.yaml` and returns the first non-empty argument set.
    ///
    /// - Parameters:
    ///   - projectRoot: The root directory of the Swift Package Manager project.
    static func compilerArguments(inPath projectRoot: String) -> [String]? {
        let yamlPath = URL(fileURLWithPath: projectRoot)
            .appendingPathComponent(".build/debug.yaml").path
        guard let data = FileManager.default.contents(atPath: yamlPath),
              let fileToArgs = try? parse(yaml: data),
              let firstArgs = fileToArgs.values.first(where: { !$0.isEmpty })
        else {
            return nil
        }
        return firstArgs
    }

    /// Parse a YAML compilation database into a mapping of source file paths to compiler arguments
    ///
    /// - Parameters:
    ///   - yaml: The raw YAML data from `.build/debug.yaml`.
    static func parse(yaml: Data) throws -> [String: [String]] {
        let decoder = YAMLDecoder()
        let compilationDB: Self

        if ProcessInfo.processInfo.environment["TEST_SRCDIR"] != nil {
            // Running tests
            let nodes = try decoder.decode(SwiftPMNodes.self, from: yaml)
            let suffix = "/Source/swiftiomatic/"
            let pathToReplace = Array(
                nodes.nodes.keys.filter { node in
                    node.hasSuffix(suffix)
                },
            )[0].dropLast(suffix.count - 1)
            let stringFileContents = String(data: yaml, encoding: .utf8)!
                .replacingOccurrences(of: pathToReplace, with: "")
            compilationDB = try decoder.decode(Self.self, from: stringFileContents)
        } else {
            compilationDB = try decoder.decode(Self.self, from: yaml)
        }

        let swiftCompilerCommands = compilationDB.commands
            .filter { $0.value.tool == "swift-compiler" }
        let allSwiftSources =
            swiftCompilerCommands
                .flatMap { $0.value.sources ?? [] }
                .filter { $0.hasSuffix(".swift") }
        return Dictionary(
            uniqueKeysWithValues: allSwiftSources.map { swiftSource in
                let command = swiftCompilerCommands
                    .values
                    .first { $0.sources?.contains(swiftSource) == true }

                guard let command,
                      let module = command.module,
                      let sources = command.sources,
                      let arguments = command.args,
                      let importPaths = command.importPaths
                else {
                    return (swiftSource, [])
                }

                let args =
                    ["-module-name", module] + sources
                        + arguments
                        .filteringCompilerArguments + ["-I"]
                        + importPaths

                return (swiftSource, args)
            },
        )
    }
}
