@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct SortGetSetAccessorsTests: RuleTesting {
  @Test func defaultRequiresGetSetForProperty() {
    assertLint(
      SortGetSetAccessors.self,
      """
      struct Foo {
        var bar: Int {
          1️⃣set { _bar = newValue }
          get { _bar }
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "computed properties should declare the getter and then the setter")
      ]
    )
  }

  @Test func defaultRequiresGetSetForSubscript() {
    assertLint(
      SortGetSetAccessors.self,
      """
      struct Foo {
        subscript(i: Int) -> Int {
          1️⃣set { _values[i] = newValue }
          get { _values[i] }
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "subscripts should declare the getter and then the setter")
      ]
    )
  }

  @Test func nonTriggeringGetSet() {
    assertLint(
      SortGetSetAccessors.self,
      """
      struct Foo {
        var bar: Int {
          get { _bar }
          set { _bar = newValue }
        }
      }
      """,
      findings: []
    )
  }

  @Test func nonTriggeringSingleAccessor() {
    assertLint(
      SortGetSetAccessors.self,
      """
      struct Foo {
        var bar: Int { _bar }
      }
      """,
      findings: []
    )
  }

  @Test func nonTriggeringProtocolBodylessAccessors() {
    // Protocol property requirements have no bodies — handled by OrderProtocolAccessors.
    assertLint(
      SortGetSetAccessors.self,
      """
      protocol Foo {
        var bar: Int { set get }
      }
      """,
      findings: []
    )
  }

  @Test func setGetConfigurationRequiresSetGet() {
    var configuration = Configuration.forTesting(enabledRule: SortGetSetAccessors.self.key)
    configuration[SortGetSetAccessors.self].order = .setGet

    assertLint(
      SortGetSetAccessors.self,
      """
      struct Foo {
        var bar: Int {
          1️⃣get { _bar }
          set { _bar = newValue }
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "computed properties should declare the setter and then the getter")
      ],
      configuration: configuration
    )
  }
}
