struct StatementPositionConfiguration: RuleConfiguration {
    let id = "statement_position"
    let name = "Statement Position"
    let summary = "Else and catch should be on the same line, one space after the previous declaration"
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
              Example("} else if {"),
              Example("} else {"),
              Example("} catch {"),
              Example("\"}else{\""),
              Example("struct A { let catchphrase: Int }\nlet a = A(\n catchphrase: 0\n)"),
              Example("struct A { let `catch`: Int }\nlet a = A(\n `catch`: 0\n)"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("↓}else if {"),
              Example("↓}  else {"),
              Example("↓}\ncatch {"),
              Example("↓}\n\t  catch {"),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("↓}\n else {"): Example("} else {"),
              Example("↓}\n   else if {"): Example("} else if {"),
              Example("↓}\n catch {"): Example("} catch {"),
            ]
    }
}
