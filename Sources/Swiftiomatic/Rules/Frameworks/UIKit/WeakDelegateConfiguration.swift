struct WeakDelegateConfiguration: RuleConfiguration {
    let id = "weak_delegate"
    let name = "Weak Delegate"
    let summary = "Delegates should be weak to avoid reference cycles"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("class Foo {\n  weak var delegate: SomeProtocol?\n}"),
              Example("class Foo {\n  weak var someDelegate: SomeDelegateProtocol?\n}"),
              Example("class Foo {\n  weak var delegateScroll: ScrollDelegate?\n}"),
              // We only consider properties to be a delegate if it has "delegate" in its name
              Example("class Foo {\n  var scrollHandler: ScrollDelegate?\n}"),
              // Only trigger on instance variables, not local variables
              Example("func foo() {\n  var delegate: SomeDelegate\n}"),
              // Only trigger when variable has the suffix "-delegate" to avoid false positives
              Example("class Foo {\n  var delegateNotified: Bool?\n}"),
              // There's no way to declare a property weak in a protocol
              Example("protocol P {\n var delegate: AnyObject? { get set }\n}"),
              Example("class Foo {\n protocol P {\n var delegate: AnyObject? { get set }\n}\n}"),
              Example(
                "class Foo {\n var computedDelegate: ComputedDelegate {\n return bar() \n} \n}",
              ),
              Example(
                """
                class Foo {
                    var computedDelegate: ComputedDelegate {
                        get {
                            return bar()
                        }
                   }
                """,
              ),
              Example(
                "struct Foo {\n @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate \n}",
              ),
              Example(
                "struct Foo {\n @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate \n}",
              ),
              Example(
                "struct Foo {\n @WKExtensionDelegateAdaptor(ExtensionDelegate.self) var extensionDelegate \n}",
              ),
              Example(
                """
                class Foo {
                    func makeDelegate() -> SomeDelegate {
                        let delegate = SomeDelegate()
                        return delegate
                    }
                }
                """,
              ),
              Example(
                """
                class Foo {
                    var bar: Bool {
                        let appDelegate = AppDelegate.bar
                        return appDelegate.bar
                    }
                }
                """, isExcludedFromDocumentation: true,
              ),
              Example("private var appDelegate: String?", isExcludedFromDocumentation: true),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("class Foo {\n  ↓var delegate: SomeProtocol?\n}"),
              Example("class Foo {\n  ↓var scrollDelegate: ScrollDelegate?\n}"),
              Example(
                """
                class Foo {
                    ↓var delegate: SomeProtocol? {
                        didSet {
                            print("Updated delegate")
                        }
                   }
                """,
              ),
            ]
    }
}
