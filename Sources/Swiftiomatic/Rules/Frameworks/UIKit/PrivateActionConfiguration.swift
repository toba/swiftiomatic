struct PrivateActionConfiguration: RuleConfiguration {
    let id = "private_action"
    let name = "Private Actions"
    let summary = "IBActions should be private"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example(
                "class Foo {\n\t@IBAction private func barButtonTapped(_ sender: UIButton) {}\n}",
              ),
              Example(
                "struct Foo {\n\t@IBAction private func barButtonTapped(_ sender: UIButton) {}\n}",
              ),
              Example(
                "class Foo {\n\t@IBAction fileprivate func barButtonTapped(_ sender: UIButton) {}\n}",
              ),
              Example(
                "struct Foo {\n\t@IBAction fileprivate func barButtonTapped(_ sender: UIButton) {}\n}",
              ),
              Example(
                "private extension Foo {\n\t@IBAction func barButtonTapped(_ sender: UIButton) {}\n}",
              ),
              Example(
                "fileprivate extension Foo {\n\t@IBAction func barButtonTapped(_ sender: UIButton) {}\n}",
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("class Foo {\n\t@IBAction ↓func barButtonTapped(_ sender: UIButton) {}\n}"),
              Example("struct Foo {\n\t@IBAction ↓func barButtonTapped(_ sender: UIButton) {}\n}"),
              Example(
                "class Foo {\n\t@IBAction public ↓func barButtonTapped(_ sender: UIButton) {}\n}",
              ),
              Example(
                "struct Foo {\n\t@IBAction public ↓func barButtonTapped(_ sender: UIButton) {}\n}",
              ),
              Example(
                "class Foo {\n\t@IBAction internal ↓func barButtonTapped(_ sender: UIButton) {}\n}",
              ),
              Example(
                "struct Foo {\n\t@IBAction internal ↓func barButtonTapped(_ sender: UIButton) {}\n}",
              ),
              Example("extension Foo {\n\t@IBAction ↓func barButtonTapped(_ sender: UIButton) {}\n}"),
              Example(
                "extension Foo {\n\t@IBAction public ↓func barButtonTapped(_ sender: UIButton) {}\n}",
              ),
              Example(
                "extension Foo {\n\t@IBAction internal ↓func barButtonTapped(_ sender: UIButton) {}\n}",
              ),
              Example(
                "public extension Foo {\n\t@IBAction ↓func barButtonTapped(_ sender: UIButton) {}\n}",
              ),
              Example(
                "internal extension Foo {\n\t@IBAction ↓func barButtonTapped(_ sender: UIButton) {}\n}",
              ),
            ]
    }
}
