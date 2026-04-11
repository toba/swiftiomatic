import SwiftUI
import Swiftiomatic

struct RuleRow: View {
  @Environment(AppModel.self) private var model
  let entry: RuleConfigurationEntry

  var body: some View {
    HStack {
      Toggle(
        isOn: Binding(
          get: { model.isRuleEnabled(entry) },
          set: { _ in model.toggleRule(entry) }
        )
      ) {
        VStack(alignment: .leading, spacing: 2) {
          HStack(spacing: 6) {
            Text(entry.name)
              .fontWeight(.medium)
            ScopeBadge(scope: entry.scope)
            if entry.isCorrectable {
              Image(systemName: "wrench.fill")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .help("Auto-correctable")
            }
          }
          Text(entry.id)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      .toggleStyle(.switch)
      .controlSize(.small)
    }
  }
}
