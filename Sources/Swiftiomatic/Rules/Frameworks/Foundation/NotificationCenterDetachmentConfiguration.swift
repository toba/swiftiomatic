struct NotificationCenterDetachmentConfiguration: RuleConfiguration {
    let id = "notification_center_detachment"
    let name = "Notification Center Detachment"
    let summary = "An object should only remove itself as an observer in `deinit`"
}
