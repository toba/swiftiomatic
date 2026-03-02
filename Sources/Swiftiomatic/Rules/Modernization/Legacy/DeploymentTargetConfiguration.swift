struct DeploymentTargetConfiguration: RuleConfiguration {
    let id = "deployment_target"
    let name = "Deployment Target"
    let summary = "Availability checks or attributes shouldn't be using older versions that are satisfied by the deployment target."
    var nonTriggeringExamples: [Example] {
        DeploymentTargetRuleExamples.nonTriggeringExamples
    }
    var triggeringExamples: [Example] {
        DeploymentTargetRuleExamples.triggeringExamples
    }
}
