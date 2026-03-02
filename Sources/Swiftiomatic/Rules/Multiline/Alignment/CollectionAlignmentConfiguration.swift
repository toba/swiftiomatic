struct CollectionAlignmentConfiguration: RuleConfiguration {
    let id = "collection_alignment"
    let name = "Collection Element Alignment"
    let summary = "All elements in a collection literal should be vertically aligned"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        Examples(alignColons: false).nonTriggeringExamples
    }
    var triggeringExamples: [Example] {
        Examples(alignColons: false).triggeringExamples
    }

    struct Examples {
        private let alignColons: Bool

        init(alignColons: Bool) {
            self.alignColons = alignColons
        }

        var triggeringExamples: [Example] {
            let examples = alignColons ? alignColonsTriggeringExamples : alignLeftTriggeringExamples
            return examples + sharedTriggeringExamples
        }

        var nonTriggeringExamples: [Example] {
            let examples = alignColons ? alignColonsNonTriggeringExamples : alignLeftNonTriggeringExamples
            return examples + sharedNonTriggeringExamples
        }

        private var alignColonsTriggeringExamples: [Example] {
            [
                Example(
                    """
                    doThings(arg: [
                        "foo": 1,
                        "bar": 2,
                        "fizz"↓: 2,
                        "buzz"↓: 2
                    ])
                    """,
                ),
                Example(
                    """
                    let abc = [
                        "alpha": "a",
                        "beta"↓: "b",
                        "gamma": "c",
                        "delta": "d",
                        "epsilon"↓: "e"
                    ]
                    """,
                ),
                Example(
                    """
                    var weirdColons = [
                        "a"    :  1,
                        "b"  ↓:2,
                        "c"    :      3
                    ]
                    """,
                ),
            ]
        }

        private var alignColonsNonTriggeringExamples: [Example] {
            [
                Example(
                    """
                    doThings(arg: [
                        "foo": 1,
                        "bar": 2,
                       "fizz": 2,
                       "buzz": 2
                    ])
                    """,
                ),
                Example(
                    """
                    let abc = [
                        "alpha": "a",
                         "beta": "b",
                        "gamma": "g",
                        "delta": "d",
                      "epsilon": "e"
                    ]
                    """,
                ),
                Example(
                    """
                    var weirdColons = [
                        "a"    :  1,
                          "b"  :2,
                           "c" :      3
                    ]
                    """,
                ),
                Example(
                    """
                    NSAttributedString(string: "…", attributes: [.font: UIFont.systemFont(ofSize: 12, weight: .regular),
                                                      .foregroundColor: UIColor(white: 0, alpha: 0.2)])
                    """,
                ),
            ]
        }

        private var alignLeftTriggeringExamples: [Example] {
            [
                Example(
                    """
                    doThings(arg: [
                        "foo": 1,
                        "bar": 2,
                       ↓"fizz": 2,
                       ↓"buzz": 2
                    ])
                    """,
                ),
                Example(
                    """
                    let abc = [
                        "alpha": "a",
                         ↓"beta": "b",
                        "gamma": "g",
                        "delta": "d",
                      ↓"epsilon": "e"
                    ]
                    """,
                ),
                Example(
                    """
                    let meals = [
                                    "breakfast": "oatmeal",
                                    "lunch": "sandwich",
                        ↓"dinner": "burger"
                    ]
                    """,
                ),
            ]
        }

        private var alignLeftNonTriggeringExamples: [Example] {
            [
                Example(
                    """
                    doThings(arg: [
                        "foo": 1,
                        "bar": 2,
                        "fizz": 2,
                        "buzz": 2
                    ])
                    """,
                ),
                Example(
                    """
                    let abc = [
                        "alpha": "a",
                        "beta": "b",
                        "gamma": "g",
                        "delta": "d",
                        "epsilon": "e"
                    ]
                    """,
                ),
                Example(
                    """
                    let meals = [
                                    "breakfast": "oatmeal",
                                    "lunch": "sandwich",
                                    "dinner": "burger"
                    ]
                    """,
                ),
                Example(
                    """
                    NSAttributedString(string: "…", attributes: [.font: UIFont.systemFont(ofSize: 12, weight: .regular),
                                                                 .foregroundColor: UIColor(white: 0, alpha: 0.2)])
                    """,
                ),
            ]
        }

        private var sharedTriggeringExamples: [Example] {
            [
                Example(
                    """
                    let coordinates = [
                        CLLocationCoordinate2D(latitude: 0, longitude: 33),
                            ↓CLLocationCoordinate2D(latitude: 0, longitude: 66),
                        CLLocationCoordinate2D(latitude: 0, longitude: 99)
                    ]
                    """,
                ),
                Example(
                    """
                    var evenNumbers: Set<Int> = [
                        2,
                      ↓4,
                        6
                    ]
                    """,
                ),
            ]
        }

        private var sharedNonTriggeringExamples: [Example] {
            [
                Example(
                    """
                    let coordinates = [
                        CLLocationCoordinate2D(latitude: 0, longitude: 33),
                        CLLocationCoordinate2D(latitude: 0, longitude: 66),
                        CLLocationCoordinate2D(latitude: 0, longitude: 99)
                    ]
                    """,
                ),
                Example(
                    """
                    var evenNumbers: Set<Int> = [
                        2,
                        4,
                        6
                    ]
                    """,
                ),
                Example(
                    """
                    let abc = [1, 2, 3, 4]
                    """,
                ),
                Example(
                    """
                    let abc = [
                        1, 2, 3, 4
                    ]
                    """,
                ),
                Example(
                    """
                    let abc = [
                        "foo": "bar", "fizz": "buzz"
                    ]
                    """,
                ),
            ]
        }
    }
}
