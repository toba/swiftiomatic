//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation
import Swiftiomatic
@_spi(Rules) @_spi(Testing) import Swiftiomatic
import SwiftSyntax
import Testing

public typealias TestSourceLocation = Testing.SourceLocation

/// Creates and returns a new `Context` for use in tests.
@_spi(Testing)
public func makeTestContext(
  sourceFileSyntax: SourceFileSyntax,
  configuration: Configuration? = nil,
  selection: Selection,
  findingConsumer: @escaping (Finding) -> Void
) -> Context {
  Context(
    configuration: configuration ?? Configuration(),
    operatorTable: .standardOperators,
    findingConsumer: findingConsumer,
    fileURL: URL(fileURLWithPath: "/tmp/test.swift"),
    selection: selection,
    sourceFileSyntax: sourceFileSyntax,
    ruleNameCache: ruleNameCache
  )
}

/// Asserts that the given list of findings matches a set of specs.
@_spi(Testing)
public func assertFindings(
  expected specs: [FindingSpec],
  markerLocations: [String: Int],
  emittedFindings: [Finding],
  context: Context,
  sourceLocation: TestSourceLocation = #_sourceLocation
) {
  var emittedFindings = emittedFindings

  // Check for a finding that matches each spec, removing it from the array if found.
  for spec in specs {
    assertAndRemoveFinding(
      findingSpec: spec,
      markerLocations: markerLocations,
      emittedFindings: &emittedFindings,
      context: context,
      sourceLocation: sourceLocation
    )
  }

  // Emit test failures for any findings that did not have matches.
  for finding in emittedFindings {
    let locationString: String
    if let location = finding.location {
      locationString = "line:col \(location.line):\(location.column)"
    } else {
      locationString = "no location provided"
    }
    Issue.record(
      "Unexpected finding '\(finding.message)' was emitted (\(locationString))",
      sourceLocation: sourceLocation
    )
  }
}

private func assertAndRemoveFinding(
  findingSpec: FindingSpec,
  markerLocations: [String: Int],
  emittedFindings: inout [Finding],
  context: Context,
  sourceLocation: TestSourceLocation
) {
  guard let utf8Offset = markerLocations[findingSpec.marker] else {
    Issue.record(
      "Marker '\(findingSpec.marker)' was not found in the input",
      sourceLocation: sourceLocation
    )
    return
  }

  let markerLocation =
    context.sourceLocationConverter.location(for: AbsolutePosition(utf8Offset: utf8Offset))

  let maybeIndex = emittedFindings.firstIndex {
    markerLocation.line == $0.location?.line && markerLocation.column == $0.location?.column
  }
  guard let index = maybeIndex else {
    Issue.record(
      """
      Finding '\(findingSpec.message)' was not emitted at marker '\(findingSpec.marker)' \
      (line:col \(markerLocation.line):\(markerLocation.column), offset \(utf8Offset))
      """,
      sourceLocation: sourceLocation
    )
    return
  }

  let matchedFinding = emittedFindings.remove(at: index)
  #expect(
    matchedFinding.message.text == findingSpec.message,
    """
    Finding emitted at marker '\(findingSpec.marker)' \
    (line:col \(markerLocation.line):\(markerLocation.column), offset \(utf8Offset)) \
    had the wrong message
    """,
    sourceLocation: sourceLocation
  )

  // Assert that a note exists for each of the expected notes in the finding.
  var emittedNotes = matchedFinding.notes
  for noteSpec in findingSpec.notes {
    assertAndRemoveNote(
      noteSpec: noteSpec,
      markerLocations: markerLocations,
      emittedNotes: &emittedNotes,
      context: context,
      sourceLocation: sourceLocation
    )
  }

  // Emit test failures for any notes that weren't specified.
  for note in emittedNotes {
    let locationString: String
    if let location = note.location {
      locationString = "line:col \(location.line):\(location.column)"
    } else {
      locationString = "no location provided"
    }
    Issue.record(
      "Unexpected note '\(note.message)' was emitted (\(locationString))",
      sourceLocation: sourceLocation
    )
  }
}

private func assertAndRemoveNote(
  noteSpec: NoteSpec,
  markerLocations: [String: Int],
  emittedNotes: inout [Finding.Note],
  context: Context,
  sourceLocation: TestSourceLocation
) {
  guard let utf8Offset = markerLocations[noteSpec.marker] else {
    Issue.record(
      "Marker '\(noteSpec.marker)' was not found in the input",
      sourceLocation: sourceLocation
    )
    return
  }

  let markerLocation =
    context.sourceLocationConverter.location(for: AbsolutePosition(utf8Offset: utf8Offset))

  let maybeIndex = emittedNotes.firstIndex {
    markerLocation.line == $0.location?.line && markerLocation.column == $0.location?.column
  }
  guard let index = maybeIndex else {
    Issue.record(
      """
      Note '\(noteSpec.message)' was not emitted at marker '\(noteSpec.marker)' \
      (line:col \(markerLocation.line):\(markerLocation.column), offset \(utf8Offset))
      """,
      sourceLocation: sourceLocation
    )
    return
  }

  let matchedNote = emittedNotes.remove(at: index)
  #expect(
    matchedNote.message.text == noteSpec.message,
    """
    Note emitted at marker '\(noteSpec.marker)' \
    (line:col \(markerLocation.line):\(markerLocation.column), offset \(utf8Offset)) \
    had the wrong message
    """,
    sourceLocation: sourceLocation
  )
}

/// Asserts that the two strings are equal, providing Unix `diff`-style output if they are not.
@_spi(Testing)
public func assertStringsEqualWithDiff(
  _ actual: String,
  _ expected: String,
  _ message: String = "",
  sourceLocation: TestSourceLocation = #_sourceLocation
) {
  let actualLines = actual.components(separatedBy: .newlines)
  let expectedLines = expected.components(separatedBy: .newlines)

  let difference = actualLines.difference(from: expectedLines)
  if difference.isEmpty { return }

  var result = ""

  var insertions = [Int: String]()
  var removals = [Int: String]()

  for change in difference {
    switch change {
    case .insert(let offset, let element, _):
      insertions[offset] = element
    case .remove(let offset, let element, _):
      removals[offset] = element
    }
  }

  var expectedLine = 0
  var actualLine = 0

  while expectedLine < expectedLines.count || actualLine < actualLines.count {
    if let removal = removals[expectedLine] {
      result += "-\(removal)\n"
      expectedLine += 1
    } else if let insertion = insertions[actualLine] {
      result += "+\(insertion)\n"
      actualLine += 1
    } else {
      result += " \(expectedLines[expectedLine])\n"
      expectedLine += 1
      actualLine += 1
    }
  }

  let failureMessage = "Actual output (+) differed from expected output (-):\n\(result)"
  let fullMessage = message.isEmpty ? failureMessage : "\(message) - \(failureMessage)"
  Issue.record(Comment(rawValue: fullMessage), sourceLocation: sourceLocation)
}
