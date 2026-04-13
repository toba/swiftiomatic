import Foundation
import SwiftParser
import SwiftSyntax

@main
struct GeneratePipeline {
  static func main() throws {
    let projectRoot = findProjectRoot()
    let rulesDir = projectRoot + "/Sources/SwiftiomaticKit/Rules"
    let syntaxDir = projectRoot + "/Sources/SwiftiomaticSyntax"
    let pipelineOutputPath =
      projectRoot + "/Sources/SwiftiomaticKit/Support/LintPipeline.generated.swift"
    let registryOutputPath =
      projectRoot + "/Sources/SwiftiomaticKit/Rules/RuleRegistry+AllRules.generated.swift"

    // Collect CodeBlockVisitor node types
    let codeBlockVisitorPath = syntaxDir + "/CodeBlockVisitor.swift"
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

      // Derive category/subcategory from directory path
      // e.g., Rules/Redundancy/Types/FooRule.swift → category "redundancy", subcategory "types"
      let (categoryName, subcategoryName) = Self.extractCategory(
        from: filePath, rulesDir: rulesDir)
      allRuleTypes.append(
        contentsOf: ruleTypes.map { info in
          var info = info
          info.categoryName = categoryName
          info.subcategoryName = subcategoryName
          return info
        })
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

  /// Extract category and subcategory from a rule file path.
  ///
  /// Given `rulesDir = ".../Rules"` and `filePath = ".../Rules/Redundancy/Types/FooRule.swift"`,
  /// returns `("redundancy", "types")`.
  private static func extractCategory(
    from filePath: String, rulesDir: String
  ) -> (category: String?, subcategory: String?) {
    // Get the relative path after the Rules/ directory
    let prefix = rulesDir + "/"
    guard filePath.hasPrefix(prefix) else { return (nil, nil) }
    let relative = String(filePath.dropFirst(prefix.count))
    let components = relative.split(separator: "/").map(String.init)
    // components: ["Redundancy", "Types", "FooRule.swift"]
    // or: ["Redundancy", "FooRule.swift"] (file directly in category)
    // or: ["FooRule.swift"] (file directly in Rules/)
    guard components.count >= 2 else { return (nil, nil) }
    let category = components[0].lowercased()
    let subcategory = components.count >= 3 ? components[1].lowercased() : nil
    return (category, subcategory)
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
