import SwiftUI
import SwiftiomaticKit
import SwiftiomaticSyntax

struct RuleRow: View {
    @Bindable var document: SwiftiomaticDocument
    let entry: RuleConfigurationEntry

    var body: some View {
        HStack {
            Toggle(isOn: document.ruleEnabledBinding(for: entry)) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        ScopeBadge(scope: entry.scope)
                        Text(entry.name)
                            .fontWeight(.medium)
                        if entry.isCorrectable {
                            Image(systemName: "wand.and.stars")
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

