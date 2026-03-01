import Foundation

struct FileNameNoSpaceRule: OptInRule, SyntaxOnlyRule {
  var configuration = FileNameNoSpaceConfiguration()

  static let description = RuleDescription(
    identifier: "file_name_no_space",
    name: "File Name no Space",
    description: "File name should not contain any whitespace",
  )

  func validate(file: SwiftSource) -> [RuleViolation] {
    guard let filePath = file.path,
      case let fileName = filePath.bridge().lastPathComponent,
      !configuration.excluded.contains(fileName),
      fileName.rangeOfCharacter(from: .whitespaces) != nil
    else {
      return []
    }

    return [
      RuleViolation(
        ruleDescription: Self.description,
        severity: configuration.severity,
        location: Location(file: filePath, line: 1),
      )
    ]
  }
}
