struct LegacyObjcTypeConfiguration: RuleConfiguration {
    let id = "legacy_objc_type"
    let name = "Legacy Objective-C Reference Type"
    let summary = "Prefer Swift value types to bridged Objective-C reference types"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("var array = Array<Int>()"),
              Example("var calendar: Calendar? = nil"),
              Example("var formatter: NSDataDetector"),
              Example("var className: String = NSStringFromClass(MyClass.self)"),
              Example("_ = URLRequest.CachePolicy.reloadIgnoringLocalCacheData"),
              Example(#"_ = Notification.Name("com.apple.Music.playerInfo")"#),
              Example(
                #"""
                class SLURLRequest: NSURLRequest {
                    let data = NSData()
                    let number: NSNumber
                }
                """#, configuration: ["allowed_types": ["NSData", "NSNumber", "NSURLRequest"]],
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("var array = ↓NSArray()"),
              Example("var calendar: ↓NSCalendar? = nil"),
              Example("_ = ↓NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData"),
              Example(#"_ = ↓NSNotification.Name("com.apple.Music.playerInfo")"#),
              Example(
                #"""
                let keyValuePair: (Int) -> (↓NSString, ↓NSString) = {
                  let n = "\($0)" as ↓NSString; return (n, n)
                }
                dictionary = [↓NSString: ↓NSString](uniqueKeysWithValues:
                  (1...10_000).lazy.map(keyValuePair))
                """#,
              ),
              Example(
                """
                extension Foundation.Notification.Name {
                    static var reachabilityChanged: Foundation.↓NSNotification.Name {
                        return Foundation.Notification.Name("org.wordpress.reachability.changed")
                    }
                }
                """,
              ),
            ]
    }
}
