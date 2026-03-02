struct LegacyHashingConfiguration: RuleConfiguration {
    let id = "legacy_hashing"
    let name = "Legacy Hashing"
    let summary = "Prefer using the `hash(into:)` function instead of overriding `hashValue`"
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                struct Foo: Hashable {
                  let bar: Int = 10

                  func hash(into hasher: inout Hasher) {
                    hasher.combine(bar)
                  }
                }
                """,
              ),
              Example(
                """
                class Foo: Hashable {
                  let bar: Int = 10

                  func hash(into hasher: inout Hasher) {
                    hasher.combine(bar)
                  }
                }
                """,
              ),
              Example(
                """
                var hashValue: Int { return 1 }
                class Foo: Hashable { \n }
                """,
              ),
              Example(
                """
                class Foo: Hashable {
                  let bar: String = "Foo"

                  public var hashValue: String {
                    return bar
                  }
                }
                """,
              ),
              Example(
                """
                class Foo: Hashable {
                  let bar: String = "Foo"

                  public var hashValue: String {
                    get { return bar }
                    set { bar = newValue }
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
                struct Foo: Hashable {
                    let bar: Int = 10

                    public ↓var hashValue: Int {
                        return bar
                    }
                }
                """,
              ),
              Example(
                """
                class Foo: Hashable {
                    let bar: Int = 10

                    public ↓var hashValue: Int {
                        return bar
                    }
                }
                """,
              ),
            ]
    }
}
