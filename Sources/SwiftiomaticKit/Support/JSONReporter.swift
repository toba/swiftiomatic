import Foundation
import Synchronization
import TobaConcurrency

/// Collects lint findings as structured records and renders them as a JSON array.
///
/// Each entry has the shape:
/// ```json
/// { "file": "/abs/path.swift", "line": 12, "column": 5,
///   "severity": "warning", "rule": "requireCamelCaseIdentifiers", "message": "..." }
/// ```
public final class JSONLintReporter: Sendable {
    public struct Entry: Encodable, Sendable {
        public let file: String?
        public let line: Int?
        public let column: Int?
        public let severity: String
        public let rule: String?
        public let message: String

        public init(
            file: String?,
            line: Int?,
            column: Int?,
            severity: String,
            rule: String?,
            message: String
        ) {
            self.file = file
            self.line = line
            self.column = column
            self.severity = severity
            self.rule = rule
            self.message = message
        }

        // Emit `null` for absent location/rule fields rather than omitting the keys, so consumers
        // can rely on a stable schema with all six fields always present.
        private enum CodingKeys: String, CodingKey {
            case file, line, column, severity, rule, message
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            if let file { try container.encode(file, forKey: .file) }
            else { try container.encodeNil(forKey: .file) }
            if let line { try container.encode(line, forKey: .line) }
            else { try container.encodeNil(forKey: .line) }
            if let column { try container.encode(column, forKey: .column) }
            else { try container.encodeNil(forKey: .column) }
            try container.encode(severity, forKey: .severity)
            if let rule { try container.encode(rule, forKey: .rule) }
            else { try container.encodeNil(forKey: .rule) }
            try container.encode(message, forKey: .message)
        }
    }

    private let entries = Mutex<[Entry]>([])

    public init() {}

    public func record(_ entry: Entry) {
        entries.append(entry)
    }

    /// Returns the JSON array as a UTF-8 string. Always succeeds for the bound encodable shape.
    public func renderJSON() -> String {
        let snapshot = entries(get: \.self)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = (try? encoder.encode(snapshot)) ?? Data("[]".utf8)
        return String(bytes: data, encoding: .utf8) ?? "[]"
    }

    /// Writes the JSON array to standard output, terminated with a newline.
    public func flush() {
        FileHandle.standardOutput.write(Data(renderJSON().utf8))
        FileHandle.standardOutput.write(Data([0x0A]))
    }
}

/// Collects per-file format outcomes and renders them as a JSON summary.
///
/// ```json
/// { "changed":   [{ "file": "...", "bytes_before": 1234, "bytes_after": 1280 }],
///   "unchanged": ["..."],
///   "skipped":   [{ "file": "...", "reason": "unparsable" }] }
/// ```
public final class JSONFormatReporter: Sendable {
    public struct Changed: Encodable, Sendable {
        public let file: String
        public let bytesBefore: Int
        public let bytesAfter: Int

        public init(file: String, bytesBefore: Int, bytesAfter: Int) {
            self.file = file
            self.bytesBefore = bytesBefore
            self.bytesAfter = bytesAfter
        }
    }

    public struct Skipped: Encodable, Sendable {
        public let file: String
        public let reason: String

        public init(file: String, reason: String) {
            self.file = file
            self.reason = reason
        }
    }

    private struct Buffer: Sendable {
        var changed: [Changed] = []
        var unchanged: [String] = []
        var skipped: [Skipped] = []
    }

    private let buffer = Mutex(Buffer())

    public init() {}

    public func recordChanged(file: String, bytesBefore: Int, bytesAfter: Int) {
        buffer.withLock {
            $0.changed.append(.init(file: file, bytesBefore: bytesBefore, bytesAfter: bytesAfter))
        }
    }

    public func recordUnchanged(file: String) {
        buffer.withLock { $0.unchanged.append(file) }
    }

    public func recordSkipped(file: String, reason: String) {
        buffer.withLock { $0.skipped.append(.init(file: file, reason: reason)) }
    }

    public func renderJSON() -> String {
        let snapshot = buffer(get: \.self)

        struct Report: Encodable {
            let changed: [Changed]
            let unchanged: [String]
            let skipped: [Skipped]
        }

        let report = Report(
            changed: snapshot.changed,
            unchanged: snapshot.unchanged,
            skipped: snapshot.skipped
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = (try? encoder.encode(report)) ?? Data("{}".utf8)
        return String(bytes: data, encoding: .utf8) ?? "{}"
    }

    public func flush() {
        FileHandle.standardOutput.write(Data(renderJSON().utf8))
        FileHandle.standardOutput.write(Data([0x0A]))
    }
}
