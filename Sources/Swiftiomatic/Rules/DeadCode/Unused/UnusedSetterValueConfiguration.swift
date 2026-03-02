struct UnusedSetterValueConfiguration: RuleConfiguration {
    let id = "unused_setter_value"
    let name = "Unused Setter Value"
    let summary = "Setter value is not used"
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                var aValue: String {
                    get {
                        return Persister.shared.aValue
                    }
                    set {
                        Persister.shared.aValue = newValue
                    }
                }
                """,
              ),
              Example(
                """
                var aValue: String {
                    set {
                        Persister.shared.aValue = newValue
                    }
                    get {
                        return Persister.shared.aValue
                    }
                }
                """,
              ),
              Example(
                """
                var aValue: String {
                    get {
                        return Persister.shared.aValue
                    }
                    set(value) {
                        Persister.shared.aValue = value
                    }
                }
                """,
              ),
              Example(
                """
                override var aValue: String {
                 get {
                     return Persister.shared.aValue
                 }
                 set { }
                }
                """,
              ),
              Example(
                """
                protocol Foo {
                    var bar: Bool { get set }
                """, isExcludedFromDocumentation: true,
              ),
              Example(
                """
                override var accessibilityValue: String? {
                    get {
                        let index = Int(self.value)
                        guard steps.indices.contains(index) else { return "" }
                        return ""
                    }
                    set {}
                }
                """, isExcludedFromDocumentation: true,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                var aValue: String {
                    get {
                        return Persister.shared.aValue
                    }
                    ↓set {
                        Persister.shared.aValue = aValue
                    }
                }
                """,
              ),
              Example(
                """
                var aValue: String {
                    ↓set {
                        Persister.shared.aValue = aValue
                    }
                    get {
                        return Persister.shared.aValue
                    }
                }
                """,
              ),
              Example(
                """
                var aValue: String {
                    get {
                        return Persister.shared.aValue
                    }
                    ↓set {
                        Persister.shared.aValue = aValue
                    }
                }
                """,
              ),
              Example(
                """
                var aValue: String {
                    get {
                        let newValue = Persister.shared.aValue
                        return newValue
                    }
                    ↓set {
                        Persister.shared.aValue = aValue
                    }
                }
                """,
              ),
              Example(
                """
                var aValue: String {
                    get {
                        return Persister.shared.aValue
                    }
                    ↓set(value) {
                        Persister.shared.aValue = aValue
                    }
                }
                """,
              ),
              Example(
                """
                override var aValue: String {
                    get {
                        return Persister.shared.aValue
                    }
                    ↓set {
                        Persister.shared.aValue = aValue
                    }
                }
                """,
              ),
            ]
    }
}
