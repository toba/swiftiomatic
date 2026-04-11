import SwiftUI
import SwiftiomaticKit

struct RulesTab: View {
  @Environment(AppModel.self) private var model
  @State private var searchText = ""
  @State private var scopeFilter: ScopeFilter = .all
  @State private var selectedRule: RuleConfigurationEntry?

  enum ScopeFilter: String, CaseIterable {
    case all = "All"
    case lint = "Lint"
    case format = "Format"
    case suggest = "Suggest"
  }

  private var filteredRules: [RuleConfigurationEntry] {
    model.rules.filter { entry in
      switch scopeFilter {
      case .all: true
      case .lint: entry.scope == .lint
      case .format: entry.scope == .format
      case .suggest: entry.scope == .suggest
      }
    }.filter {
      searchText.isEmpty
        || $0.name.localizedCaseInsensitiveContains(searchText)
        || $0.id.localizedCaseInsensitiveContains(searchText)
        || $0.summary.localizedCaseInsensitiveContains(searchText)
    }
  }

  var body: some View {
    NavigationSplitView {
      List(filteredRules, selection: $selectedRule) { entry in
        RuleRow(entry: entry)
          .tag(entry)
      }
      .searchable(text: $searchText, placement: .sidebar, prompt: "Filter rules")
      .toolbar {
        ToolbarItem {
          Picker("Scope", selection: $scopeFilter) {
            ForEach(ScopeFilter.allCases, id: \.self) { filter in
              Text(filter.rawValue).tag(filter)
            }
          }
          .pickerStyle(.segmented)
        }
      }
      .navigationTitle("Rules")
      .navigationSplitViewColumnWidth(min: 280, ideal: 340, max: 500)
    } detail: {
      if let rule = selectedRule {
        RuleDetailView(entry: rule)
      } else {
        ContentUnavailableView(
          "Select a Rule",
          systemImage: "doc.text.magnifyingglass",
          description: Text("Choose a rule from the sidebar to view its details.")
        )
      }
    }
  }
}
