import Foundation
import SwiftParser
import SwiftSyntax

/// Enumerates top-level statements in all Swift files within a directory.
///
/// - Parameters:
///   - directory: The directory to scan.
///   - filter: Optional predicate on the file base name. Defaults to accepting all `.swift` files.
///   - body: Called once per top-level `CodeBlockItemSyntax` in each matching file.
package func enumerateSwiftStatements(
    in directory: URL,
    filter: (@Sendable (String) -> Bool)? = nil,
    body: (CodeBlockItemSyntax) throws -> Void
) async throws {
    try await enumerateSwiftFiles(in: directory, filter: filter) { statements in
        for statement in statements { try body(statement) }
    }
}

/// Enumerates all Swift files within a directory, providing all top-level statements per file.
///
/// Files parse concurrently across cores. `body` still runs serially, in sorted path order, so a
/// caller can accumulate into non-Sendable state and get the same result on every run.
///
/// - Parameters:
///   - directory: The directory to scan.
///   - filter: Optional predicate on the file base name. Defaults to accepting all `.swift` files.
///   - body: Called once per file with all top-level statements.
package func enumerateSwiftFiles(
    in directory: URL,
    filter: (@Sendable (String) -> Bool)? = nil,
    body: (CodeBlockItemListSyntax) throws -> Void
) async throws {
    for statements in try await parseSwiftFiles(in: directory, filter: filter) {
        try body(statements)
    }
}

/// Parses every matching Swift file under `directory` concurrently, returning the parsed top-level
/// statements in sorted path order.
private func parseSwiftFiles(
    in directory: URL,
    filter: (@Sendable (String) -> Bool)?
) async throws -> [CodeBlockItemListSyntax] {
    let urls = try swiftFileURLs(in: directory, filter: filter)

    // Index each result so the sorted input order survives out-of-order completion.
    return try await withThrowingTaskGroup(of: (Int, CodeBlockItemListSyntax).self) { group in
        for (index, url) in urls.enumerated() {
            group.addTask(name: "parse \(url.lastPathComponent)") {
                guard let source = try? String(contentsOf: url, encoding: .utf8) else {
                    throw ScanError.unreadableFile(url)
                }
                return (index, Parser.parse(source: source).statements)
            }
        }

        var results = [CodeBlockItemListSyntax?](repeating: nil, count: urls.count)
        for try await (index, statements) in group { results[index] = statements }
        return results.compactMap(\.self)
    }
}

/// Returns every `.swift` file under `directory` that passes `filter` , sorted by path.
private func swiftFileURLs(
    in directory: URL,
    filter: (@Sendable (String) -> Bool)?
) throws -> [URL] {
    guard let enumerator = FileManager.default.enumerator(
        at: directory,
        includingPropertiesForKeys: nil,
        options: [.skipsHiddenFiles]
    ) else { throw ScanError.unreadableDirectory(directory) }

    var urls: [URL] = []

    for case let url as URL in enumerator where url.pathExtension == "swift" {
        if let filter, !filter(url.lastPathComponent) { continue }
        urls.append(url)
    }
    urls.sort { $0.path < $1.path }
    return urls
}

/// A failure reading the source tree the generator scans.
package enum ScanError: Error, CustomStringConvertible {
    case unreadableDirectory(URL)
    case unreadableFile(URL)

    package var description: String {
        switch self {
            case let .unreadableDirectory(url): "Could not list the directory \(url.path())"
            case let .unreadableFile(url): "Could not read \(url.path()) as UTF-8"
        }
    }
}
