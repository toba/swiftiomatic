import Foundation
import Synchronization
import TobaConcurrency

/// Collects lint findings and renders them as one SARIF 2.1.0 log.
///
/// SARIF (Static Analysis Results Interchange Format) is the JSON format that GitHub code scanning,
/// VS Code and other tools read. The log has one run. Each recorded entry becomes one result, and
/// each rule that fired appears once in `tool.driver.rules`.
///
/// A file inside the working directory gets a URI relative to the `%SRCROOT%` base. Any other file
/// gets an absolute `file://` URI.
public final class SARIFLintReporter: Sendable {
    /// The rule ID for a diagnostic from the Swift parser.
    public static let parserRuleID = "parser"

    /// The rule ID for a diagnostic from the tool itself, such as a file that cannot be read.
    public static let toolRuleID = "tool"

    public enum Level: String, Encodable, Sendable { case error, warning, note }

    public struct Entry: Sendable {
        public let file: String?
        public let line: Int?
        public let column: Int?
        public let level: Level
        public let ruleID: String
        public let message: String

        public init(
            file: String?,
            line: Int?,
            column: Int?,
            level: Level,
            ruleID: String,
            message: String
        ) {
            self.file = file
            self.line = line
            self.column = column
            self.level = level
            self.ruleID = ruleID
            self.message = message
        }
    }

    private static let sourceRootID = "%SRCROOT%"

    private let toolVersion: String
    /// The working directory path with a trailing slash. A file path with this prefix is relative.
    private let rootPath: String
    /// The `file://` URI of the working directory. SARIF requires a trailing slash on a base URI.
    private let rootURI: String
    private let entries = Mutex<[Entry]>([])

    /// - Parameters:
    ///   - toolVersion: The `sm` version that goes in `tool.driver.version`.
    ///   - workingDirectory: The directory that relative artifact URIs start from.
    public init(
        toolVersion: String,
        workingDirectory: URL = .init(fileURLWithPath: FileManager.default.currentDirectoryPath)
    ) {
        let directory = workingDirectory.standardizedFileURL
        let uri = directory.absoluteString

        self.toolVersion = toolVersion
        rootPath = directory.path.hasSuffix("/") ? directory.path : directory.path + "/"
        rootURI = uri.hasSuffix("/") ? uri : uri + "/"
    }

    public func record(_ entry: Entry) { entries.append(entry) }

    /// Returns the SARIF log as a UTF-8 string. Always succeeds for the bound encodable shape.
    public func renderJSON() -> String {
        let snapshot = entries(get: \.self)
        let ruleIDs = Set(snapshot.map(\.ruleID)).sorted()
        let ruleIndex = Dictionary(uniqueKeysWithValues: ruleIDs.enumerated().map { ($1, $0) })

        let log = Log(runs: [
            Run(
                tool: Tool(driver: Driver(
                    version: toolVersion,
                    rules: ruleIDs.map(ReportingDescriptor.init)
                )),
                originalURIBaseIDs: [Self.sourceRootID: ArtifactLocation(
                    uri: rootURI,
                    uriBaseID: nil
                )],
                results: snapshot.map { entry in
                    Result(
                        ruleID: entry.ruleID,
                        ruleIndex: ruleIndex[entry.ruleID] ?? 0,
                        level: entry.level,
                        message: Message(text: entry.message),
                        locations: entry.file.map { [location(for: entry, file: $0)] } ?? []
                    )
                }
            )
        ])
        return encodePrettyJSON(log, fallback: "{}", extraFormatting: .withoutEscapingSlashes)
    }

    /// Writes the SARIF log to standard output, terminated with a newline.
    public func flush() { writeLineToStandardOutput(renderJSON()) }

    private func location(for entry: Entry, file: String) -> Location {
        .init(physicalLocation: PhysicalLocation(
            artifactLocation: artifactLocation(for: file),
            region: entry.line.map { Region(startLine: $0, startColumn: entry.column) }
        ))
    }

    private func artifactLocation(for file: String) -> ArtifactLocation {
        let path = URL(fileURLWithPath: file).standardizedFileURL.path

        if path.hasPrefix(rootPath),
           let relative = String(path.dropFirst(rootPath.count))
               .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
        {
            return ArtifactLocation(uri: relative, uriBaseID: Self.sourceRootID)
        }
        return .init(uri: URL(fileURLWithPath: path).absoluteString, uriBaseID: nil)
    }
}

// MARK: - SARIF 2.1.0 schema subset

// Property names follow Swift style. Each `CodingKeys` enum keeps the key text the SARIF schema
// requires.

private struct Log: Encodable {
    let schema = "https://json.schemastore.org/sarif-2.1.0.json"
    let version = "2.1.0"
    let runs: [Run]

    private enum CodingKeys: String, CodingKey {
        case schema = "$schema"
        case version, runs
    }
}

private struct Run: Encodable {
    let tool: Tool
    let originalURIBaseIDs: [String: ArtifactLocation]
    let results: [Result]

    private enum CodingKeys: String, CodingKey {
        case tool, results
        case originalURIBaseIDs = "originalUriBaseIds"
    }
}

private struct Tool: Encodable {
    let driver: Driver
}

private struct Driver: Encodable {
    let name = "sm"
    let informationURI = "https://github.com/toba/swiftiomatic"
    let version: String
    let rules: [ReportingDescriptor]

    private enum CodingKeys: String, CodingKey {
        case name, version, rules
        case informationURI = "informationUri"
    }
}

private struct ReportingDescriptor: Encodable {
    let id: String
}

private struct Result: Encodable {
    let ruleID: String
    let ruleIndex: Int
    let level: SARIFLintReporter.Level
    let message: Message
    let locations: [Location]

    private enum CodingKeys: String, CodingKey {
        case ruleIndex, level, message, locations
        case ruleID = "ruleId"
    }
}

private struct Message: Encodable {
    let text: String
}

private struct Location: Encodable {
    let physicalLocation: PhysicalLocation
}

private struct PhysicalLocation: Encodable {
    let artifactLocation: ArtifactLocation
    let region: Region?
}

private struct ArtifactLocation: Encodable {
    let uri: String
    let uriBaseID: String?

    private enum CodingKeys: String, CodingKey {
        case uri
        case uriBaseID = "uriBaseId"
    }
}

private struct Region: Encodable {
    let startLine: Int
    let startColumn: Int?
}
