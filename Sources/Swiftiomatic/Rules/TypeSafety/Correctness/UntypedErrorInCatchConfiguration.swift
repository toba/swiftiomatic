struct UntypedErrorInCatchConfiguration: RuleConfiguration {
    let id = "untyped_error_in_catch"
    let name = "Untyped Error in Catch"
    let summary = "Catch statements should not declare error variables without type casting"
    let isCorrectable = true
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                do {
                  try foo()
                } catch {}
                """,
              ),
              Example(
                """
                do {
                  try foo()
                } catch Error.invalidOperation {
                } catch {}
                """,
              ),
              Example(
                """
                do {
                  try foo()
                } catch let error as MyError {
                } catch {}
                """,
              ),
              Example(
                """
                do {
                  try foo()
                } catch var error as MyError {
                } catch {}
                """,
              ),
              Example(
                """
                do {
                    try something()
                } catch let e where e.code == .fileError {
                    // can be ignored
                } catch {
                    print(error)
                }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                do {
                  try foo()
                } ↓catch var error {}
                """,
              ),
              Example(
                """
                do {
                  try foo()
                } ↓catch let error {}
                """,
              ),
              Example(
                """
                do {
                  try foo()
                } ↓catch let someError {}
                """,
              ),
              Example(
                """
                do {
                  try foo()
                } ↓catch var someError {}
                """,
              ),
              Example(
                """
                do {
                  try foo()
                } ↓catch let e {}
                """,
              ),
              Example(
                """
                do {
                  try foo()
                } ↓catch(let error) {}
                """,
              ),
              Example(
                """
                do {
                  try foo()
                } ↓catch (let error) {}
                """,
              ),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("do {\n    try foo() \n} ↓catch let error {}"): Example(
                "do {\n    try foo() \n} catch {}",
              ),
              Example("do {\n    try foo() \n} ↓catch(let error) {}"): Example(
                "do {\n    try foo() \n} catch {}",
              ),
              Example("do {\n    try foo() \n} ↓catch (let error) {}"): Example(
                "do {\n    try foo() \n} catch {}",
              ),
            ]
    }
}
