struct FileLengthConfiguration: RuleConfiguration {
    let id = "file_length"
    let name = "File Length"
    let summary = "Files should not span too many lines."
    var nonTriggeringExamples: [Example] {
        [
              Example(repeatElement("print(\"swiftlint\")\n", count: 399).joined())
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(repeatElement("print(\"swiftlint\")\n", count: 401).joined()),
              Example((repeatElement("print(\"swiftlint\")\n", count: 400) + ["//\n"]).joined()),
              Example(repeatElement("print(\"swiftlint\")\n\n", count: 201).joined()),
            ]
    }
}
