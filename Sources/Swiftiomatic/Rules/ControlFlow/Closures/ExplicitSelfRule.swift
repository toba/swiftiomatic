import Foundation

struct ExplicitSelfRule: CorrectableRule, AnalyzerRule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "explicit_self",
    name: "Explicit Self",
    description: "Instance variables and functions should be explicitly accessed with 'self.'",
    isOptIn: true,
    requiresSourceKit: true,
    requiresCompilerArguments: true,
    nonTriggeringExamples: ExplicitSelfRuleExamples.nonTriggeringExamples,
    triggeringExamples: ExplicitSelfRuleExamples.triggeringExamples,
    corrections: ExplicitSelfRuleExamples.corrections,
    requiresFileOnDisk: true,
  )

  func validate(file: SwiftSource, compilerArguments: [String]) -> [RuleViolation] {
    violationRanges(in: file, compilerArguments: compilerArguments).map {
      RuleViolation(
        ruleDescription: Self.description,
        severity: configuration.severity,
        location: Location(file: file, characterOffset: $0.location),
      )
    }
  }

  func correct(file: SwiftSource, compilerArguments: [String]) -> Int {
    let violations = violationRanges(in: file, compilerArguments: compilerArguments)
    let matches = file.ruleEnabled(violatingRanges: violations, for: self)
    if matches.isEmpty {
      return 0
    }
    var contents = file.contents as NSString
    for range in matches.reversed() {
      contents = contents.replacingCharacters(in: range, with: "self.") as NSString
    }
    file.write(contents as String)
    return matches.count
  }

  private func violationRanges(in file: SwiftSource, compilerArguments: [String]) -> [NSRange] {
    guard compilerArguments.isNotEmpty else {
      SwiftiomaticError.missingCompilerArguments(path: file.path, ruleID: Self.identifier).print()
      return []
    }

    let allCursorInfo: [[String: SourceKitValue]]
    do {
      let byteOffsets = try binaryOffsets(file: file, compilerArguments: compilerArguments)
      allCursorInfo = try file.allCursorInfo(
        compilerArguments: compilerArguments,
        atByteOffsets: byteOffsets,
      )
    } catch {
      Console.printError(String(describing: error))
      return []
    }

    let cursorsMissingExplicitSelf = allCursorInfo.filter { cursorInfo in
      guard let kindString = cursorInfo["key.kind"]?.stringValue else { return false }
      return kindsToFind.contains(kindString)
    }

    guard cursorsMissingExplicitSelf.isNotEmpty else {
      return []
    }

    let contents = file.stringView

    return cursorsMissingExplicitSelf.compactMap { cursorInfo in
      guard
        let byteOffset = cursorInfo["swiftlint.offset"]?.int64Value
          .flatMap(ByteCount.init)
      else {
        SwiftiomaticError.genericWarning("Cannot convert offsets in '\(Self.identifier)' rule.").print()
        return nil
      }

      return contents.byteRangeToNSRange(ByteRange(location: byteOffset, length: 0))
    }
  }
}

private let kindsToFind: Set = [
  "source.lang.swift.ref.function.method.instance",
  "source.lang.swift.ref.var.instance",
]

extension SwiftSource {
  fileprivate func allCursorInfo(
    compilerArguments: [String], atByteOffsets byteOffsets: [ByteCount],
  ) throws
    -> [[String: SourceKitValue]]
  {
    try byteOffsets.compactMap { offset in
      if isExplicitAccess(at: offset) { return nil }
      let cursorInfoRequest = Request.cursorInfoWithoutSymbolGraph(
        file: self.path!, offset: offset, arguments: compilerArguments,
      )
      var cursorInfo = try cursorInfoRequest.sendIfNotDisabled()

      // Accessing a `projectedValue` of a property wrapper (e.g. `self.$foo`) or the property wrapper itself
      // (e.g. `self._foo`) results in an incorrect `key.length` (it does not account for the identifier
      // prefixes `$` and `_`), while `key.name` contains the prefix. Hence we need to check for explicit access
      // at a corrected offset as well.
      var prefixLength: Int64 = 0
      let sourceKittenDictionary = SourceKitDictionary(cursorInfo)
      if sourceKittenDictionary.kind == "source.lang.swift.ref.var.instance",
        let name = sourceKittenDictionary.name,
        let length = sourceKittenDictionary.length
      {
        prefixLength = Int64(name.count - length.value)
        if prefixLength > 0, isExplicitAccess(at: offset - ByteCount(prefixLength)) {
          return nil
        }
      }

      cursorInfo["swiftlint.offset"] = .int64(Int64(offset.value) - prefixLength)
      return cursorInfo
    }
  }

  private func isExplicitAccess(at location: ByteCount) -> Bool {
    stringView.substringWithByteRange(ByteRange(location: location - 1, length: 1))! == "."
  }
}

extension StringView {
  fileprivate func recursiveByteOffsets(_ dict: [String: SourceKitValue]) -> [ByteCount] {
    let cur: [ByteCount]
    if let line = dict["key.line"]?.int64Value,
      let column = dict["key.column"]?.int64Value,
      let kindString = dict["key.kind"]?.stringValue,
      kindsToFind.contains(kindString),
      let offset = byteOffset(forLine: line, bytePosition: column)
    {
      cur = [offset]
    } else {
      cur = []
    }
    if let entities = dict["key.entities"]?.arrayValue {
      return entities.compactMap(\.dictionaryValue).flatMap(recursiveByteOffsets) + cur
    }
    return cur
  }
}

private func binaryOffsets(file: SwiftSource, compilerArguments: [String]) throws(Request.Error)
  -> [ByteCount]
{
  let absoluteFile = file.path!.absolutePathRepresentation()
  let index = try Request.index(file: absoluteFile, arguments: compilerArguments)
    .sendIfNotDisabled()
  let binaryOffsets = file.stringView.recursiveByteOffsets(index)
  return binaryOffsets.sorted()
}
