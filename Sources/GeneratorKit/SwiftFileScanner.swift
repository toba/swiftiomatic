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
    filter: ((String) -> Bool)? = nil,
    body: (CodeBlockItemSyntax) throws -> Void
) throws {
    try enumerateSwiftFiles(in: directory, filter: filter) { statements in
        for statement in statements {
            try body(statement)
        }
    }
}

/// Enumerates all Swift files within a directory, providing all top-level statements per file.
///
/// - Parameters:
///   - directory: The directory to scan.
///   - filter: Optional predicate on the file base name. Defaults to accepting all `.swift` files.
///   - body: Called once per file with all top-level statements.
package func enumerateSwiftFiles(
    in directory: URL,
    filter: ((String) -> Bool)? = nil,
    body: (CodeBlockItemListSyntax) throws -> Void
) throws {
    let fm = FileManager.default
    guard let enumerator = fm.enumerator(atPath: directory.path()) else {
        fatalError("Could not list the directory \(directory.path())")
    }

    for baseName in enumerator {
        guard let baseName = baseName as? String, baseName.hasSuffix(".swift") else { continue }
        if let filter, !filter(baseName) { continue }

        let fileURL = directory.appending(path: baseName)
        let fileInput = try String(contentsOf: fileURL, encoding: .utf8)
        let sourceFile = Parser.parse(source: fileInput)

        try body(sourceFile.statements)
    }
}
