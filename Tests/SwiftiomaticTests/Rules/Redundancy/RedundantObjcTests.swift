import Testing

@testable import Swiftiomatic

@Suite struct RedundantObjcTests {
  @Test func redundantObjcRemovedFromBeforeOutlet() {
    let input = """
      @objc @IBOutlet var label: UILabel!
      """
    let output = """
      @IBOutlet var label: UILabel!
      """
    testFormatting(for: input, output, rule: .redundantObjc)
  }

  @Test func redundantObjcRemovedFromAfterOutlet() {
    let input = """
      @IBOutlet @objc var label: UILabel!
      """
    let output = """
      @IBOutlet var label: UILabel!
      """
    testFormatting(for: input, output, rule: .redundantObjc)
  }

  @Test func redundantObjcRemovedFromLineBeforeOutlet() {
    let input = """
      @objc
      @IBOutlet var label: UILabel!
      """
    let output = """

      @IBOutlet var label: UILabel!
      """
    testFormatting(for: input, output, rule: .redundantObjc)
  }

  @Test func redundantObjcCommentNotRemoved() {
    let input = """
      @objc /// an outlet
      @IBOutlet var label: UILabel!
      """
    let output = """
      /// an outlet
      @IBOutlet var label: UILabel!
      """
    testFormatting(for: input, output, rule: .redundantObjc)
  }

  @Test func objcNotRemovedFromNSCopying() {
    let input = """
      @objc @NSCopying var foo: String!
      """
    testFormatting(for: input, rule: .redundantObjc)
  }

  @Test func renamedObjcNotRemoved() {
    let input = """
      @IBOutlet @objc(uiLabel) var label: UILabel!
      """
    testFormatting(for: input, rule: .redundantObjc)
  }

  @Test func objcRemovedOnObjcMembersClass() {
    let input = """
      @objcMembers class Foo: NSObject {
          @objc var foo: String
      }
      """
    let output = """
      @objcMembers class Foo: NSObject {
          var foo: String
      }
      """
    testFormatting(for: input, output, rule: .redundantObjc)
  }

  @Test func objcRemovedOnRenamedObjcMembersClass() {
    let input = """
      @objcMembers @objc(OCFoo) class Foo: NSObject {
          @objc var foo: String
      }
      """
    let output = """
      @objcMembers @objc(OCFoo) class Foo: NSObject {
          var foo: String
      }
      """
    testFormatting(for: input, output, rule: .redundantObjc)
  }

  @Test func objcNotRemovedOnNestedClass() {
    let input = """
      @objcMembers class Foo: NSObject {
          @objc class Bar: NSObject {}
      }
      """
    testFormatting(for: input, rule: .redundantObjc)
  }

  @Test func objcNotRemovedOnRenamedPrivateNestedClass() {
    let input = """
      @objcMembers class Foo: NSObject {
          @objc private class Bar: NSObject {}
      }
      """
    testFormatting(for: input, rule: .redundantObjc)
  }

  @Test func objcNotRemovedOnNestedEnum() {
    let input = """
      @objcMembers class Foo: NSObject {
          @objc enum Bar: Int {}
      }
      """
    testFormatting(for: input, rule: .redundantObjc)
  }

  @Test func objcRemovedOnObjcExtensionVar() {
    let input = """
      @objc extension Foo {
          @objc var foo: String {}
      }
      """
    let output = """
      @objc extension Foo {
          var foo: String {}
      }
      """
    testFormatting(for: input, output, rule: .redundantObjc)
  }

  @Test func objcRemovedOnObjcExtensionFunc() {
    let input = """
      @objc extension Foo {
          @objc func foo() -> String {}
      }
      """
    let output = """
      @objc extension Foo {
          func foo() -> String {}
      }
      """
    testFormatting(for: input, output, rule: .redundantObjc)
  }

  @Test func objcNotRemovedOnPrivateFunc() {
    let input = """
      @objcMembers class Foo: NSObject {
          @objc private func bar() {}
      }
      """
    testFormatting(for: input, rule: .redundantObjc)
  }

  @Test func objcNotRemovedOnFileprivateFunc() {
    let input = """
      @objcMembers class Foo: NSObject {
          @objc fileprivate func bar() {}
      }
      """
    testFormatting(for: input, rule: .redundantObjc)
  }

  @Test func objcRemovedOnPrivateSetFunc() {
    let input = """
      @objcMembers class Foo: NSObject {
          @objc private(set) func bar() {}
      }
      """
    let output = """
      @objcMembers class Foo: NSObject {
          private(set) func bar() {}
      }
      """
    testFormatting(for: input, output, rule: .redundantObjc)
  }
}
