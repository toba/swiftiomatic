import SwiftiomaticSyntax

extension SwiftSyntaxRule {
  func correct(file: SwiftSource) -> Int {
    guard Self.isCorrectable else { return 0 }
    guard let syntaxTree = preprocess(file: file) else {
      return 0
    }
    if let rewriter = makeRewriter(file: file) {
      let newTree = rewriter.visit(syntaxTree)
      file.write(newTree.description)
      return rewriter.numberOfCorrections
    }

    // There is no rewriter. Falling back to the correction ranges collected by the visitor (if any).
    let violations = makeVisitor(file: file)
      .walk(tree: syntaxTree, handler: \.violations)
    guard violations.isNotEmpty else {
      return 0
    }

    let locationConverter = file.locationConverter
    let disabledRegions = file.regions()
      .filter { $0.areRulesDisabled(ruleIDs: Self.allIdentifiers) }
      .compactMap { $0.toSourceRange(locationConverter: locationConverter) }

    // Resolve corrections to UTF-8 offset edits.
    let edits =
      violations
      .filter {
        !$0.position.isContainedIn(
          regions: disabledRegions,
          locationConverter: locationConverter,
        )
      }
      .compactMap(\.correction)
      .compactMap { correction -> CorrectionEdit? in
        guard let resolved = correction.resolved else { return nil }
        return CorrectionEdit(
          start: resolved.start,
          end: resolved.end,
          replacement: resolved.replacement,
        )
      }
    guard edits.isNotEmpty else {
      return 0
    }

    let (result, applied) = CorrectionApplicator.apply(edits: edits, to: file.contents)
    file.write(result)
    return applied
  }
}

/// A UTF-8 offset edit used by the conflict-aware correction applicator.
package struct CorrectionEdit {
  package var startOffset: Int
  package var endOffset: Int
  package var replacement: String

  package var isEmpty: Bool { startOffset == endOffset && replacement.isEmpty }

  package static let empty = CorrectionEdit(startOffset: 0, endOffset: 0, replacement: "")

  package init(startOffset: Int, endOffset: Int, replacement: String) {
    self.startOffset = startOffset
    self.endOffset = endOffset
    self.replacement = replacement
  }

  init(start: AbsolutePosition, end: AbsolutePosition, replacement: String) {
    self.startOffset = start.utf8Offset
    self.endOffset = end.utf8Offset
    self.replacement = replacement
  }
}

/// Conflict-aware edit applicator ported from swift-syntax `FixItApplier`.
///
/// Applies edits in source order. Overlapping later edits are dropped;
/// non-overlapping subsequent edits have their positions shifted by the
/// delta of each applied edit.
package enum CorrectionApplicator {
  /// Apply edits to `source`, returning the modified string and the count of applied edits.
  package static func apply(edits inputEdits: [CorrectionEdit], to source: String) -> (result: String, applied: Int) {
    var edits = inputEdits.sorted { $0.startOffset < $1.startOffset }
    var source = source
    var applied = 0

    for editIndex in edits.indices {
      let edit = edits[editIndex]
      guard !edit.isEmpty else { continue }

      let utf8 = source.utf8
      let startIndex = utf8.index(utf8.startIndex, offsetBy: edit.startOffset)
      let endIndex = utf8.index(utf8.startIndex, offsetBy: edit.endOffset)
      source.replaceSubrange(startIndex..<endIndex, with: edit.replacement)
      applied += 1

      var nextIndex = editIndex
      while edits.formIndex(after: &nextIndex) != edits.endIndex {
        let remaining = edits[nextIndex]
        guard !remaining.isEmpty else { continue }

        let overlaps =
          edit.endOffset > remaining.startOffset
          && edit.startOffset < remaining.endOffset

        if overlaps {
          edits[nextIndex] = .empty
          continue
        }

        if edit.endOffset <= remaining.startOffset {
          let shift = edit.replacement.utf8.count - (edit.endOffset - edit.startOffset)
          edits[nextIndex] = CorrectionEdit(
            startOffset: remaining.startOffset + shift,
            endOffset: remaining.endOffset + shift,
            replacement: remaining.replacement,
          )
        }
      }
    }

    return (source, applied)
  }
}

private extension Collection {
  func formIndex(after index: inout Index) -> Index {
    formIndex(after: &index) as Void
    return index
  }
}
