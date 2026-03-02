struct ValidIBInspectableConfiguration: RuleConfiguration {
    let id = "valid_ibinspectable"
    let name = "Valid IBInspectable"
    let summary = ""
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                class Foo {
                  @IBInspectable private var x: Int
                }
                """,
              ),
              Example(
                """
                class Foo {
                  @IBInspectable private var x: String?
                }
                """,
              ),
              Example(
                """
                class Foo {
                  @IBInspectable private var x: String!
                }
                """,
              ),
              Example(
                """
                class Foo {
                  @IBInspectable private var count: Int = 0
                }
                """,
              ),
              Example(
                """
                class Foo {
                  private var notInspectable = 0
                }
                """,
              ),
              Example(
                """
                class Foo {
                  private let notInspectable: Int
                }
                """,
              ),
              Example(
                """
                class Foo {
                  private let notInspectable: UInt8
                }
                """,
              ),
              Example(
                """
                extension Foo {
                    @IBInspectable var color: UIColor {
                        set {
                            self.bar.textColor = newValue
                        }

                        get {
                            return self.bar.textColor
                        }
                    }
                }
                """,
              ),
              Example(
                """
                class Foo {
                    @IBInspectable var borderColor: UIColor? = nil {
                        didSet {
                            updateAppearance()
                        }
                    }
                }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                class Foo {
                  @IBInspectable private ↓let count: Int
                }
                """,
              ),
              Example(
                """
                class Foo {
                  @IBInspectable private ↓var insets: UIEdgeInsets
                }
                """,
              ),
              Example(
                """
                class Foo {
                  @IBInspectable private ↓var count = 0
                }
                """,
              ),
              Example(
                """
                class Foo {
                  @IBInspectable private ↓var count: Int?
                }
                """,
              ),
              Example(
                """
                class Foo {
                  @IBInspectable private ↓var count: Int!
                }
                """,
              ),
              Example(
                """
                class Foo {
                  @IBInspectable private ↓var count: Optional<Int>
                }
                """,
              ),
              Example(
                """
                class Foo {
                  @IBInspectable private ↓var x: Optional<String>
                }
                """,
              ),
            ]
    }
}
