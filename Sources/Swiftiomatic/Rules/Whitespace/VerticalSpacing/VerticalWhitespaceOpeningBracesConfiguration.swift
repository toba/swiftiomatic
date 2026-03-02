struct VerticalWhitespaceOpeningBracesConfiguration: RuleConfiguration {
    private static let nonTriggeringExamples = [
        Example("[1, 2].map { $0 }.foo()"),
        Example("[1, 2].map { $0 }.filter { num in true }"),
        Example("// [1, 2].map { $0 }.filter { num in true }"),
        Example(
            """
            /*
                class X {

                    let x = 5

                }
            */
            """
        ),
    ]

    private static let violatingToValidExamples: [Example: Example] = [
        Example(
            """
            if x == 5 {
            ↓
              print("x is 5")
            }
            """
        ): Example(
            """
            if x == 5 {
              print("x is 5")
            }
            """
        ),
        Example(
            """
            if x == 5 {
            ↓

              print("x is 5")
            }
            """
        ): Example(
            """
            if x == 5 {
              print("x is 5")
            }
            """
        ),
        Example(
            """
            struct MyStruct {
            ↓
              let x = 5
            }
            """
        ): Example(
            """
            struct MyStruct {
              let x = 5
            }
            """
        ),
        Example(
            """
            class X {
              struct Y {
            ↓
                class Z {
                }
              }
            }
            """
        ): Example(
            """
            class X {
              struct Y {
                class Z {
                }
              }
            }
            """
        ),
        Example(
            """
            [
            ↓
            1,
            2,
            3
            ]
            """
        ): Example(
            """
            [
            1,
            2,
            3
            ]
            """
        ),
        Example(
            """
            foo(
            ↓
              x: 5,
              y:6
            )
            """
        ): Example(
            """
            foo(
              x: 5,
              y:6
            )
            """
        ),
        Example(
            """
            func foo() {
            ↓
              run(5) { x in
                print(x)
              }
            }
            """
        ): Example(
            """
            func foo() {
              run(5) { x in
                print(x)
              }
            }
            """
        ),
        Example(
            """
            KingfisherManager.shared.retrieveImage(with: url, options: nil, progressBlock: nil) { image, _, _, _ in
            ↓
                guard let img = image else { return }
            }
            """
        ): Example(
            """
            KingfisherManager.shared.retrieveImage(with: url, options: nil, progressBlock: nil) { image, _, _, _ in
                guard let img = image else { return }
            }
            """
        ),
        Example(
            """
            foo({ }) { _ in
            ↓
              self.dismiss(animated: false, completion: {
              })
            }
            """
        ): Example(
            """
            foo({ }) { _ in
              self.dismiss(animated: false, completion: {
              })
            }
            """
        ),
    ]
    let id = "vertical_whitespace_opening_braces"
    let name = "Vertical Whitespace after Opening Braces"
    let summary = "Don't include vertical whitespace (empty line) after opening braces"
    let isCorrectable = true
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        (Self.violatingToValidExamples.values + Self.nonTriggeringExamples)
    }
    var triggeringExamples: [Example] {
        Array(Self.violatingToValidExamples.keys).sorted()
    }
    var corrections: [Example: Example] {
        Self.violatingToValidExamples.removingViolationMarkers()
    }
}
