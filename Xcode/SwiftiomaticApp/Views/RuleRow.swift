import SwiftUI
import SwiftiomaticKit
import SwiftiomaticSyntax

struct RuleRow: View {
    @Bindable var document: SwiftiomaticDocument
    let entry: RuleConfigurationEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Toggle(isOn: document.ruleEnabledBinding(for: entry)) {
                    EmptyView()
                }
                .toggleStyle(.switch)
                .controlSize(.small)
                .labelsHidden()

                ScopeBadge(scope: entry.scope)

                Text(entry.name)
                    .fontWeight(.medium)

                if entry.isCorrectable {
                    Label("Auto-fix", systemImage: "wand.and.stars")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.green.opacity(0.15), in: .capsule)
                        .foregroundStyle(.green)
                }

                if entry.isOptIn {
                    Text("Opt-In")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.orange.opacity(0.15), in: .capsule)
                        .foregroundStyle(.orange)
                }

                Spacer()
            }

            Text(entry.id)
                .font(.caption.monospaced())
                .foregroundStyle(.tertiary)

            Text(entry.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)
        }
    }
}
