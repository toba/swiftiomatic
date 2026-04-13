import SwiftiomaticSyntax

extension UseEarlyExitsRule {
  static var nonTriggeringExamples: [Example] {
    [
      // Already using guard
      Example(
        """
        func foo() {
            guard condition else {
                return
            }
            doSomething()
        }
        """
      ),
      // if/else-if chain — don't flag
      Example(
        """
        func foo() {
            if condition {
                doSomething()
            } else if otherCondition {
                doSomethingElse()
                return
            }
        }
        """
      ),
      // Else doesn't exit
      Example(
        """
        func foo() {
            if condition {
                doSomething()
                doMore()
                doEvenMore()
                doYetMore()
            } else {
                handleError()
            }
        }
        """
      ),
      // Trivial true-block (3 or fewer statements)
      Example(
        """
        func foo() {
            if condition {
                doSomething()
            } else {
                return
            }
        }
        """
      ),
      // if/else-if/else chain — don't flag
      Example(
        """
        func foo() {
            if condition {
                doSomething()
            } else if otherCondition {
                doOtherThing()
            } else {
                doDefault()
                return
            }
        }
        """
      ),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      // Simple if/else with early return and long true-block
      Example(
        """
        func foo() {
            ↓if condition {
                doSomething()
                doMore()
                doEvenMore()
                doYetMore()
            } else {
                return
            }
        }
        """
      ),
      // Early throw
      Example(
        """
        func foo() throws {
            ↓if let value = optional {
                process(value)
                transform(value)
                validate(value)
                save(value)
            } else {
                throw MyError.missing
            }
        }
        """
      ),
      // Early break
      Example(
        """
        func foo() {
            for item in items {
                ↓if item.isValid {
                    process(item)
                    transform(item)
                    validate(item)
                    save(item)
                } else {
                    break
                }
            }
        }
        """
      ),
      // Else block with multiple statements ending in return
      Example(
        """
        func foo() {
            ↓if condition {
                doA()
                doB()
                doC()
                doD()
            } else {
                log("failing")
                return
            }
        }
        """
      ),
    ]
  }
}
