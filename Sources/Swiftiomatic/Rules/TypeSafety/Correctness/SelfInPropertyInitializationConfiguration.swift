struct SelfInPropertyInitializationConfiguration: RuleConfiguration {
    let id = "self_in_property_initialization"
    let name = "Self in Property Initialization"
    let summary = "`self` refers to the unapplied `NSObject.self()` method, which is likely not expected; make the variable `lazy` to be able to refer to the current instance or use `ClassName.self`"
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                class View: UIView {
                    let button: UIButton = {
                        return UIButton()
                    }()
                }
                """,
              ),
              Example(
                """
                class View: UIView {
                    lazy var button: UIButton = {
                        let button = UIButton()
                        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
                        return button
                    }()
                }
                """,
              ),
              Example(
                """
                class View: UIView {
                    var button: UIButton = {
                        let button = UIButton()
                        button.addTarget(otherObject, action: #selector(didTapButton), for: .touchUpInside)
                        return button
                    }()
                }
                """,
              ),
              Example(
                """
                class View: UIView {
                    private let collectionView: UICollectionView = {
                        let layout = UICollectionViewFlowLayout()
                        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
                        collectionView.registerReusable(Cell.self)

                        return collectionView
                    }()
                }
                """,
              ),
              Example(
                """
                class Foo {
                    var bar: Bool = false {
                        didSet {
                            value = {
                                if bar {
                                    return self.calculateA()
                                } else {
                                    return self.calculateB()
                                }
                            }()
                            print(value)
                        }
                    }

                    var value: String?

                    func calculateA() -> String { "A" }
                    func calculateB() -> String { "B" }
                }
                """, isExcludedFromDocumentation: true,
              ),
              Example(
                """
                final class NotActuallyReferencingSelf {
                    let keyPath: Any = \\String.self
                    let someType: Any = String.self
                }
                """, isExcludedFromDocumentation: true,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                class View: UIView {
                    ↓var button: UIButton = {
                        let button = UIButton()
                        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
                        return button
                    }()
                }
                """,
              ),
              Example(
                """
                class View: UIView {
                    ↓let button: UIButton = {
                        let button = UIButton()
                        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
                        return button
                    }()
                }
                """,
              ),
            ]
    }
}
