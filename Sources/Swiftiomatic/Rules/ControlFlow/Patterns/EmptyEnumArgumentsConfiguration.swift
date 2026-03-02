struct EmptyEnumArgumentsConfiguration: RuleConfiguration {
    let id = "empty_enum_arguments"
    let name = "Empty Enum Arguments"
    let summary = "Arguments can be omitted when matching enums with associated values if they are not used"
    let isCorrectable = true

    private static func wrapInSwitch(
      variable: String = "foo",
      _ str: String,
      file: StaticString = #filePath,
      line: UInt = #line,
    ) -> Example {
      Example(
        """
        switch \(variable) {
        \(str): break
        }
        """, file: file, line: line,
      )
    }

    private static func wrapInFunc(_ str: String, file: StaticString = #filePath, line: UInt = #line)
      -> Example
    {
      Example(
        """
        func example(foo: Foo) {
            switch foo {
            \(str):
                break
            }
        }
        """, file: file, line: line,
      )
    }

    var nonTriggeringExamples: [Example] {
        [
              Self.wrapInSwitch("case .bar"),
              Self.wrapInSwitch("case .bar(let x)"),
              Self.wrapInSwitch("case let .bar(x)"),
              Self.wrapInSwitch(variable: "(foo, bar)", "case (_, _)"),
              Self.wrapInSwitch("case \"bar\".uppercased()"),
              Self.wrapInSwitch(variable: "(foo, bar)", "case (_, _) where !something"),
              Self.wrapInSwitch("case (let f as () -> String)?"),
              Self.wrapInSwitch("case .bar(Baz())"),
              Self.wrapInSwitch("case .bar(.init())"),
              Self.wrapInSwitch("default"),
              Example("if case .bar = foo {\n}"),
              Example("guard case .bar = foo else {\n}"),
              Example("if foo == .bar() {}"),
              Example("guard foo == .bar() else { return }"),
              Example(
                """
                if case .appStore = self.appInstaller, !UIDevice.isSimulator() {
                    viewController.present(self, animated: false)
                } else {
                    UIApplication.shared.open(self.appInstaller.url)
                }
                """,
              ),
              Example(
                """
                let updatedUserNotificationSettings = deepLink.filter { nav in
                    guard case .settings(.notifications(_, nil)) = nav else { return false }
                    return true
                }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Self.wrapInSwitch("case .bar↓(_)"),
              Self.wrapInSwitch("case .bar↓()"),
              Self.wrapInSwitch("case .bar↓(_), .bar2↓(_)"),
              Self.wrapInSwitch("case .bar↓() where method() > 2"),
              Self.wrapInSwitch("case .bar(.baz↓())"),
              Self.wrapInSwitch("case .bar(.baz↓(_))"),
              Self.wrapInFunc("case .bar↓(_)"),
              Example("if case .bar↓(_) = foo {\n}"),
              Example("guard case .bar↓(_) = foo else {\n}"),
              Example("if case .bar↓() = foo {\n}"),
              Example("guard case .bar↓() = foo else {\n}"),
              Example(
                """
                if case .appStore↓(_) = self.appInstaller, !UIDevice.isSimulator() {
                    viewController.present(self, animated: false)
                } else {
                    UIApplication.shared.open(self.appInstaller.url)
                }
                """,
              ),
              Example(
                """
                let updatedUserNotificationSettings = deepLink.filter { nav in
                    guard case .settings(.notifications↓(_, _)) = nav else { return false }
                    return true
                }
                """,
              ),
            ]
    }
    var corrections: [Example: Example] {
        [
              Self.wrapInSwitch("case .bar↓(_)"): Self.wrapInSwitch("case .bar"),
              Self.wrapInSwitch("case .bar↓()"): Self.wrapInSwitch("case .bar"),
              Self.wrapInSwitch("case .bar↓(_), .bar2↓(_)"): Self.wrapInSwitch("case .bar, .bar2"),
              Self.wrapInSwitch("case .bar↓() where method() > 2"): Self.wrapInSwitch(
                "case .bar where method() > 2",
              ),
              Self.wrapInSwitch("case .bar(.baz↓())"): Self.wrapInSwitch("case .bar(.baz)"),
              Self.wrapInSwitch("case .bar(.baz↓(_))"): Self.wrapInSwitch("case .bar(.baz)"),
              Self.wrapInFunc("case .bar↓(_)"): Self.wrapInFunc("case .bar"),
              Example("if case .bar↓(_) = foo {"): Example("if case .bar = foo {"),
              Example("guard case .bar↓(_) = foo else {"): Example("guard case .bar = foo else {"),
              Example(
                """
                let updatedUserNotificationSettings = deepLink.filter { nav in
                    guard case .settings(.notifications↓(_, _)) = nav else { return false }
                    return true
                }
                """,
              ):
                Example(
                  """
                  let updatedUserNotificationSettings = deepLink.filter { nav in
                      guard case .settings(.notifications) = nav else { return false }
                      return true
                  }
                  """,
                ),
            ]
    }
}
