struct UnhandledThrowingTaskConfiguration: RuleConfiguration {
    let id = "unhandled_throwing_task"
    let name = "Unhandled Throwing Task"
    let summary = ""
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                Task<Void, Never> {
                  try await myThrowingFunction()
                }
                """,
              ),
              Example(
                """
                Task {
                  try? await myThrowingFunction()
                }
                """,
              ),
              Example(
                """
                Task {
                  try! await myThrowingFunction()
                }
                """,
              ),
              Example(
                """
                Task<Void, String> {
                  let text = try myThrowingFunction()
                  return text
                }
                """,
              ),
              Example(
                """
                Task {
                  do {
                    try myThrowingFunction()
                  } catch let e {
                    print(e)
                  }
                }
                """,
              ),
              Example(
                """
                func someFunction() throws {
                  Task {
                    anotherFunction()
                    do {
                      try myThrowingFunction()
                    } catch {
                      print(error)
                    }
                  }

                  try something()
                }
                """,
              ),
              Example(
                """
                let task = Task {
                  try await myThrowingFunction()
                }
                """,
              ),
              Example(
                """
                var task = Task {
                  try await myThrowingFunction()
                }
                """,
              ),
              Example(
                """
                try await Task {
                  try await myThrowingFunction()
                }.value
                """,
              ),
              Example(
                """
                executor.task = Task {
                  try await isolatedOpen(.init(executor.asUnownedSerialExecutor()))
                }
                """,
              ),
              Example(
                """
                let result = await Task {
                  throw CancellationError()
                }.result
                """,
              ),
              Example(
                """
                func makeTask() -> Task<String, Error> {
                  return Task {
                    try await someThrowingFunction()
                  }
                }
                """,
              ),
              Example(
                """
                func makeTask() -> Task<String, Error> {
                  // Implicit return
                  Task {
                    try await someThrowingFunction()
                  }
                }
                """,
              ),
              Example(
                """
                Task {
                  return Result {
                      try someThrowingFunc()
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
                ↓Task {
                  try await myThrowingFunction()
                }
                """,
              ),
              Example(
                """
                ↓Task {
                  let text = try myThrowingFunction()
                  return text
                }
                """,
              ),
              Example(
                """
                ↓Task {
                  do {
                    try myThrowingFunction()
                  }
                }
                """,
              ),
              Example(
                """
                ↓Task {
                  do {
                    try myThrowingFunction()
                  } catch let e as FooError {
                    print(e)
                  }
                }
                """,
              ),
              Example(
                """
                ↓Task {
                  do {
                    throw FooError.bar
                  }
                }
                """,
              ),
              Example(
                """
                ↓Task {
                  throw FooError.bar
                }
                """,
              ),
              Example(
                """
                ↓Task<_, _> {
                  throw FooError.bar
                }
                """,
              ),
              Example(
                """
                ↓Task<Void,_> {
                  throw FooError.bar
                }
                """,
              ),
              Example(
                """
                ↓Task {
                  do {
                    try foo()
                  } catch {
                    try bar()
                  }
                }
                """,
              ),
              Example(
                """
                ↓Task {
                  do {
                    try foo()
                  } catch {
                    throw BarError()
                  }
                }
                """,
              ),
              Example(
                """
                func doTask() {
                  ↓Task {
                    try await someThrowingFunction()
                  }
                }
                """,
              ),
            ]
    }
}
