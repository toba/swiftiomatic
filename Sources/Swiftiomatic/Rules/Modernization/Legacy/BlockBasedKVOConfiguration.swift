struct BlockBasedKVOConfiguration: RuleConfiguration {
    let id = "block_based_kvo"
    let name = "Block Based KVO"
    let summary = "Prefer the new block based KVO API with keypaths when using Swift 3.2 or later"
    var nonTriggeringExamples: [Example] {
        [
              Example(
                #"""
                let observer = foo.observe(\.value, options: [.new]) { (foo, change) in
                   print(change.newValue)
                }
                """#,
              )
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                class Foo: NSObject {
                  override ↓func observeValue(forKeyPath keyPath: String?, of object: Any?,
                                              change: [NSKeyValueChangeKey : Any]?,
                                              context: UnsafeMutableRawPointer?) {}
                }
                """,
              ),
              Example(
                """
                class Foo: NSObject {
                  override ↓func observeValue(forKeyPath keyPath: String?, of object: Any?,
                                              change: Dictionary<NSKeyValueChangeKey, Any>?,
                                              context: UnsafeMutableRawPointer?) {}
                }
                """,
              ),
            ]
    }
}
