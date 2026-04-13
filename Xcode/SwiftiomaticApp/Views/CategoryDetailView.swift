import SwiftUI
import SwiftiomaticKit
import SwiftiomaticSyntax

struct CategoryDetailView: View {
    @Bindable var document: SwiftiomaticDocument
    let category: DisplayCategory
    let rules: [RuleConfigurationEntry]

    var body: some View {
        if rules.isEmpty {
            ContentUnavailableView(
                "No Rules",
                systemImage: category.symbolName,
                description: Text("No rules match the current filters.")
            )
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(rules) { entry in
                        RuleRow(document: document, entry: entry)
                            .padding(.horizontal)
                            .padding(.vertical, 10)

                        if entry.id != rules.last?.id {
                            Divider().padding(.horizontal)
                        }
                    }
                }
            }
            .navigationTitle(category.displayName)
        }
    }
}

