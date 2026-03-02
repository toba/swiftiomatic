struct DiscardedNotificationCenterObserverConfiguration: RuleConfiguration {
    let id = "discarded_notification_center_observer"
    let name = "Discarded Notification Center Observer"
    let summary = "When registering for a notification using a block, the opaque observer that is returned should be stored so it can be removed later"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                "let foo = nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil) { }",
              ),
              Example(
                """
                let foo = nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { })
                """,
              ),
              Example(
                """
                func foo() -> Any {
                    return nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { })
                }
                """,
              ),
              Example(
                """
                func foo() -> Any {
                    nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { })
                }
                """,
              ),
              Example(
                """
                var obs: [Any?] = []
                obs.append(nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { }))
                """,
              ),
              Example(
                """
                var obs: [String: Any?] = []
                obs["foo"] = nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { })
                """,
              ),
              Example(
                """
                var obs: [Any?] = []
                obs.append(nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { }))
                """,
              ),
              Example(
                """
                func foo(_ notify: Any) {
                   obs.append(notify)
                }
                foo(nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { }))
                """,
              ),
              Example(
                """
                var obs: [NSObjectProtocol] = [
                   nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { }),
                   nc.addObserver(forName: .CKAccountChanged, object: nil, queue: nil, using: { })
                ]
                """,
              ),
              Example(
                """
                names.map { self.notificationCenter.addObserver(forName: $0, object: object, queue: queue, using: block) }
                """,
              ),
              Example(
                """
                f { return nc.addObserver(forName: $0, object: object, queue: queue, using: block) }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                "↓nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil) { }",
              ),
              Example(
                "_ = ↓nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil) { }",
              ),
              Example(
                "↓nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { })",
              ),
              Example(
                """
                @discardableResult func foo() -> Any {
                   return ↓nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { })
                }
                """,
              ),
              Example(
                """
                class C {
                    var i: Int {
                        set { ↓notificationCenter.addObserver(forName: $0, object: object, queue: queue, using: block) }
                        get {
                            ↓notificationCenter.addObserver(forName: $0, object: object, queue: queue, using: block)
                            return 2
                        }
                    }
                }
                """,
              ),
              Example(
                """
                f {
                    ↓nc.addObserver(forName: $0, object: object, queue: queue) {}
                    return 2
                }
                """,
              ),
              Example(
                """
                func foo() -> Any {
                    if cond {
                        ↓nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { })
                    }
                }
                """,
              ),
            ]
    }
}
