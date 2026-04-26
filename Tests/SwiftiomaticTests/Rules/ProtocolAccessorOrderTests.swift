@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct ProtocolAccessorOrderTests: RuleTesting {
  @Test func reordersSetGet() {
    assertFormatting(
      ProtocolAccessorOrder.self,
      input: """
        protocol Foo {
          var bar: String { 1️⃣set get }
        }
        """,
      expected: """
        protocol Foo {
          var bar: String { get set }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "swap accessor order to 'get set'")
      ]
    )
  }

  @Test func nonTriggeringGetSet() {
    assertFormatting(
      ProtocolAccessorOrder.self,
      input: """
        protocol Foo {
          var bar: String { get set }
        }
        """,
      expected: """
        protocol Foo {
          var bar: String { get set }
        }
        """,
      findings: []
    )
  }

  @Test func nonTriggeringGetOnly() {
    assertFormatting(
      ProtocolAccessorOrder.self,
      input: """
        protocol Foo {
          var bar: String { get }
        }
        """,
      expected: """
        protocol Foo {
          var bar: String { get }
        }
        """,
      findings: []
    )
  }

  @Test func nonTriggeringSetOnly() {
    assertFormatting(
      ProtocolAccessorOrder.self,
      input: """
        protocol Foo {
          var bar: String { set }
        }
        """,
      expected: """
        protocol Foo {
          var bar: String { set }
        }
        """,
      findings: []
    )
  }

  @Test func nonTriggeringComputedProperty() {
    // Outside a protocol with bodies — different rule's concern (AccessorOrder).
    assertFormatting(
      ProtocolAccessorOrder.self,
      input: """
        struct Foo {
          var bar: String {
            set { _bar = newValue }
            get { _bar }
          }
        }
        """,
      expected: """
        struct Foo {
          var bar: String {
            set { _bar = newValue }
            get { _bar }
          }
        }
        """,
      findings: []
    )
  }
}
