import SwiftiomaticSyntax

// sm:disable file_length
extension ValidateDocumentationCommentsRule {
  static var nonTriggeringExamples: [Example] {
    [
      // Valid singular parameter
      Example(
        """
        /// Returns the output for a command.
        ///
        /// - Parameter command: The command to execute.
        /// - Returns: A string with the output.
        func run(command: String) -> String { "" }
        """
      ),
      // Valid plural parameters
      Example(
        """
        /// Executes a command with stdin.
        ///
        /// - Parameters:
        ///   - command: The command to execute.
        ///   - stdin: The standard input.
        /// - Throws: An error on failure.
        /// - Returns: The output string.
        func run(command: String, stdin: String) throws -> String { "" }
        """
      ),
      // Summary-only doc comment (no tags) — always valid
      Example(
        """
        /// Brief summary of the function.
        func doSomething(value: Int) {}
        """
      ),
      // Rethrowing function — throws doc not required
      Example(
        """
        /// Brief summary.
        ///
        /// - Parameter body: The closure to run.
        func wrapper(body: () throws -> Void) rethrows {}
        """
      ),
      // Never return type — Returns doc not required
      Example(
        """
        /// Terminates the process.
        ///
        /// - Parameter code: The exit code.
        func terminate(code: Int) -> Never { fatalError() }
        """
      ),
      // Void return — Returns doc not required
      Example(
        """
        /// Does work.
        ///
        /// - Parameter count: How many times.
        func work(count: Int) {}
        """
      ),
      // Label differs from identifier — identifier should be documented
      Example(
        """
        /// Runs a command.
        ///
        /// - Parameter command: The command.
        /// - Returns: Output.
        func run(label command: String) -> String { "" }
        """
      ),
      // Initializer with correct params
      Example(
        """
        struct Foo {
            /// Creates a Foo.
            ///
            /// - Parameter value: The value.
            init(value: Int) {}
        }
        """
      ),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      // Plural Parameters: used for single param
      Example(
        """
        /// Summary.
        ///
        /// - Parameters:
        ///   - value: The value.
        /// - Returns: A string.
        ↓func foo(value: Int) -> String { "" }
        """
      ),
      // Singular Parameter used for multiple params
      Example(
        """
        /// Summary.
        ///
        /// - Parameter a: First.
        /// - Parameter b: Second.
        /// - Returns: A string.
        ↓func foo(a: Int, b: Int) -> String { "" }
        """
      ),
      // Parameter names don't match
      Example(
        """
        /// Summary.
        ///
        /// - Parameters:
        ///   - x: Wrong name.
        ///   - y: Wrong name.
        /// - Returns: An int.
        ↓func foo(a: Int, b: Int) -> Int { 0 }
        """
      ),
      // Missing Returns: for non-Void function
      Example(
        """
        /// Summary.
        ///
        /// - Parameter value: The value.
        func foo(value: Int) ↓-> Int { 0 }
        """
      ),
      // Returns: present but function returns Void
      Example(
        """
        /// Summary.
        ///
        /// - Parameter value: The value.
        /// - Returns: Nothing really.
        ↓func foo(value: Int) {}
        """
      ),
      // Missing Throws: for throwing function
      Example(
        """
        /// Summary.
        ///
        /// - Parameters:
        ///   - a: First.
        ///   - b: Second.
        func foo(a: Int, b: Int) ↓throws {}
        """
      ),
      // Throws: present but function doesn't throw
      Example(
        """
        /// Summary.
        ///
        /// - Parameter value: The value.
        /// - Throws: An error.
        ↓func foo(value: Int) {}
        """
      ),
      // Initializer with mismatched param and spurious Returns
      Example(
        """
        struct Foo {
            /// Brief.
            ///
            /// - Parameter wrong: Not a real param.
            /// - Returns: Shouldn't be here.
            ↓init(label command: String) {}
        }
        """
      ),
    ]
  }
}
