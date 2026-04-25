@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UnusedSetterValueTests: RuleTesting {
  @Test func defaultNewValueUsed() {
    assertLint(
      UnusedSetterValue.self,
      """
      var aValue: String {
        get { return Persister.shared.aValue }
        set { Persister.shared.aValue = newValue }
      }
      """,
      findings: []
    )
  }

  @Test func defaultNewValueUnused() {
    assertLint(
      UnusedSetterValue.self,
      """
      var aValue: String {
        get { return Persister.shared.aValue }
        1️⃣set { Persister.shared.aValue = aValue }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "the setter parameter (newValue) is never used"),
      ]
    )
  }

  @Test func customParameterNameUsed() {
    assertLint(
      UnusedSetterValue.self,
      """
      var aValue: String {
        get { return Persister.shared.aValue }
        set(value) { Persister.shared.aValue = value }
      }
      """,
      findings: []
    )
  }

  @Test func customParameterNameUnused() {
    assertLint(
      UnusedSetterValue.self,
      """
      var aValue: String {
        get { return Persister.shared.aValue }
        1️⃣set(value) { Persister.shared.aValue = aValue }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "the setter parameter (value) is never used"),
      ]
    )
  }

  @Test func overrideEmptySetterDoesNotTrigger() {
    assertLint(
      UnusedSetterValue.self,
      """
      class Sub: Base {
        override var aValue: String {
          get { return Persister.shared.aValue }
          set {}
        }
      }
      """,
      findings: []
    )
  }

  @Test func overrideNonEmptySetterStillTriggers() {
    assertLint(
      UnusedSetterValue.self,
      """
      class Sub: Base {
        override var aValue: String {
          get { return Persister.shared.aValue }
          1️⃣set { Persister.shared.aValue = aValue }
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "the setter parameter (newValue) is never used"),
      ]
    )
  }

  @Test func protocolStubsNotChecked() {
    assertLint(
      UnusedSetterValue.self,
      """
      protocol Foo {
        var bar: Bool { get set }
      }
      """,
      findings: []
    )
  }

  @Test func nestedNewValueShadowingDoesNotConfuse() {
    // A `let newValue = ...` in the getter is irrelevant — the setter
    // doesn't use it.
    assertLint(
      UnusedSetterValue.self,
      """
      var aValue: String {
        get {
          let newValue = Persister.shared.aValue
          return newValue
        }
        1️⃣set { Persister.shared.aValue = aValue }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "the setter parameter (newValue) is never used"),
      ]
    )
  }
}
