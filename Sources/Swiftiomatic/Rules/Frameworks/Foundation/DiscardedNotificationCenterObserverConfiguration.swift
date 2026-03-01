struct DiscardedNotificationCenterObserverConfiguration: RuleConfiguration {
    let id = "discarded_notification_center_observer"
    let name = "Discarded Notification Center Observer"
    let summary = "When registering for a notification using a block, the opaque observer that is returned should be stored so it can be removed later"
    let isOptIn = true
}
