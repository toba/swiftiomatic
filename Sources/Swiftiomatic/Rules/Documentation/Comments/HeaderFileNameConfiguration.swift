struct HeaderFileNameConfiguration: RuleConfiguration {
    let id = "header_file_name"
    let name = "Header File Name"
    let summary = "File name in header comment should match the actual file name"
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                // Correct.swift
                struct Foo {}
                """,
                configuration: ["file_name": "Correct.swift"],
              )
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                ↓// Wrong.swift
                struct Foo {}
                """,
                configuration: ["file_name": "Correct.swift"],
              )
            ]
    }
}
