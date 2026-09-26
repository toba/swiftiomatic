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
        /// The notes of the finding. Each one becomes a related location.
        public let evidence: [LintEvidence]
        /// Whether the finding is on a changed line. It becomes the SARIF `baselineState`.
        public let status: ChangeStatus?

        public init(
            file: String?,
            line: Int?,
            column: Int?,
            level: Level,
            ruleID: String,
            message: String,
            evidence: [LintEvidence] = [],
            status: ChangeStatus? = nil
        ) {
            self.file = file
            self.line = line
            self.column = column
            self.level = level
            self.ruleID = ruleID
            self.message = message
            self.evidence = evidence
            self.status = status
        }
    }

    private static let sourceRootID = "%SRCROOT%"

    private let toolVersion: String
    /// The working directory. SARIF requires the trailing slash that its `rootURI` carries.
    private let paths: WorkingDirectoryPaths
    private let entries = Mutex<[Entry]>([])

    /// - Parameters:
    ///   - toolVersion: The `sm` version that goes in `tool.driver.version`.
    ///   - workingDirectory: The directory that relative artifact URIs start from.
    public init(
        toolVersion: String,
        workingDirectory: URL = .init(fileURLWithPath: FileManager.default.currentDirectoryPath)
    ) {
        self.toolVersion = toolVersion
        paths = WorkingDirectoryPaths(workingDirectory)
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
                    rules: ruleIDs.map(ReportingDescriptor.init(ruleID:))
                )),
                originalURIBaseIDs: [Self.sourceRootID: ArtifactLocation(
                    uri: paths.rootURI,
                    uriBaseID: nil
                )],
                results: snapshot.map { entry in
                    Result(
                        ruleID: entry.ruleID,
                        ruleIndex: ruleIndex[entry.ruleID] ?? 0,
                        level: entry.level,
                        message: Message(text: entry.message),
                        locations: entry.file.map {
                            [location(file: $0, line: entry.line, column: entry.column)]
                        } ?? [],
                        relatedLocations: relatedLocations(for: entry),
                        baselineState: entry.status.map {
                            switch $0 {
                                case .introduced: .new
                                case .existing: .unchanged
                            }
                        }
                    )
                }
            )
        ])
        return encodePrettyJSON(log, fallback: "{}", extraFormatting: .withoutEscapingSlashes)
    }

    /// Writes the SARIF log to standard output, terminated with a newline.
    public func flush() { writeLineToStandardOutput(renderJSON()) }

    private func location(file: String, line: Int?, column: Int?) -> Location {
        .init(physicalLocation: PhysicalLocation(
            artifactLocation: artifactLocation(for: file),
            region: line.map { Region(startLine: $0, startColumn: column) }
        ))
    }

    /// Maps the evidence of an entry to related locations. SARIF requires a physical location, so
    /// evidence without a file uses the file of the entry, and evidence with neither is left out.
    private func relatedLocations(for entry: Entry) -> [RelatedLocation]? {
        let related = entry.evidence.compactMap { evidence -> (LintEvidence, String)? in
            (evidence.file ?? entry.file).map { (evidence, $0) }
        }
        guard !related.isEmpty else { return nil }

        return related.enumerated().map { index, pair in
            let (evidence, file) = pair
            return RelatedLocation(
                id: index,
                physicalLocation: location(file: file, line: evidence.line, column: evidence.column)
                    .physicalLocation,
                message: Message(text: evidence.message),
                properties: .init(role: evidence.role)
            )
        }
    }

    private func artifactLocation(for file: String) -> ArtifactLocation {
        if let relative = paths.relativePath(of: file)?
            .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
        {
            return ArtifactLocation(uri: relative, uriBaseID: Self.sourceRootID)
        }
        return .init(uri: URL(fileURLWithPath: paths.standardized(file)).absoluteString, uriBaseID: nil)
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
    let shortDescription: Message?
    let properties: Properties?

    struct Properties: Encodable {
        let guidance: GuidanceLevel
    }

    /// Fills in the applicability and guidance level when the rule ID names a known rule.
    init(ruleID: String) {
        let info = RuleCatalog.info(for: ruleID).flatMap { $0.key == ruleID ? $0 : nil }

        id = ruleID
        shortDescription = info.map { Message(text: $0.applicability) }
        properties = info.map { Properties(guidance: $0.guidance) }
    }
}

private struct Result: Encodable {
    let ruleID: String
    let ruleIndex: Int
    let level: SARIFLintReporter.Level
    let message: Message
    let locations: [Location]
    let relatedLocations: [RelatedLocation]?
    let baselineState: BaselineState?

    enum BaselineState: String, Encodable { case new, unchanged }

    private enum CodingKeys: String, CodingKey {
        case ruleIndex, level, message, locations, relatedLocations, baselineState
        case ruleID = "ruleId"
    }
}

private struct RelatedLocation: Encodable {
    let id: Int
    let physicalLocation: PhysicalLocation
    let message: Message
    let properties: Properties

    struct Properties: Encodable {
        let role: EvidenceRole
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
