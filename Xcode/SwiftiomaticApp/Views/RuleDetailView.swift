import SwiftUI
import SwiftiomaticKit
import SwiftiomaticSyntax

struct RuleDetailView: View {
    @Environment(AppModel.self) private var model
    let entry: RuleConfigurationEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack(spacing: 12) {
                    Text(entry.name)
                        .font(.title)
                        .fontWeight(.bold)
                    ScopeBadge(scope: entry.scope)
                    if entry.isCorrectable {
                        Label("Correctable", systemImage: "wrench.fill")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.green.opacity(0.15), in: .capsule)
                            .foregroundStyle(.green)
                    }
                    Spacer()
                    Toggle(
                        "Enabled",
                        isOn: Binding(
                            get: { model.isRuleEnabled(entry) },
                            set: { _ in model.toggleRule(entry) }
                        )
                    )
                    .toggleStyle(.switch)
                }

                Text(entry.id)
                    .font(.subheadline.monospaced())
                    .foregroundStyle(.secondary)

                Divider()

                // Description
                Text("Description")
                    .font(.headline)
                Text(entry.summary)

                // Rationale
                if let rationale = entry.rationale {
                    Text("Rationale")
                        .font(.headline)
                    Text(rationale)
                        .foregroundStyle(.secondary)
                }

                // Metadata
                GroupBox {
                    Grid(alignment: .leading, verticalSpacing: 8) {
                        GridRow {
                            Text("Scope")
                                .gridColumnAlignment(.trailing)
                            Text(entry.scope.displayName)
                        }
                        GridRow {
                            Text("Opt-In")
                            Text(entry.isOptIn ? "Yes" : "No")
                        }
                        GridRow {
                            Text("Auto-Fix")
                            Text(entry.isCorrectable ? "Yes" : "No")
                        }
                    }
                    .padding(4)
                }
                .padding(.top, 4)
            }
            .padding()
        }
        .navigationTitle(entry.name)
    }
}

