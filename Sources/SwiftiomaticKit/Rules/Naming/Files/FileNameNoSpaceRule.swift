import Foundation

struct FileNameNoSpaceRule: Rule {
  static let id = "file_name_no_space"
  static let name = "File Name no Space"
  static let summary = "File name should not contain any whitespace"
  static let isOptIn = true
  static let requiresFileOnDisk = true
  var options = FileNameNoSpaceOptions()

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
        ruleType: Self.self,
        severity: options.severity,
        location: Location(file: filePath, line: 1),
      )
    ]
  }
}
