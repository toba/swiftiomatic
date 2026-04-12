import Foundation
import SwiftParser
import SwiftSyntax

/// Information about a single rule extracted from its source file
struct RuleInfo {
  let ruleTypeName: String
  let ruleID: String
  let visitNodeTypes: Set<String>
  let visitPostNodeTypes: Set<String>
  let isPipelineEligible: Bool
}

/// Minimal info about any rule type (for registry generation)
struct RuleTypeInfo {
  let typeName: String
  let ruleID: String
}

/// Parses rule source files to extract visitor override information
enum RuleCollector {
  /// Collect all rules defined in the given source file
  static func collectRules(
    from filePath: String,
    codeBlockNodeTypes: Set<String>,
  ) -> (rules: [RuleInfo], ruleTypes: [RuleTypeInfo]) {
    guard let source = try? String(contentsOfFile: filePath, encoding: .utf8) else {
      return ([], [])
    }
    let tree = Parser.parse(source: source)
    let collector = RuleFileVisitor(
      viewMode: .sourceAccurate,
      codeBlockNodeTypes: codeBlockNodeTypes,
    )
    collector.walk(tree)
    return (collector.rules, collector.ruleTypes)
  }
}

/// Visits a rule source file to extract rule type names, IDs, and visitor overrides
private final class RuleFileVisitor: SyntaxVisitor {
  let codeBlockNodeTypes: Set<String>
  var rules: [RuleInfo] = []
  var ruleTypes: [RuleTypeInfo] = []

  // Track which struct conforms to SwiftSyntaxRule
  private var ruleStructs: [String: RuleStructInfo] = [:]
  // Track visitor classes and their parent class + overrides
  private var visitorClasses: [String: VisitorClassInfo] = [:]
  // Track which struct contains which visitor class (via extensions)
  private var currentExtensionType: String?

  init(viewMode: SyntaxTreeViewMode, codeBlockNodeTypes: Set<String>) {
    self.codeBlockNodeTypes = codeBlockNodeTypes
    super.init(viewMode: viewMode)
  }

  override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    let name = node.name.text
    // Look for static let id = "..."
    if let id = extractStaticStringProperty(from: node.memberBlock, named: "id") {
      let conformances =
        node.inheritanceClause?.inheritedTypes
        .map(\.type.trimmedDescription) ?? []
      ruleStructs[name] = RuleStructInfo(
        typeName: name,
        ruleID: id,
        hasPreprocessOverride: false,
        isCollecting: conformances.contains(where: { $0.contains("CollectingRule") }),
        isAnalyzer: extractStaticBoolProperty(
          from: node.memberBlock, named: "requiresCompilerArguments") ?? false,
        isSourceKitAST: conformances.contains("SourceKitASTRule"),
        requiresPostProcessing: extractStaticBoolProperty(
          from: node.memberBlock, named: "requiresPostProcessing") ?? false,
        conformsToSwiftSyntaxRule: conformances.contains("SwiftSyntaxRule"),
      )
    }
    return .visitChildren
  }

  override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
    let extendedType = node.extendedType.trimmedDescription
    currentExtensionType = extendedType

    // Check for protocol conformances
    if let inheritanceClause = node.inheritanceClause {
      let conformances = inheritanceClause.inheritedTypes.map(\.type.trimmedDescription)
      if var info = ruleStructs[extendedType] {
        for conformance in conformances {
          if conformance == "SwiftSyntaxRule" {
            info.conformsToSwiftSyntaxRule = true
          }
          if conformance == "SourceKitASTRule" {
            info.isSourceKitAST = true
          }
          if conformance.contains("CollectingRule") {
            info.isCollecting = true
          }
        }
        ruleStructs[extendedType] = info
      }
    }

    // Check for preprocess override in extension
    for member in node.memberBlock.members {
      if let funcDecl = member.decl.as(FunctionDeclSyntax.self),
        funcDecl.name.text == "preprocess"
      {
        if var info = ruleStructs[extendedType] {
          info.hasPreprocessOverride = true
          ruleStructs[extendedType] = info
        }
      }
    }

    return .visitChildren
  }

  override func visitPost(_: ExtensionDeclSyntax) {
    currentExtensionType = nil
  }

  override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    let className = node.name.text

    // Determine parent class
    var parentClassName: String?
    if let inheritanceClause = node.inheritanceClause {
      for inherited in inheritanceClause.inheritedTypes {
        let typeName = inherited.type.trimmedDescription
        // Extract just the base type name, stripping generic parameters
        let baseName: String
        if let angleBracketIndex = typeName.firstIndex(of: "<") {
          baseName = String(typeName[typeName.startIndex..<angleBracketIndex])
        } else {
          baseName = typeName
        }
        if baseName == "ViolationCollectingVisitor"
          || baseName == "CodeBlockVisitor"
          || baseName == "BodyLengthVisitor"
        {
          parentClassName = baseName
          break
        }
      }
    }

    guard let parent = parentClassName else {
      return .visitChildren
    }

    var visitNodeTypes: Set<String> = []
    var visitPostNodeTypes: Set<String> = []

    // If it extends CodeBlockVisitor, include all code block node types
    if parent == "CodeBlockVisitor" {
      visitPostNodeTypes = codeBlockNodeTypes
    }

    // Scan methods for visitor overrides
    for member in node.memberBlock.members {
      if let funcDecl = member.decl.as(FunctionDeclSyntax.self),
        funcDecl.modifiers.contains(where: { $0.name.text == "override" })
      {
        let funcName = funcDecl.name.text
        if let param = funcDecl.signature.parameterClause.parameters.first,
          let typeAnnotation = param.type.as(IdentifierTypeSyntax.self)
        {
          let nodeType = typeAnnotation.name.text
          if funcName == "visit" {
            visitNodeTypes.insert(nodeType)
          } else if funcName == "visitPost" {
            visitPostNodeTypes.insert(nodeType)
          }
        }
      }
    }

    // Associate with enclosing rule struct
    let enclosingType = currentExtensionType
    visitorClasses[className] = VisitorClassInfo(
      className: className,
      parentClassName: parent,
      enclosingRuleType: enclosingType,
      visitNodeTypes: visitNodeTypes,
      visitPostNodeTypes: visitPostNodeTypes,
    )

    return .skipChildren
  }

  override func visitPost(_: SourceFileSyntax) {
    // Build final rule infos by matching visitors to rule structs
    for (_, visitorInfo) in visitorClasses {
      guard let enclosingType = visitorInfo.enclosingRuleType,
        let ruleInfo = ruleStructs[enclosingType]
      else {
        continue
      }

      // Only consider rules that conform to SwiftSyntaxRule
      guard ruleInfo.conformsToSwiftSyntaxRule else { continue }

      // Determine pipeline eligibility
      let eligible =
        !ruleInfo.hasPreprocessOverride
        && !ruleInfo.isCollecting
        && !ruleInfo.isAnalyzer
        && !ruleInfo.isSourceKitAST
        && !ruleInfo.requiresPostProcessing

      // Merge visit/visitPost node types from the base class handling in
      // ViolationCollectingVisitor (the 10 skippable declaration types are
      // handled there, not in individual rules)
      let visitNodeTypes = visitorInfo.visitNodeTypes
      let visitPostNodeTypes = visitorInfo.visitPostNodeTypes

      // The pipeline handles skippableDeclarations separately, so we need to
      // keep all visit() overrides that rules have added beyond the base class.
      // However, if a rule just relies on ViolationCollectingVisitor's default
      // skip behavior, those visit() methods don't need to be in the rule's
      // own set. The pipeline will generate skip handling for all rules.

      // For CodeBlockVisitor subclasses that also override visitPost for
      // declaration types (like OpeningBraceRule overriding visitPost for
      // ActorDeclSyntax etc.), we keep those since they have rule-specific logic
      // beyond what CodeBlockVisitor provides.

      rules.append(
        RuleInfo(
          ruleTypeName: enclosingType,
          ruleID: ruleInfo.ruleID,
          visitNodeTypes: visitNodeTypes,
          visitPostNodeTypes: visitPostNodeTypes,
          isPipelineEligible: eligible,
        ))
    }

    // Emit all rule types (any struct with static let id) for registry generation
    for (_, structInfo) in ruleStructs {
      ruleTypes.append(
        RuleTypeInfo(
          typeName: structInfo.typeName,
          ruleID: structInfo.ruleID,
        ))
    }
  }

  private func extractStaticStringProperty(
    from memberBlock: MemberBlockSyntax,
    named propertyName: String,
  ) -> String? {
    for member in memberBlock.members {
      if let varDecl = member.decl.as(VariableDeclSyntax.self),
        varDecl.modifiers.contains(where: { $0.name.text == "static" }),
        let binding = varDecl.bindings.first,
        let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
        pattern.identifier.text == propertyName,
        let initializer = binding.initializer,
        let stringLiteral = initializer.value.as(StringLiteralExprSyntax.self),
        let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self)
      {
        return segment.content.text
      }
    }
    return nil
  }

  private func extractStaticBoolProperty(
    from memberBlock: MemberBlockSyntax,
    named propertyName: String,
  ) -> Bool? {
    for member in memberBlock.members {
      if let varDecl = member.decl.as(VariableDeclSyntax.self),
        varDecl.modifiers.contains(where: { $0.name.text == "static" }),
        let binding = varDecl.bindings.first,
        let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
        pattern.identifier.text == propertyName,
        let initializer = binding.initializer,
        let boolLiteral = initializer.value.as(BooleanLiteralExprSyntax.self)
      {
        return boolLiteral.literal.text == "true"
      }
    }
    return nil
  }
}

private struct RuleStructInfo {
  let typeName: String
  let ruleID: String
  var hasPreprocessOverride: Bool
  var isCollecting: Bool
  var isAnalyzer: Bool
  var isSourceKitAST: Bool
  var requiresPostProcessing: Bool
  var conformsToSwiftSyntaxRule: Bool
}

private struct VisitorClassInfo {
  let className: String
  let parentClassName: String
  let enclosingRuleType: String?
  let visitNodeTypes: Set<String>
  let visitPostNodeTypes: Set<String>
}
