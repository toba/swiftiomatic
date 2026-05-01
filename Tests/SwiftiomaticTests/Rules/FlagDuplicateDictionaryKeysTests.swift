@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct FlagDuplicateDictionaryKeysTests: RuleTesting {
  @Test func duplicateIntKey() {
    assertLint(
      FlagDuplicateDictionaryKeys.self,
      """
      let d = [
        1: "1",
        2: "2",
        1️⃣1: "one",
      ]
      """,
      findings: [
        FindingSpec("1️⃣", message: "duplicate key '1' in dictionary literal — last value wins"),
      ]
    )
  }

  @Test func duplicateStringKey() {
    assertLint(
      FlagDuplicateDictionaryKeys.self,
      """
      let d = [
        "1": 1,
        "2": 2,
        1️⃣"2": 2,
      ]
      """,
      findings: [
        FindingSpec("1️⃣", message: "duplicate key '\"2\"' in dictionary literal — last value wins"),
      ]
    )
  }

  @Test func duplicateIdentifierKey() {
    assertLint(
      FlagDuplicateDictionaryKeys.self,
      """
      let d = [
        foo: "1",
        bar: "2",
        baz: "3",
        1️⃣foo: "4",
        zaz: "5",
      ]
      """,
      findings: [
        FindingSpec("1️⃣", message: "duplicate key 'foo' in dictionary literal — last value wins"),
      ]
    )
  }

  @Test func duplicateMemberAccessKey() {
    assertLint(
      FlagDuplicateDictionaryKeys.self,
      """
      let d: [Foo: String] = [
        .one: "1",
        .two: "2",
        .three: "3",
        1️⃣.one: "1",
        .four: "4",
      ]
      """,
      findings: [
        FindingSpec("1️⃣", message: "duplicate key '.one' in dictionary literal — last value wins"),
      ]
    )
  }

  @Test func tripleDuplicateFlagsAllAfterFirst() {
    assertLint(
      FlagDuplicateDictionaryKeys.self,
      """
      let d = [
        1: "a",
        1️⃣1: "b",
        2️⃣1: "c",
      ]
      """,
      findings: [
        FindingSpec("1️⃣", message: "duplicate key '1' in dictionary literal — last value wins"),
        FindingSpec("2️⃣", message: "duplicate key '1' in dictionary literal — last value wins"),
      ]
    )
  }

  @Test func dynamicKeysDoNotTrigger() {
    // Function-call keys can produce different values per invocation, so
    // they aren't statically duplicate.
    assertLint(
      FlagDuplicateDictionaryKeys.self,
      """
      let d = [
        UUID(): "1",
        UUID(): "2",
      ]
      let e = [
        #line: "1",
        #line: "2",
      ]
      """,
      findings: []
    )
  }

  @Test func uniqueKeysDoNotTrigger() {
    assertLint(
      FlagDuplicateDictionaryKeys.self,
      """
      let d = [
        1: "1",
        2: "2",
      ]
      let e = [
        foo: "1",
        bar: "2",
      ]
      """,
      findings: []
    )
  }
}
