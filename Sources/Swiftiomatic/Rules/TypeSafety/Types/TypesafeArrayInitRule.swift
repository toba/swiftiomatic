import Foundation

struct TypesafeArrayInitRule: AnalyzerRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = TypesafeArrayInitConfiguration()

  private static let parentRule = ArrayInitRule()
  private static let mapTypePatterns = [
    regex(
      """
      \\Q<Self, T where Self : \\E(?:Sequence|Collection)> \
      \\Q(Self) -> ((Self.Element) throws -> T) throws -> [T]\\E
      """,
    ),
    regex(
      """
      \\Q<Self, T, E where Self : \\E(?:Sequence|Collection), \
      \\QE : Error> (Self) -> ((Self.Element) throws(E) -> T) throws(E) -> [T]\\E
      """,
    ),
  ]

  func validate(file: SwiftSource, compilerArguments: [String]) -> [RuleViolation] {
    guard let filePath = file.path else {
      return []
    }
    guard compilerArguments.isNotEmpty else {
      SwiftiomaticError.missingCompilerArguments(path: file.path, ruleID: Self.identifier).print()
      return []
    }
    return Self.parentRule.validate(file: file)
      .filter { violation in
        guard let offset = getOffset(in: file, at: violation.location) else {
          return false
        }
        let cursorInfo = Request.cursorInfoWithoutSymbolGraph(
          file: filePath, offset: offset, arguments: compilerArguments,
        )
        guard let request = try? cursorInfo.sendIfNotDisabled() else {
          return false
        }
        return pointsToSystemMapType(pointee: request)
      }.map { RuleViolation(ruleDescription: Self.description, location: $0.location) }
  }

  private func pointsToSystemMapType(pointee: [String: SourceKitValue]) -> Bool {
    if pointee["key.is_system"]?.boolValue == true,
      pointee["key.name"]?.stringValue == "map(_:)",
      let typeName = pointee["key.typename"]?.stringValue
    {
      return Self.mapTypePatterns.contains { pattern in
        pattern.hasMatch(in: typeName, range: typeName.fullNSRange)
      }
    }
    return false
  }

  private func getOffset(in file: SwiftSource, at location: Location) -> ByteCount? {
    guard let line = location.line, let offset = location.column else {
      return nil
    }
    return file.stringView.byteOffset(forLine: Int64(line), bytePosition: Int64(offset))
  }
}
