struct ClassDelegateProtocolConfiguration: RuleConfiguration {
    let id = "class_delegate_protocol"
    let name = "Class Delegate Protocol"
    let summary = "Delegate protocols should be class-only so they can be weakly referenced"
    var nonTriggeringExamples: [Example] {
        [
              Example("protocol FooDelegate: class {}"),
              Example("protocol FooDelegate: class, BarDelegate {}"),
              Example("protocol Foo {}"),
              Example("class FooDelegate {}"),
              Example("@objc protocol FooDelegate {}"),
              Example("@objc(MyFooDelegate)\n protocol FooDelegate {}"),
              Example("protocol FooDelegate: BarDelegate {}"),
              Example("protocol FooDelegate: AnyObject {}"),
              Example("protocol FooDelegate: AnyObject & Foo {}"),
              Example("protocol FooDelegate: Foo, AnyObject & Foo {}"),
              Example("protocol FooDelegate: Foo & AnyObject & Bar {}"),
              Example("protocol FooDelegate: NSObjectProtocol {}"),
              Example("protocol FooDelegate where Self: BarDelegate {}"),
              Example("protocol FooDelegate where Self: BarDelegate & Bar {}"),
              Example("protocol FooDelegate where Self: Foo & BarDelegate & Bar {}"),
              Example("protocol FooDelegate where Self: AnyObject {}"),
              Example("protocol FooDelegate where Self: NSObjectProtocol {}"),
              Example("protocol FooDelegate: Actor {}"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("↓protocol FooDelegate {}"),
              Example("↓protocol FooDelegate: Bar {}"),
              Example("↓protocol FooDelegate: Foo & Bar {}"),
              Example("↓protocol FooDelegate where Self: StringProtocol {}"),
              Example("↓protocol FooDelegate where Self: A & B {}"),
            ]
    }
    let rationale: String? = """
      Delegate protocols are usually `weak` to avoid retain cycles, or bad references to deallocated delegates.

      The `weak` operator is only supported for classes, and so this rule enforces that protocols ending in \
      "Delegate" are class based.

      For example

      ```
      protocol FooDelegate: class {}
      ```

      versus

      ```
      ↓protocol FooDelegate {}
      ```
      """
}
