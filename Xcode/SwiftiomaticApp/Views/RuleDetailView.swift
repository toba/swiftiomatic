import SwiftUI
import Swiftiomatic

struct RuleDetailView: View {
    @Environment(AppModel.self) private var model
    let entry: RuleCatalogEntry

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

                Text(entry.identifier)
                    .font(.subheadline.monospaced())
                    .foregroundStyle(.secondary)

                Divider()

                // Description
                Text("Description")
                    .font(.headline)
                Text(entry.description)

                // Rationale
                if let rationale = entry.rationale {
                    Text("Rationale")
                        .font(.headline)
                    Text(rationale)
                        .foregroundStyle(.secondary)
                }

                // Metadata
                GroupBox("Details") {
                    LabeledContent("Scope", value: entry.scope.displayName)
                    LabeledContent("Opt-In", value: entry.isOptIn ? "Yes" : "No")
                    LabeledContent("Auto-Fix", value: entry.isCorrectable ? "Yes" : "No")
                }
            }
            .padding()
        }
        .navigationTitle(entry.name)
    }
}
