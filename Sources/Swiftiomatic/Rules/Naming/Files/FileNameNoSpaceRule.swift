import Foundation

struct FileNameNoSpaceRule: SyntaxOnlyRule {
  var options = FileNameNoSpaceOptions()

  static let description = RuleDescription(
    identifier: "file_name_no_space",
    name: "File Name no Space",
    description: "File name should not contain any whitespace",
      isOptIn: true,
  )

  func validate(file: SwiftSource) -> [RuleViolation] {
    guard let filePath = file.path,
      case let fileName = (filePath as NSString).lastPathComponent,
      !options.excluded.contains(fileName),
      fileName.rangeOfCharacter(from: .whitespaces) != nil
    else {
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
