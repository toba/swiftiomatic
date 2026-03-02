struct VerticalParameterAlignmentOnCallConfiguration: RuleConfiguration {
    let id = "vertical_parameter_alignment_on_call"
    let name = "Vertical Parameter Alignment on Call"
    let summary = "Function parameters should be aligned vertically if they're in multiple lines in a method call"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                foo(param1: 1, param2: bar
                    param3: false, param4: true)
                """,
              ),
              Example(
                """
                foo(param1: 1, param2: bar)
                """,
              ),
              Example(
                """
                foo(param1: 1, param2: bar
                    param3: false,
                    param4: true)
                """,
              ),
              Example(
                """
                foo(
                   param1: 1
                ) { _ in }
                """,
              ),
              Example(
                """
                UIView.animate(withDuration: 0.4, animations: {
                    blurredImageView.alpha = 1
                }, completion: { _ in
                    self.hideLoading()
                })
                """,
              ),
              Example(
                """
                UIView.animate(withDuration: 0.4, animations: {
                    blurredImageView.alpha = 1
                },
                completion: { _ in
                    self.hideLoading()
                })
                """,
              ),
              Example(
                """
                UIView.animate(withDuration: 0.4, animations: {
                    blurredImageView.alpha = 1
                } { _ in
                    self.hideLoading()
                }
                """,
              ),
              Example(
                """
                foo(param1: 1, param2: { _ in },
                    param3: false, param4: true)
                """,
              ),
              Example(
                """
                foo({ _ in
                       bar()
                   },
                   completion: { _ in
                       baz()
                   }
                )
                """,
              ),
              Example(
                """
                foo(param1: 1, param2: [
                   0,
                   1
                ], param3: 0)
                """,
              ),
              Example(
                """
                myFunc(foo: 0,
                       bar: baz == 0)
                """,
              ),
              Example(
                """
                UIViewPropertyAnimator.runningPropertyAnimator(
                    withDuration: 2.0,
                    delay: 0.0,
                    options: [.curveEaseIn]
                ) {
                    // animations
                } completion: { _ in
                    // completion
                }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                foo(param1: 1, param2: bar,
                                ↓param3: false, param4: true)
                """,
              ),
              Example(
                """
                foo(param1: 1, param2: bar,
                 ↓param3: false, param4: true)
                """,
              ),
              Example(
                """
                foo(param1: 1, param2: bar,
                       ↓param3: false,
                       ↓param4: true)
                """,
              ),
              Example(
                """
                foo(param1: 1,
                       ↓param2: { _ in })
                """,
              ),
              Example(
                """
                foo(param1: 1,
                    param2: { _ in
                }, param3: 2,
                 ↓param4: 0)
                """,
              ),
              Example(
                """
                foo(param1: 1, param2: { _ in },
                       ↓param3: false, param4: true)
                """,
              ),
              Example(
                """
                myFunc(foo: 0,
                        ↓bar: baz == 0)
                """,
              ),
              Example(
                """
                myFunc(foo: 0, bar:
                        baz == 0, ↓baz: true)
                """,
              ),
            ]
    }
}
