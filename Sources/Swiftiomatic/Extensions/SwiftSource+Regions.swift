import Foundation

extension SwiftSource {
  func regions(restrictingRuleIdentifiers: Set<RuleIdentifier>? = nil) -> [Region] {
    var regions = [Region]()
    var disabledRules = Set<RuleIdentifier>()
    let commands: [Command]
    if let restrictingRuleIdentifiers {
      commands = self.commands().filter { command in
        command.ruleIdentifiers.contains(where: restrictingRuleIdentifiers.contains)
      }
    } else {
      commands = self.commands()
    }
    let commandPairs = zip(commands, Array(commands.dropFirst().map(Optional.init)) + [nil])
    for (command, nextCommand) in commandPairs {
      switch command.action {
      case .disable:
        disabledRules.formUnion(command.ruleIdentifiers)

      case .enable:
        disabledRules.subtract(command.ruleIdentifiers)

      case .invalid:
        break
      }

      let start = Location(
        file: path,
        line: command.line,
        character: command.range?.upperBound,
      )
      let end = endOf(next: nextCommand)
      guard start < end else { continue }
      var didSetRegion = false
      for (index, region) in zip(regions.indices, regions)
      where region.start == start && region.end == end {
        regions[index] = Region(
          start: start,
          end: end,
          disabledRuleIdentifiers: disabledRules.union(region.disabledRuleIdentifiers),
        )
        didSetRegion = true
      }
      if !didSetRegion {
        regions.append(
          Region(start: start, end: end, disabledRuleIdentifiers: disabledRules),
        )
      }
    }
    return regions
  }

  func commands(in range: NSRange? = nil) -> [Command] {
    guard let range else {
      return
        commands
        .flatMap { $0.expand() }
    }

    let rangeStart = Location(file: self, characterOffset: range.location)
    let rangeEnd = Location(file: self, characterOffset: NSMaxRange(range))
    return
      commands
      .filter { command in
        let commandLocation = Location(
          file: path, line: command.line, character: command.range?.upperBound,
        )
        return rangeStart <= commandLocation && commandLocation <= rangeEnd
      }
      .flatMap { $0.expand() }
  }

  private func endOf(next command: Command?) -> Location {
    guard let nextCommand = command else {
      return Location(file: path, line: .max, character: .max)
    }
    let nextLine: Int
    let nextCharacter: Int?
    if let nextCommandCharacter = nextCommand.range?.upperBound {
      nextLine = nextCommand.line
      if nextCommandCharacter > 0 {
        nextCharacter = nextCommandCharacter - 1
      } else {
        nextCharacter = nil
      }
    } else {
      nextLine = max(nextCommand.line - 1, 0)
      nextCharacter = .max
    }
    return Location(file: path, line: nextLine, character: nextCharacter)
  }
}
