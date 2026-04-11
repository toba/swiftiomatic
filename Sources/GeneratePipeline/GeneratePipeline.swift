import Foundation
import SwiftParser
import SwiftSyntax

@main
struct GeneratePipeline {
  static func main() throws {
    let projectRoot = findProjectRoot()
    let rulesDir = projectRoot + "/Sources/SwiftiomaticKit/Rules"
    let visitorsDir = projectRoot + "/Sources/SwiftiomaticKit/Support/Visitors"
    let pipelineOutputPath =
      projectRoot + "/Sources/SwiftiomaticKit/Support/LintPipeline.generated.swift"
    let registryOutputPath =
      projectRoot + "/Sources/SwiftiomaticKit/Rules/RuleRegistry+AllRules.generated.swift"

    // Collect CodeBlockVisitor node types
    let codeBlockVisitorPath = visitorsDir + "/CodeBlockVisitor.swift"
    let codeBlockNodeTypes = collectCodeBlockVisitorNodeTypes(filePath: codeBlockVisitorPath)

    // Collect BodyLengthVisitor node types (none in base class, subclasses add their own)

    // Scan all rule files
    let ruleFiles = findSwiftFiles(in: rulesDir)
    var allRules: [RuleInfo] = []
    var allRuleTypes: [RuleTypeInfo] = []

    for filePath in ruleFiles {
      let (rules, ruleTypes) = RuleCollector.collectRules(
        from: filePath,
        codeBlockNodeTypes: codeBlockNodeTypes,
      )
      allRules.append(contentsOf: rules)
      allRuleTypes.append(contentsOf: ruleTypes)
    }

    // Filter to pipeline-eligible rules
    let eligible = allRules.filter(\.isPipelineEligible)

    print(
      "Found \(allRules.count) SwiftSyntax rules, \(eligible.count) pipeline-eligible, \(allRuleTypes.count) total rule types",
    )

    // Generate the pipeline
    let pipelineOutput = PipelineEmitter.emit(rules: eligible)
    try pipelineOutput.write(toFile: pipelineOutputPath, atomically: true, encoding: .utf8)
    print("Generated \(pipelineOutputPath)")

    // Generate the rule registry
    let registryOutput = RegistryEmitter.emit(ruleTypes: allRuleTypes)
    try registryOutput.write(toFile: registryOutputPath, atomically: true, encoding: .utf8)
    print("Generated \(registryOutputPath)")
  }

  private static func findProjectRoot() -> String {
    // Walk up from current directory looking for Package.swift
    var dir = FileManager.default.currentDirectoryPath
    while dir != "/" {
      if FileManager.default.fileExists(atPath: dir + "/Package.swift") {
        return dir
      }
      dir = (dir as NSString).deletingLastPathComponent
    }
    fatalError("Could not find project root (no Package.swift found)")
  }

  private static func findSwiftFiles(in directory: String) -> [String] {
    let fm = FileManager.default
    guard let enumerator = fm.enumerator(atPath: directory) else { return [] }
    var files: [String] = []
    while let file = enumerator.nextObject() as? String {
      if file.hasSuffix(".swift") {
        files.append(directory + "/" + file)
      }
    }
    return files.sorted()
  }

  private static func collectCodeBlockVisitorNodeTypes(filePath: String) -> Set<String> {
    guard let source = try? String(contentsOfFile: filePath, encoding: .utf8) else {
      fatalError("Cannot read CodeBlockVisitor.swift")
    }
    let tree = Parser.parse(source: source)
    let collector = CodeBlockNodeCollector(viewMode: .sourceAccurate)
    collector.walk(tree)
    return collector.nodeTypes
  }
}

/// Collects the node types that CodeBlockVisitor handles via its visitPost overrides
private final class CodeBlockNodeCollector: SyntaxVisitor {
  var nodeTypes: Set<String> = []

  override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
    // Look for override func visitPost(_ node: XxxSyntax)
    if let name = node.name.text as String?,
      name == "visitPost",
      node.modifiers.contains(where: { $0.name.text == "override" }),
      let param = node.signature.parameterClause.parameters.first,
      let typeAnnotation = param.type.as(IdentifierTypeSyntax.self)
    {
      nodeTypes.insert(typeAnnotation.name.text)
    }
    return .skipChildren
  }
}
