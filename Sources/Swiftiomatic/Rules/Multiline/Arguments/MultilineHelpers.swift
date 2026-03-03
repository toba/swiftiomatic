import SwiftSyntax

func containsMultilineViolation(
    positions: [AbsolutePosition],
    locationConverter: SourceLocationConverter,
    allowsSingleLine: Bool,
    maxSingleLine: Int?,
) -> Bool {
    guard positions.isNotEmpty else { return false }

    var numberOfParameters = 0
    var linesWithParameters: Set<Int> = []
    var hasMultipleParametersOnSameLine = false

    for position in positions {
        let line = locationConverter.location(for: position).line
        if !linesWithParameters.insert(line).inserted {
            hasMultipleParametersOnSameLine = true
        }
        numberOfParameters += 1
    }

    if linesWithParameters.count == 1 {
        guard allowsSingleLine else {
            return numberOfParameters > 1
        }
        if let maxSingleLine {
            return numberOfParameters > maxSingleLine
        }
        return false
    }

    return hasMultipleParametersOnSameLine
}
