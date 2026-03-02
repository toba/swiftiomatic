struct FunctionDefaultParameterAtEndConfiguration: RuleConfiguration {
    let id = "function_default_parameter_at_end"
    let name = "Function Default Parameter at End"
    let summary = "Prefer to locate parameters with defaults toward the end of the parameter list"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("func foo(baz: String, bar: Int = 0) {}"),
              Example("func foo(x: String, y: Int = 0, z: CGFloat = 0) {}"),
              Example("func foo(bar: String, baz: Int = 0, z: () -> Void) {}"),
              Example("func foo(bar: String, z: () -> Void, baz: Int = 0) {}"),
              Example("func foo(bar: Int = 0) {}"),
              Example("func foo() {}"),
              Example(
                """
                class A: B {
                  override func foo(bar: Int = 0, baz: String) {}
                """,
              ),
              Example("func foo(bar: Int = 0, completion: @escaping CompletionHandler) {}"),
              Example(
                """
                func foo(a: Int, b: CGFloat = 0) {
                  let block = { (error: Error?) in }
                }
                """,
              ),
              Example(
                """
                func foo(a: String, b: String? = nil,
                         c: String? = nil, d: @escaping AlertActionHandler = { _ in }) {}
                """,
              ),
              Example(
                "override init?(for date: Date = Date(), coordinate: CLLocationCoordinate2D) {}",
              ),
              Example(
                """
                func handleNotification(_ userInfo: NSDictionary,
                                        userInteraction: Bool = false,
                                        completionHandler: ((UIBackgroundFetchResult) -> Void)?) {}
                """,
              ),
              Example(
                """
                func write(withoutNotifying tokens: [NotificationToken] =  {}, _ block: (() throws -> Int)) {}
                """,
              ),
              Example(
                """
                func expect<T>(file: String = #file, _ expression: @autoclosure () -> (() throws -> T)) -> Expectation<T> {}
                """, isExcludedFromDocumentation: true,
              ),
              Example("func foo(bar: Int, baz: Int = 0, z: () -> Void) {}"),
              Example("func foo(bar: Int, baz: Int = 0, z: () -> Void, x: Int = 0) {}"),
              Example("func foo(isolation: isolated (any Actor)? = #isolation, bar: String) {}"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("func foo(↓bar: Int = 0, baz: String) {}"),
              Example("private func foo(↓bar: Int = 0, baz: String) {}"),
              Example(
                "public init?(↓for date: Date = Date(), coordinate: CLLocationCoordinate2D) {}",
              ),
              Example("func foo(bar: Int, ↓baz: Int = 0, z: () -> Void, x: Int) {}"),
              Example(
                "func foo(isolation: isolated (any Actor)? = #isolation, bar: String) {}",
                configuration: ["ignore_first_isolation_inheritance_parameter": false],
              ),
            ]
    }
}
