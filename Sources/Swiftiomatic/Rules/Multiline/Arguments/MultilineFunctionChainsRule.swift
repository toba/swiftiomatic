import Foundation

struct MultilineFunctionChainsRule: SourceKitASTRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = MultilineFunctionChainsConfiguration()

  func validate(
    file: SwiftSource,
    kind: ExpressionKind,
    dictionary: SourceKitDictionary,
  ) -> [RuleViolation] {
    violatingOffsets(file: file, kind: kind, dictionary: dictionary).map { offset in
      RuleViolation(
        configuration: Self.configuration,
        severity: options.severity,
        location: Location(file: file, characterOffset: offset),
      )
    }
  }

  private func violatingOffsets(
    file: SwiftSource,
    kind: ExpressionKind,
    dictionary: SourceKitDictionary,
  ) -> [Int] {
    let ranges = callRanges(file: file, kind: kind, dictionary: dictionary)

    let calls = ranges.compactMap {
      range -> (
        dotLine: Int,
        dotOffset: Int,
        range: ByteRange
      )? in
      guard let offset = callDotOffset(file: file, callRange: range),
        let line = file.stringView.lineAndCharacter(forCharacterOffset: offset)?.line
      else {
        return nil
      }
      return (dotLine: line, dotOffset: offset, range: range)
    }

    let uniqueLines = calls.map(\.dotLine).unique

    if uniqueLines.count == 1 { return [] }

    // The first call (last here) is allowed to not have a leading newline.
    let noLeadingNewlineViolations =
      calls
      .dropLast()
      .filter { line in
        !callHasLeadingNewline(file: file, callRange: line.range)
      }

    return noLeadingNewlineViolations.map(\.dotOffset)
  }

  private static let whitespaceDotRegex: CachedRegex = "\\s*\\."

  private func callDotOffset(file: SwiftSource, callRange: ByteRange) -> Int? {
    guard let range = file.stringView.byteRangeToNSRange(callRange),
      let match = Self.whitespaceDotRegex.matches(in: file.contents, range: range).last
    else {
      return nil
    }
    let matchNSRange = NSRange(match.range, in: file.contents)
    return matchNSRange.location + matchNSRange.length - 1
  }

  private static let newlineWhitespaceDotRegex: CachedRegex = "\\n\\s*\\."

  private func callHasLeadingNewline(file: SwiftSource, callRange: ByteRange) -> Bool {
    guard let range = file.stringView.byteRangeToNSRange(callRange) else {
      return false
    }
    return Self.newlineWhitespaceDotRegex.firstMatch(in: file.contents, range: range) != nil
  }

  private func callRanges(
    file: SwiftSource,
    kind: ExpressionKind,
    dictionary: SourceKitDictionary,
    parentCallName: String? = nil,
  ) -> [ByteRange] {
    guard
      kind == .call,
      case let contents = file.stringView,
      let offset = dictionary.nameOffset,
      let length = dictionary.nameLength,
      case let nameByteRange = ByteRange(location: offset, length: length),
      let name = contents.substringWithByteRange(nameByteRange)
    else {
      return []
    }

    let subcalls = dictionary.subcalls

    if subcalls.isEmpty, let parentCallName, parentCallName.starts(with: name) {
      return [ByteRange(location: offset, length: length)]
    }

    return subcalls.flatMap { call -> [ByteRange] in
      // Bail out early if there's no subcall, since this means there's no chain.
      guard
        let range = subcallRange(
          file: file,
          call: call,
          parentName: name,
          parentNameOffset: offset,
        )
      else {
        return []
      }

      return [range]
        + callRanges(
          file: file,
          kind: .call,
          dictionary: call,
          parentCallName: name,
        )
    }
  }

  private func subcallRange(
    file: SwiftSource,
    call: SourceKitDictionary,
    parentName: String,
    parentNameOffset: ByteCount,
  ) -> ByteRange? {
    guard case let contents = file.stringView,
      let nameOffset = call.nameOffset,
      parentNameOffset == nameOffset,
      let nameLength = call.nameLength,
      let bodyOffset = call.bodyOffset,
      let bodyLength = call.bodyLength,
      case let nameByteRange = ByteRange(location: nameOffset, length: nameLength),
      let name = contents.substringWithByteRange(nameByteRange),
      parentName.starts(with: name)
    else {
      return nil
    }

    let nameEndOffset = nameOffset + nameLength
    let nameLengthDifference = ByteCount(parentName.lengthOfBytes(using: .utf8)) - nameLength
    let offsetDifference = bodyOffset - nameEndOffset

    return ByteRange(
      location: nameEndOffset + offsetDifference + bodyLength,
      length: nameLengthDifference - bodyLength - offsetDifference,
    )
  }
}

extension SourceKitDictionary {
  fileprivate var subcalls: [SourceKitDictionary] {
    substructure.compactMap { dictionary -> SourceKitDictionary? in
      guard dictionary.expressionKind == .call else {
        return nil
      }
      return dictionary
    }
  }
}
