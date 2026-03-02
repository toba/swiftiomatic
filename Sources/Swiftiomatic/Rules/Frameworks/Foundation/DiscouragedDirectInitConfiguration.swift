struct DiscouragedDirectInitConfiguration: RuleConfiguration {
    let id = "discouraged_direct_init"
    let name = "Discouraged Direct Initialization"
    let summary = "Discouraged direct initialization of types that can be harmful"
    var nonTriggeringExamples: [Example] {
        [
              Example("let foo = UIDevice.current"),
              Example("let foo = Bundle.main"),
              Example("let foo = Bundle(path: \"bar\")"),
              Example("let foo = Bundle(identifier: \"bar\")"),
              Example("let foo = Bundle.init(path: \"bar\")"),
              Example("let foo = Bundle.init(identifier: \"bar\")"),
              Example("let foo = NSError(domain: \"bar\", code: 0)"),
              Example("let foo = NSError.init(domain: \"bar\", code: 0)"),
              Example("func testNSError()"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("↓UIDevice()"),
              Example("↓Bundle()"),
              Example("let foo = ↓UIDevice()"),
              Example("let foo = ↓Bundle()"),
              Example("let foo = ↓NSError()"),
              Example("let foo = bar(bundle: ↓Bundle(), device: ↓UIDevice(), error: ↓NSError())"),
              Example("↓UIDevice.init()"),
              Example("↓Bundle.init()"),
              Example("↓NSError.init()"),
              Example("let foo = ↓UIDevice.init()"),
              Example("let foo = ↓Bundle.init()"),
              Example(
                "let foo = bar(bundle: ↓Bundle.init(), device: ↓UIDevice.init(), error: ↓NSError.init())",
              ),
            ]
    }
}
