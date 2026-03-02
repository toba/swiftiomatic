struct BlanketDisableCommandConfiguration: RuleConfiguration {
    let id = "blanket_disable_command"
    let name = "Blanket Disable Command"
    let summary = ""
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                // sm:disable unused_import
                // sm:enable unused_import
                """,
              ),
              Example(
                """
                // sm:disable unused_import unused_declaration
                // sm:enable unused_import
                // sm:enable unused_declaration
                """,
              ),
              Example("// sm:disable:this unused_import"),
              Example("// sm:disable:next unused_import"),
              Example("// sm:disable:previous unused_import"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("// sm:disable ↓unused_import"),
              Example(
                """
                // sm:disable unused_import ↓unused_declaration
                // sm:enable unused_import
                """,
              ),
              Example(
                """
                // sm:disable unused_import
                // sm:disable ↓unused_import
                // sm:enable unused_import
                """,
              ),
              Example(
                """
                // sm:enable ↓unused_import
                """,
              ),
              Example("// sm:disable all"),
            ]
    }
    let rationale: String? = """
      The intent of this rule is to prevent code like

      ```
      // sm:disable force_unwrapping
      let foo = bar!
      ```

      which disables the `force_unwrapping` rule for the remainder of the file, instead of just for the specific \
      violation.

      `next`, `this`, or `previous` can be used to restrict the disable command's scope to a single line, or it \
      can be re-enabled after the violations.

      To disable this rule in code you will need to do something like

      ```
      // sm:disable:next blanket_disable_command
      // sm:disable force_unwrapping
      ```
      """
}
