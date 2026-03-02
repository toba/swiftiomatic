struct LowerACLThanParentConfiguration: RuleConfiguration {
    let id = "lower_acl_than_parent"
    let name = "Lower ACL than Parent"
    let summary = "Ensure declarations have a lower access control level than their enclosing parent"
    let isCorrectable = true
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
                    Example("public struct Foo { public func bar() {} }"),
                    Example("internal struct Foo { func bar() {} }"),
                    Example("struct Foo { func bar() {} }"),
                    Example("struct Foo { internal func bar() {} }"),
                    Example("open class Foo { public func bar() {} }"),
                    Example("open class Foo { open func bar() {} }"),
                    Example("fileprivate struct Foo { private func bar() {} }"),
                    Example("private struct Foo { private func bar(id: String) }"),
                    Example("extension Foo { public func bar() {} }"),
                    Example("private struct Foo { fileprivate func bar() {} }"),
                    Example("private func foo(id: String) {}"),
                    Example("private class Foo { func bar() {} }"),
                    Example("public extension Foo { struct Bar { public func baz() {} }}"),
                    Example("public extension Foo { struct Bar { internal func baz() {} }}"),
                    Example("internal extension Foo { struct Bar { internal func baz() {} }}"),
                    Example("extension Foo { struct Bar { internal func baz() {} }}"),
                ]
    }
    var triggeringExamples: [Example] {
        [
                    Example("struct Foo { ↓public func bar() {} }"),
                    Example("enum Foo { ↓public func bar() {} }"),
                    Example("public class Foo { ↓open func bar() }"),
                    Example("class Foo { ↓public private(set) var bar: String? }"),
                    Example("private struct Foo { ↓public func bar() {} }"),
                    Example("private class Foo { ↓public func bar() {} }"),
                    Example("private actor Foo { ↓public func bar() {} }"),
                    Example("fileprivate struct Foo { ↓public func bar() {} }"),
                    Example("class Foo { ↓public func bar() {} }"),
                    Example("actor Foo { ↓public func bar() {} }"),
                    Example("private struct Foo { ↓internal func bar() {} }"),
                    Example("fileprivate struct Foo { ↓internal func bar() {} }"),
                    Example("extension Foo { struct Bar { ↓public func baz() {} }}"),
                    Example("internal extension Foo { struct Bar { ↓public func baz() {} }}"),
                    Example("private extension Foo { struct Bar { ↓public func baz() {} }}"),
                    Example("fileprivate extension Foo { struct Bar { ↓public func baz() {} }}"),
                    Example("private extension Foo { struct Bar { ↓internal func baz() {} }}"),
                    Example("fileprivate extension Foo { struct Bar { ↓internal func baz() {} }}"),
                    Example("public extension Foo { struct Bar { struct Baz { ↓public func qux() {} }}}"),
                    Example("final class Foo { ↓public func bar() {} }"),
                ]
    }
    var corrections: [Example: Example] {
        [
                    Example("struct Foo { ↓public func bar() {} }"):
                        Example("struct Foo { func bar() {} }"),
                    Example("enum Foo { ↓public func bar() {} }"):
                        Example("enum Foo { func bar() {} }"),
                    Example("public class Foo { ↓open func bar() }"):
                        Example("public class Foo { public func bar() }"),
                    Example("class Foo { ↓public private(set) var bar: String? }"):
                        Example("class Foo { private(set) var bar: String? }"),
                    Example("private struct Foo { ↓public func bar() {} }"):
                        Example("private struct Foo { func bar() {} }"),
                    Example("private class Foo { ↓public func bar() {} }"):
                        Example("private class Foo { func bar() {} }"),
                    Example("private actor Foo { ↓public func bar() {} }"):
                        Example("private actor Foo { func bar() {} }"),
                    Example("class Foo { ↓public func bar() {} }"):
                        Example("class Foo { func bar() {} }"),
                    Example("actor Foo { ↓public func bar() {} }"):
                        Example("actor Foo { func bar() {} }"),
                    Example(
                        """
                        struct Foo {
                            ↓public func bar() {}
                        }
                        """,
                    ):
                        Example(
                            """
                            struct Foo {
                                func bar() {}
                            }
                            """,
                        ),
                ]
    }
}
