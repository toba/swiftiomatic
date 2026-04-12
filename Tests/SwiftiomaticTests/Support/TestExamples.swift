
@testable import SwiftiomaticKit
@testable import SwiftiomaticSyntax

/// Test-only container for rule examples, built from a ``Rule`` type's static metadata.
struct TestExamples {
  let identifier: String
  let nonTriggeringExamples: [Example]
  let triggeringExamples: [Example]
  let corrections: [Example: Example]
  let minSwiftVersion: SwiftVersion
  let requiresFileOnDisk: Bool
  let allIdentifiers: [String]

  init<R: Rule>(from ruleType: R.Type) {
    identifier = R.id
    nonTriggeringExamples = R.nonTriggeringExamples
    triggeringExamples = R.triggeringExamples
    corrections = R.corrections
    minSwiftVersion = R.minSwiftVersion
    requiresFileOnDisk = R.requiresFileOnDisk
    allIdentifiers = R.allIdentifiers
  }

  func with(
    nonTriggeringExamples: [Example]? = nil,
    triggeringExamples: [Example]? = nil,
    corrections: [Example: Example]? = nil,
  ) -> TestExamples {
    TestExamples(
      identifier: identifier,
      nonTriggeringExamples: nonTriggeringExamples ?? self.nonTriggeringExamples,
      triggeringExamples: triggeringExamples ?? self.triggeringExamples,
      corrections: corrections ?? self.corrections,
      minSwiftVersion: minSwiftVersion,
      requiresFileOnDisk: requiresFileOnDisk,
      allIdentifiers: allIdentifiers,
    )
  }

  func focused() -> TestExamples {
    let nonTriggering = nonTriggeringExamples.filter(\.isFocused)
    let triggering = triggeringExamples.filter(\.isFocused)
    let focusedCorrections = corrections.filter { key, value in key.isFocused || value.isFocused }
    let anyFocused =
      nonTriggering.isNotEmpty || triggering.isNotEmpty || focusedCorrections.isNotEmpty

    if anyFocused {
      return TestExamples(
        identifier: identifier,
        nonTriggeringExamples: nonTriggering,
        triggeringExamples: triggering,
        corrections: focusedCorrections,
        minSwiftVersion: minSwiftVersion,
        requiresFileOnDisk: requiresFileOnDisk,
        allIdentifiers: allIdentifiers,
      )
    }
    return self
  }

  private init(
    identifier: String,
    nonTriggeringExamples: [Example],
    triggeringExamples: [Example],
    corrections: [Example: Example],
    minSwiftVersion: SwiftVersion,
    requiresFileOnDisk: Bool,
    allIdentifiers: [String],
  ) {
    self.identifier = identifier
    self.nonTriggeringExamples = nonTriggeringExamples
    self.triggeringExamples = triggeringExamples
    self.corrections = corrections
    self.minSwiftVersion = minSwiftVersion
    self.requiresFileOnDisk = requiresFileOnDisk
    self.allIdentifiers = allIdentifiers
  }
}
