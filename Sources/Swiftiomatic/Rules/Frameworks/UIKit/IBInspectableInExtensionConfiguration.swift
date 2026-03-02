struct IBInspectableInExtensionConfiguration: RuleConfiguration {
    let id = "ibinspectable_in_extension"
    let name = "IBInspectable in Extension"
    let summary = "Extensions shouldn't add @IBInspectable properties"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                class Foo {
                  @IBInspectable private var x: Int
                }
                """,
              )
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                extension Foo {
                  ↓@IBInspectable private var x: Int
                }
                """,
              )
            ]
    }
}
