import Foundation
import SwiftSyntax

struct FileNameRule: SyntaxOnlyRule {
  var options = FileNameOptions()

  static let description = RuleDescription(
    identifier: "file_name",
    name: "File Name",
    description: "File name should match a type or extension declared in the file (if any)",
      isOptIn: true,
  )

  func validate(file: SwiftSource) -> [RuleViolation] {
    guard let filePath = file.path,
      !options.shouldExclude(filePath: filePath)
    else {
      return []
    }

    let prefixRegex = regex("\\A(?:\(options.prefixPattern))")
    let suffixRegex = regex("(?:\(options.suffixPattern))\\z")

    let fileName = (filePath as NSString).lastPathComponent
    var typeInFileName = (fileName as NSString).deletingPathExtension

    // Process prefix
    if let match = prefixRegex.firstMatch(
      in: typeInFileName, range: typeInFileName.fullNSRange,
    ),
      let range = typeInFileName.nsRangeToIndexRange(NSRange(match.range, in: typeInFileName))
    {
      typeInFileName.removeSubrange(range)
    }

    // Process suffix
    if let match = suffixRegex.firstMatch(
      in: typeInFileName, range: typeInFileName.fullNSRange,
    ),
      let range = typeInFileName.nsRangeToIndexRange(NSRange(match.range, in: typeInFileName))
    {
      typeInFileName.removeSubrange(range)
    }

    // Process nested type separator
    let allDeclaredTypeNames = TypeNameCollectingVisitor(
      requireFullyQualifiedNames: options.requireFullyQualifiedNames,
    )
    .walk(tree: file.syntaxTree, handler: \.names)
    .map {
      $0.replacingOccurrences(of: ".", with: options.nestedTypeSeparator)
    }

    guard allDeclaredTypeNames.isNotEmpty, !allDeclaredTypeNames.contains(typeInFileName) else {
      return []
    }

    return [
      RuleViolation(
        ruleDescription: Self.description,
        severity: options.severity,
        location: Location(file: filePath, line: 1),
      )
    ]
  }
}

private final class TypeNameCollectingVisitor: SyntaxVisitor {
  /// All of a visited node's ancestor type names if that node is nested, starting with the furthest
  /// ancestor and ending with the direct parent
  private var ancestorNames = Stack<String>()

  /// All of the type names found in the file
  private(set) var names: Set<String> = []

  /// If true, nested types are only allowed in the file name when used by their fully-qualified name
  /// (e.g. `My.Nested.Type` and not just `Type`)
  private let requireFullyQualifiedNames: Bool

  init(requireFullyQualifiedNames: Bool) {
    self.requireFullyQualifiedNames = requireFullyQualifiedNames
    super.init(viewMode: .sourceAccurate)
  }

  /// Calls `visit(name:)` using the name of the provided node
  private func visit(node: some NamedDeclSyntax) -> SyntaxVisitorContinueKind {
    visit(name: node.name.trimmedDescription)
  }

  /// Visits a node with the provided name, storing that name as an ancestor type name to prepend to
  /// any children to form their fully-qualified names
  private func visit(name: String) -> SyntaxVisitorContinueKind {
    let fullyQualifiedName = (ancestorNames + [name]).joined(separator: ".")
    names.insert(fullyQualifiedName)

    // If the options don't require only fully-qualified names, then we will allow this node's
    // name to be used by itself
    if !requireFullyQualifiedNames {
      names.insert(name)
    }

    ancestorNames.push(name)
    return .visitChildren
  }

  override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    visit(node: node)
  }

  override func visitPost(_: ClassDeclSyntax) {
    ancestorNames.pop()
  }

  override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
    visit(node: node)
  }

  override func visitPost(_: ActorDeclSyntax) {
    ancestorNames.pop()
  }

  override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    visit(node: node)
  }

  override func visitPost(_: StructDeclSyntax) {
    ancestorNames.pop()
  }

  override func visit(_ node: TypeAliasDeclSyntax) -> SyntaxVisitorContinueKind {
    visit(node: node)
  }

  override func visitPost(_: TypeAliasDeclSyntax) {
    ancestorNames.pop()
  }

  override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    visit(node: node)
  }

  override func visitPost(_: EnumDeclSyntax) {
    ancestorNames.pop()
  }

  override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
    visit(node: node)
  }

  override func visitPost(_: ProtocolDeclSyntax) {
    ancestorNames.pop()
  }

  override func visit(_ node: MacroDeclSyntax) -> SyntaxVisitorContinueKind {
    visit(node: node)
  }

  override func visitPost(_: MacroDeclSyntax) {
    ancestorNames.pop()
  }

  override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
    visit(name: node.extendedType.trimmedDescription)
  }

  override func visitPost(_: ExtensionDeclSyntax) {
    ancestorNames.pop()
  }
}
