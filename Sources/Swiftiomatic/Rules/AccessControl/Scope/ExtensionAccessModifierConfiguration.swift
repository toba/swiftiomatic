struct ExtensionAccessModifierConfiguration: RuleConfiguration {
    let id = "extension_access_modifier"
    let name = "Extension Access Modifier"
    let summary = "Prefer to use extension access modifiers"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                extension Foo: SomeProtocol {
                  public var bar: Int { return 1 }
                }
                """,
              ),
              Example(
                """
                extension Foo {
                  private var bar: Int { return 1 }
                  public var baz: Int { return 1 }
                }
                """,
              ),
              Example(
                """
                extension Foo {
                  private var bar: Int { return 1 }
                  public func baz() {}
                }
                """,
              ),
              Example(
                """
                extension Foo {
                  var bar: Int { return 1 }
                  var baz: Int { return 1 }
                }
                """,
              ),
              Example(
                """
                extension Foo {
                  var bar: Int { return 1 }
                  internal var baz: Int { return 1 }
                }
                """,
              ),
              Example(
                """
                internal extension Foo {
                  var bar: Int { return 1 }
                  var baz: Int { return 1 }
                }
                """,
              ),
              Example(
                """
                public extension Foo {
                  var bar: Int { return 1 }
                  var baz: Int { return 1 }
                }
                """,
              ),
              Example(
                """
                public extension Foo {
                  var bar: Int { return 1 }
                  internal var baz: Int { return 1 }
                }
                """,
              ),
              Example(
                """
                extension Foo {
                  private var bar: Int { return 1 }
                  private var baz: Int { return 1 }
                }
                """,
              ),
              Example(
                """
                extension Foo {
                  open var bar: Int { return 1 }
                  open var baz: Int { return 1 }
                }
                """,
              ),
              Example(
                """
                extension Foo {
                    func setup() {}
                    public func update() {}
                }
                """,
              ),
              Example(
                """
                private extension Foo {
                  private var bar: Int { return 1 }
                  var baz: Int { return 1 }
                }
                """,
              ),
              Example(
                """
                extension Foo {
                  internal private(set) var bar: Int {
                    get { Foo.shared.bar }
                    set { Foo.shared.bar = newValue }
                  }
                }
                """,
              ),
              Example(
                """
                extension Foo {
                  private(set) internal var bar: Int {
                    get { Foo.shared.bar }
                    set { Foo.shared.bar = newValue }
                  }
                }
                """,
              ),
              Example(
                """
                public extension Foo {
                  private(set) var value: Int { 1 }
                }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                ↓extension Foo {
                   public var bar: Int { return 1 }
                   public var baz: Int { return 1 }
                }
                """,
              ),
              Example(
                """
                ↓extension Foo {
                   public var bar: Int { return 1 }
                   public func baz() {}
                }
                """,
              ),
              Example(
                """
                public extension Foo {
                  ↓public func bar() {}
                  ↓public func baz() {}
                }
                """,
              ),
              Example(
                """
                ↓extension Foo {
                   public var bar: Int {
                      let value = 1
                      return value
                   }

                   public var baz: Int { return 1 }
                }
                """,
              ),
              Example(
                """
                ↓extension Array where Element: Equatable {
                    public var unique: [Element] {
                        var uniqueValues = [Element]()
                        for item in self where !uniqueValues.contains(item) {
                            uniqueValues.append(item)
                        }
                        return uniqueValues
                    }
                }
                """,
              ),
              Example(
                """
                ↓extension Foo {
                   #if DEBUG
                   public var bar: Int {
                      let value = 1
                      return value
                   }
                   #endif

                   public var baz: Int { return 1 }
                }
                """,
              ),
              Example(
                """
                public extension Foo {
                  ↓private func bar() {}
                  ↓private func baz() {}
                }
                """,
              ),
              Example(
                """
                ↓extension Foo {
                  private(set) public var value: Int { 1 }
                }
                """,
              ),
            ]
    }
}
