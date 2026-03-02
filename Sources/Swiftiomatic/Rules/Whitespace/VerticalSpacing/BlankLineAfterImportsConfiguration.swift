struct BlankLineAfterImportsConfiguration: RuleConfiguration {
    let id = "blank_line_after_imports"
    let name = "Blank Line After Imports"
    let summary = "There should be a blank line after import statements"
    let scope: Scope = .format
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                import Foundation

                class Foo {}
                """),
              Example(
                """
                import Foundation
                import UIKit

                class Foo {}
                """),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                import Foundation
                ↓class Foo {}
                """)
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("import Foundation\n↓class Foo {}"): Example("import Foundation\n\nclass Foo {}")
            ]
    }
}
