struct ForWhereConfiguration: RuleConfiguration {
    let id = "for_where"
    let name = "Prefer For-Where"
    let summary = "`where` clauses are preferred over a single `if` inside a `for`"
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                for user in users where user.id == 1 { }
                """,
              ),
              // if let
              Example(
                """
                for user in users {
                  if let id = user.id { }
                }
                """,
              ),
              // if var
              Example(
                """
                for user in users {
                  if var id = user.id { }
                }
                """,
              ),
              // if with else
              Example(
                """
                for user in users {
                  if user.id == 1 { } else { }
                }
                """,
              ),
              // if with else if
              Example(
                """
                for user in users {
                  if user.id == 1 {
                  } else if user.id == 2 { }
                }
                """,
              ),
              // if is not the only expression inside for
              Example(
                """
                for user in users {
                  if user.id == 1 { }
                  print(user)
                }
                """,
              ),
              // if a variable is used
              Example(
                """
                for user in users {
                  let id = user.id
                  if id == 1 { }
                }
                """,
              ),
              // if something is after if
              Example(
                """
                for user in users {
                  if user.id == 1 { }
                  return true
                }
                """,
              ),
              // condition with multiple clauses
              Example(
                """
                for user in users {
                  if user.id == 1 && user.age > 18 { }
                }
                """,
              ),
              Example(
                """
                for user in users {
                  if user.id == 1, user.age > 18 { }
                }
                """,
              ),
              // if case
              Example(
                """
                for (index, value) in array.enumerated() {
                  if case .valueB(_) = value {
                    return index
                  }
                }
                """,
              ),
              Example(
                """
                for user in users {
                  if user.id == 1 { return true }
                }
                """, configuration: ["allow_for_as_filter": true],
              ),
              Example(
                """
                for user in users {
                  if user.id == 1 {
                    let derivedValue = calculateValue(from: user)
                    return derivedValue != 0
                  }
                }
                """, configuration: ["allow_for_as_filter": true],
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                for user in users {
                  ↓if user.id == 1 { return true }
                }
                """,
              ),
              Example(
                """
                for subview in subviews {
                    ↓if !(subview is UIStackView) {
                        subview.removeConstraints(subview.constraints)
                        subview.removeFromSuperview()
                    }
                }
                """,
              ),
              Example(
                """
                for subview in subviews {
                    ↓if !(subview is UIStackView) {
                        subview.removeConstraints(subview.constraints)
                        subview.removeFromSuperview()
                    }
                }
                """, configuration: ["allow_for_as_filter": true],
              ),
            ]
    }
}
