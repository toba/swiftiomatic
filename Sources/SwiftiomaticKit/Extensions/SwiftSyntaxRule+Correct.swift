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

    typealias CorrectionRange = (range: Range<String.Index>, correction: String)
    let correctionRanges =
      violations
      .filter {
        !$0.position.isContainedIn(
          regions: disabledRegions,
          locationConverter: locationConverter,
        )
      }
      .compactMap(\.correction)
      .compactMap { correction in
        file.stringView.stringRange(start: correction.start, end: correction.end)
          .map { range in
            CorrectionRange(range: range, correction: correction.replacement)
          }
      }
      .sorted { (lhs: CorrectionRange, rhs: CorrectionRange) -> Bool in
        lhs.range.lowerBound > rhs.range.lowerBound
      }
    guard correctionRanges.isNotEmpty else {
      return 0
    }

    var contents = file.contents
    for range in correctionRanges {
      contents.replaceSubrange(range.range, with: range.correction)
    }
    file.write(contents)
    return correctionRanges.count
  }
}
