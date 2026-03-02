struct MultilineLiteralBracketsConfiguration: RuleConfiguration {
    let id = "multiline_literal_brackets"
    let name = "Multiline Literal Brackets"
    let summary = "Multiline literals should have their surrounding brackets in a new line"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                let trio = ["harry", "ronald", "hermione"]
                let houseCup = ["gryffindor": 460, "hufflepuff": 370, "ravenclaw": 410, "slytherin": 450]
                """,
              ),
              Example(
                """
                let trio = [
                    "harry",
                    "ronald",
                    "hermione"
                ]
                let houseCup = [
                    "gryffindor": 460,
                    "hufflepuff": 370,
                    "ravenclaw": 410,
                    "slytherin": 450
                ]
                """,
              ),
              Example(
                """
                let trio = [
                    "harry", "ronald", "hermione"
                ]
                let houseCup = [
                    "gryffindor": 460, "hufflepuff": 370,
                    "ravenclaw": 410, "slytherin": 450
                ]
                """,
              ),
              Example(
                """
                _ = [
                    1,
                    2,
                    3,
                    4,
                    5, 6,
                    7, 8, 9
                ]
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                let trio = [↓"harry",
                            "ronald",
                            "hermione"
                ]
                """,
              ),
              Example(
                """
                let houseCup = [↓"gryffindor": 460, "hufflepuff": 370,
                                "ravenclaw": 410, "slytherin": 450
                ]
                """,
              ),
              Example(
                """
                let houseCup = [↓"gryffindor": 460,
                                "hufflepuff": 370,
                                "ravenclaw": 410,
                                "slytherin": 450↓]
                """,
              ),
              Example(
                """
                let trio = [
                    "harry",
                    "ronald",
                    "hermione"↓]
                """,
              ),
              Example(
                """
                let houseCup = [
                    "gryffindor": 460, "hufflepuff": 370,
                    "ravenclaw": 410, "slytherin": 450↓]
                """,
              ),
              Example(
                """
                class Hogwarts {
                    let houseCup = [
                        "gryffindor": 460, "hufflepuff": 370,
                        "ravenclaw": 410, "slytherin": 450↓]
                }
                """,
              ),
              Example(
                """
                _ = [
                    1,
                    2,
                    3,
                    4,
                    5, 6,
                    7, 8, 9↓]
                """,
              ),
              Example(
                """
                _ = [↓1, 2, 3,
                     4, 5, 6,
                     7, 8, 9
                ]
                """,
              ),
              Example(
                """
                class Hogwarts {
                    let houseCup = [
                        "gryffindor": 460, "hufflepuff": 370,
                        "ravenclaw": 410, "slytherin": slytherinPoints.filter {
                            $0.isValid
                        }.sum()↓]
                }
                """,
              ),
            ]
    }
}
