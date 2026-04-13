import Testing

@testable import SwiftiomaticKit

@Suite struct CorrectionApplicatorTests {
  @Test func nonOverlappingEditsApplyAndShift() {
    // Two non-overlapping replacements: "aa" at [0,2) and "bb" at [4,6)
    // Source: "xxyyzzww"  →  replace [0,2) with "aa", [4,6) with "bb"
    let edits = [
      CorrectionEdit(startOffset: 0, endOffset: 2, replacement: "aa"),
      CorrectionEdit(startOffset: 4, endOffset: 6, replacement: "bb"),
    ]
    let (result, applied) = CorrectionApplicator.apply(edits: edits, to: "xxyyzzww")
    #expect(result == "aayybbww")
    #expect(applied == 2)
  }

  @Test func overlappingEditDropsLaterConflict() {
    // Two edits overlap: [0,4) and [2,6) — second should be dropped
    let edits = [
      CorrectionEdit(startOffset: 0, endOffset: 4, replacement: "AAAA"),
      CorrectionEdit(startOffset: 2, endOffset: 6, replacement: "BBBB"),
    ]
    let (result, applied) = CorrectionApplicator.apply(edits: edits, to: "abcdefgh")
    #expect(result == "AAAAefgh")
    #expect(applied == 1)
  }

  @Test func subsequentEditsShiftedByDelta() {
    // Replace [0,2) with "X" (shrinks by 1), then [4,6) with "YY"
    // After first edit: source shrinks by 1 byte, so second edit shifts to [3,5)
    let edits = [
      CorrectionEdit(startOffset: 0, endOffset: 2, replacement: "X"),
      CorrectionEdit(startOffset: 4, endOffset: 6, replacement: "YY"),
    ]
    let (result, applied) = CorrectionApplicator.apply(edits: edits, to: "aabbccdd")
    #expect(result == "XbbYYdd")
    #expect(applied == 2)
  }

  @Test func growingEditShiftsSubsequent() {
    // Replace [0,1) with "XXX" (grows by 2), then [3,4) with "Y"
    // After first edit: source grows by 2 bytes, so second edit shifts to [5,6)
    let edits = [
      CorrectionEdit(startOffset: 0, endOffset: 1, replacement: "XXX"),
      CorrectionEdit(startOffset: 3, endOffset: 4, replacement: "Y"),
    ]
    let (result, applied) = CorrectionApplicator.apply(edits: edits, to: "abcd")
    #expect(result == "XXXbcY")
    #expect(applied == 2)
  }

  @Test func adjacentEditsDoNotConflict() {
    // Edit [0,2) and [2,4) — adjacent, not overlapping
    let edits = [
      CorrectionEdit(startOffset: 0, endOffset: 2, replacement: "AA"),
      CorrectionEdit(startOffset: 2, endOffset: 4, replacement: "BB"),
    ]
    let (result, applied) = CorrectionApplicator.apply(edits: edits, to: "abcd")
    #expect(result == "AABB")
    #expect(applied == 2)
  }

  @Test func emptyEditsAreSkipped() {
    let edits = [
      CorrectionEdit.empty,
      CorrectionEdit(startOffset: 0, endOffset: 1, replacement: "X"),
    ]
    let (result, applied) = CorrectionApplicator.apply(edits: edits, to: "ab")
    #expect(result == "Xb")
    #expect(applied == 1)
  }

  @Test func unsortedEditsAreSortedBeforeApplication() {
    // Edits given in reverse order — applicator should sort them
    let edits = [
      CorrectionEdit(startOffset: 4, endOffset: 6, replacement: "YY"),
      CorrectionEdit(startOffset: 0, endOffset: 2, replacement: "XX"),
    ]
    let (result, applied) = CorrectionApplicator.apply(edits: edits, to: "aabbccdd")
    #expect(result == "XXbbYYdd")
    #expect(applied == 2)
  }

  @Test func insertionInsideReplacementIsDropped() {
    // Replace [0,4) with "XXXX", insertion at [2,2) is strictly inside — dropped
    let edits = [
      CorrectionEdit(startOffset: 0, endOffset: 4, replacement: "XXXX"),
      CorrectionEdit(startOffset: 2, endOffset: 2, replacement: "I"),
    ]
    let (result, applied) = CorrectionApplicator.apply(edits: edits, to: "abcdef")
    #expect(result == "XXXXef")
    #expect(applied == 1)
  }
}
