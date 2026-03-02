struct ProhibitedSuperConfiguration: RuleConfiguration {
    let id = "prohibited_super_call"
    let name = "Prohibited Calls to Super"
    let summary = "Some methods should not call super."
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                class VC: UIViewController {
                    override func loadView() {
                    }
                }
                """,
              ),
              Example(
                """
                class NSView {
                    func updateLayer() {
                        self.method1()
                    }
                }
                """,
              ),
              Example(
                """
                public class FileProviderExtension: NSFileProviderExtension {
                    override func providePlaceholder(at url: URL, completionHandler: @escaping (Error?) -> Void) {
                        guard let identifier = persistentIdentifierForItem(at: url) else {
                            completionHandler(NSFileProviderError(.noSuchItem))
                            return
                        }
                    }
                }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                class VC: UIViewController {
                    override func loadView() {↓
                        super.loadView()
                    }
                }
                """,
              ),
              Example(
                """
                class VC: NSFileProviderExtension {
                    override func providePlaceholder(at url: URL, completionHandler: @escaping (Error?) -> Void) {↓
                        self.method1()
                        super.providePlaceholder(at:url, completionHandler: completionHandler)
                    }
                }
                """,
              ),
              Example(
                """
                class VC: NSView {
                    override func updateLayer() {↓
                        self.method1()
                        super.updateLayer()
                        self.method2()
                    }
                }
                """,
              ),
              Example(
                """
                class VC: NSView {
                    override func updateLayer() {↓
                        defer {
                            super.updateLayer()
                        }
                    }
                }
                """,
              ),
            ]
    }
}
