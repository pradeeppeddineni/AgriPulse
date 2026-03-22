import SwiftUI
import SwiftData

struct SidebarView: View {
    @Bindable var viewModel: SidebarViewModel

    var body: some View {
        List(selection: Binding(
            get: { viewModel.selectedCommodity },
            set: { viewModel.selectedCommodity = $0 }
        )) {
            Section {
                Button {
                    viewModel.selectedCommodity = nil
                } label: {
                    Label("Latest Updates", systemImage: "bolt.fill")
                }
                .listRowBackground(viewModel.selectedCommodity == nil ? AgriPulseTheme.primary.opacity(0.15) : Color.clear)
            }

            ForEach(viewModel.grouped, id: \.group) { section in
                Section(section.group.rawValue) {
                    ForEach(section.items, id: \.name) { commodity in
                        Button {
                            viewModel.selectedCommodity = commodity
                        } label: {
                            HStack {
                                Text(commodity.name)
                                    .font(.subheadline)
                                    .foregroundStyle(AgriPulseTheme.foreground)

                                Spacer()

                                if let count = viewModel.freshCounts[commodity.name], count > 0 {
                                    Text("\(count)")
                                        .font(.caption2.weight(.bold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(AgriPulseTheme.primary.opacity(0.2))
                                        .foregroundStyle(AgriPulseTheme.primary)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .listRowBackground(
                            viewModel.selectedCommodity?.name == commodity.name
                                ? AgriPulseTheme.primary.opacity(0.15)
                                : Color.clear
                        )
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("AgriPulse")
        .scrollContentBackground(.hidden)
        .background(AgriPulseTheme.sidebar)
    }
}
