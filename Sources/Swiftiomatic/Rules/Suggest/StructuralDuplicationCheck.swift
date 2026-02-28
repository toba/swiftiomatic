import SwiftSyntax

/// §8b: Two-pass cross-file structural duplication detection via AST fingerprinting.
///
/// Pass 1: Visit all function declarations, compute a structural fingerprint of each
/// function body by recording the sequence of syntax node types (ignoring identifiers,
/// literal values, and trivia). Functions with fewer than 5 structural nodes are skipped.
///
/// Pass 2: Group functions by fingerprint. Groups of 2+ are structural duplicates.
final class StructuralDuplicationCheck: BaseCheck {
    /// Collected function fingerprints from this file.
    private(set) var collectedFunctions:
        [(name: String, file: String, line: Int, fingerprint: String)] = []

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        guard let body = node.body else { return .visitChildren }

        let nodes = FingerprintVisitor.collectNodeTypes(from: body)
        guard nodes.count >= 5 else { return .visitChildren }

        let fingerprint = nodes.joined(separator: ",")
        let loc = node.startLocation(converter: .init(fileName: filePath, tree: node.root))

        collectedFunctions.append(
            (
                name: node.name.text,
                file: filePath,
                line: loc.line,
                fingerprint: fingerprint,
            ),
        )

        return .visitChildren
    }

    /// After all files have been walked, generate findings for structural duplicates.
    ///
    /// - Parameter allCollected: Combined fingerprint data from all files.
    /// - Returns: Findings for groups of 2+ functions sharing an identical fingerprint.
    func generateDuplicationFindings(
        allCollected: [(name: String, file: String, line: Int, fingerprint: String)],
    ) -> [Finding] {
        var groups: [String: [(name: String, file: String, line: Int)]] = [:]

        for entry in allCollected {
            groups[entry.fingerprint, default: []].append(
                (
                    name: entry.name,
                    file: entry.file,
                    line: entry.line,
                ),
            )
        }

        var results: [Finding] = []

        for (_, members) in groups where members.count >= 2 {
            let confidence: Confidence = members.count >= 3 ? .high : .medium
            let otherNames = members.map { "'\($0.name)' (\($0.file):\($0.line))" }

            for (index, member) in members.enumerated() {
                let peers = otherNames.enumerated()
                    .filter { $0.offset != index }
                    .map(\.element)
                    .joined(separator: ", ")

                results.append(
                    Finding(
                        category: .agentReview,
                        severity: .medium,
                        file: member.file,
                        line: member.line,
                        column: 1,
                        message: "Function '\(member.name)' is structurally identical to \(peers)",
                        suggestion: "Consider extracting shared logic into a common function",
                        confidence: confidence,
                    ),
                )
            }
        }

        return results
    }
}

/// Recursively walks a syntax subtree and collects the type name of every
/// non-token, non-trivia node to produce a structural fingerprint.
enum FingerprintVisitor {
    /// Container node types to skip — they add no structural signal.
    private static let containerTypes: Set<String> = [
        "CodeBlockSyntax",
        "CodeBlockItemListSyntax",
        "CodeBlockItemSyntax",
    ]

    /// Collect structural node type names from the given syntax subtree.
    static func collectNodeTypes(from node: some SyntaxProtocol) -> [String] {
        var result: [String] = []
        collect(from: Syntax(node), into: &result)
        return result
    }

    private static func collect(from node: Syntax, into result: inout [String]) {
        // Skip tokens — we only care about structural (non-leaf) nodes.
        if node.is(TokenSyntax.self) { return }

        let typeName = "\(type(of: node.asProtocol(SyntaxProtocol.self)))"

        if !containerTypes.contains(typeName) {
            result.append(typeName)
        }

        for child in node.children(viewMode: .sourceAccurate) {
            collect(from: child, into: &result)
        }
    }
}
