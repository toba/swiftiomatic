struct FileHeaderConfiguration: RuleConfiguration {
    let id = "file_header"
    let name = "File Header"
    let summary = "Header comments should be consistent with project patterns. The CURRENT_FILENAME placeholder can optionally be used in the required and forbidden patterns. It will be replaced by the real file name."
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("let foo = \"Copyright\""),
              Example("let foo = 2 // Copyright"),
              Example("let foo = 2\n // Copyright"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("// ↓Copyright"),
              Example("//\n// ↓Copyright"),
              Example(
                """
                //
                //  FileHeaderRule.swift
                //  Swiftiomatic
                //
                //  Created by Marcelo Fabri on 27/11/16.
                //  ↓Copyright © 2016 Realm. All rights reserved.
                //
                """,
              ),
            ]
    }
}
