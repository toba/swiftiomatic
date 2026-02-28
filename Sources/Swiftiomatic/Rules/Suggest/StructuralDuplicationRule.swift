import SwiftSyntax

struct StructuralDuplicationRule: CollectingRule, OptInRule {
    typealias FileInfo = [FunctionFingerprint]

    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "structural_duplication",
        name: "Structural Duplication",
        description: "Functions with identical AST structure are likely duplicated code that should be consolidated",
        kind: .lint,
        nonTriggeringExamples: [
            Example("func unique1() { print(1) }\nfunc unique2() { return 2 }"),
        ],
        triggeringExamples: []
    )

    func collectInfo(for file: SwiftLintFile) -> [FunctionFingerprint] {
        guard let path = file.path else { return [] }
        let collector = FingerprintCollector(filePath: path, viewMode: .sourceAccurate)
        collector.walk(file.syntaxTree)
        return collector.fingerprints
    }

    func validate(file: SwiftLintFile, collectedInfo: [SwiftLintFile: [FunctionFingerprint]]) -> [StyleViolation] {
        guard let filePath = file.path else { return [] }

        // Group all fingerprints by their structural hash
        var groups: [String: [FunctionFingerprint]] = [:]
        for (_, fingerprints) in collectedInfo {
            for fp in fingerprints {
                groups[fp.fingerprint, default: []].append(fp)
            }
        }

        var violations: [StyleViolation] = []

        for (_, members) in groups where members.count >= 2 {
            let confidence: Confidence = members.count >= 3 ? .high : .medium

            for (index, member) in members.enumerated() where member.file == filePath {
                let peers = members.enumerated()
                    .filter { $0.offset != index }
                    .map { "'\($0.element.name)' (\($0.element.file):\($0.element.line))" }
                    .joined(separator: ", ")

                violations.append(StyleViolation(
                    ruleDescription: Self.description,
                    severity: configuration.severity,
                    location: Location(file: filePath, line: member.line, character: 1),
                    reason: "Function '\(member.name)' is structurally identical to \(peers)",
                    confidence: confidence,
                    suggestion: "Consider extracting shared logic into a common function"
                ))
            }
        }

        return violations
    }
}

struct FunctionFingerprint {
    let name: String
    let file: String
    let line: Int
    let fingerprint: String
}

private final class FingerprintCollector: SyntaxVisitor {
    let filePath: String
    var fingerprints: [FunctionFingerprint] = []

    init(filePath: String, viewMode: SyntaxTreeViewMode) {
        self.filePath = filePath
        super.init(viewMode: viewMode)
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        guard let body = node.body else { return .visitChildren }

        let nodes = FingerprintVisitor.collectNodeTypes(from: body)
        guard nodes.count >= 5 else { return .visitChildren }

        let loc = node.startLocation(converter: .init(fileName: filePath, tree: node.root))
        fingerprints.append(FunctionFingerprint(
            name: node.name.text,
            file: filePath,
            line: loc.line,
            fingerprint: nodes.joined(separator: ",")
        ))

        return .visitChildren
    }
}
