import SwiftUI
import SwiftData

struct SidebarView: View {
    @Bindable var viewModel: SidebarViewModel

    var body: some View {
        List {
            // COMMAND section
            Section("Command") {
                Button {
                    viewModel.selectedCommodity = nil
                } label: {
                    sidebarRow(icon: "bolt.fill", name: "Latest Updates", badge: viewModel.latestFreshCount)
                }
                .listRowBackground(viewModel.selectedCommodity == nil ? AgriPulseTheme.primary.opacity(0.15) : Color.clear)

                if let weather = viewModel.commodity(named: "Agri Weather") {
                    Button {
                        viewModel.selectedCommodity = weather
                    } label: {
                        sidebarRow(icon: "cloud.sun.fill", name: "Agri Weather", badge: viewModel.weatherFreshCount)
                    }
                    .listRowBackground(
                        viewModel.selectedCommodity?.name == "Agri Weather"
                            ? AgriPulseTheme.primary.opacity(0.15) : Color.clear
                    )
                }
            }

            // MARKETS section — grouped
            Section("Markets") {
                ForEach(CommoditySeeds.marketGroups) { group in
                    let fresh = viewModel.freshCountForGroup(group)
                    Button {
                        if let first = group.commodities.first,
                           let commodity = viewModel.commodity(named: first) {
                            viewModel.selectedCommodity = commodity
                        }
                    } label: {
                        sidebarRow(icon: group.icon, name: group.label, badge: fresh)
                    }
                }
            }

            // EQUITY section
            Section("Equity") {
                let equityNames = ["Indian Equity", "Global Equity", "Crypto", "Mutual Funds"]
                ForEach(equityNames, id: \.self) { name in
                    if let commodity = viewModel.commodity(named: name) {
                        Button {
                            viewModel.selectedCommodity = commodity
                        } label: {
                            sidebarRow(
                                icon: equityIcon(for: name),
                                name: name,
                                badge: viewModel.freshCounts[name] ?? 0
                            )
                        }
                        .listRowBackground(
                            viewModel.selectedCommodity?.name == name
                                ? AgriPulseTheme.primary.opacity(0.15) : Color.clear
                        )
                    }
                }
            }

            // REGULATORY section
            Section("Regulatory") {
                let regulatoryConfig: [(icon: String, name: String)] = [
                    ("shippingbox.and.arrow.backward.fill", "Packaging"),
                    ("doc.text.fill", "PIB Updates"),
                    ("checkmark.shield.fill", "DGFT Updates"),
                    ("thermometer.medium", "IMD / Advisories"),
                ]

                ForEach(regulatoryConfig, id: \.name) { config in
                    if let commodity = viewModel.commodity(named: config.name) {
                        Button {
                            viewModel.selectedCommodity = commodity
                        } label: {
                            sidebarRow(
                                icon: config.icon,
                                name: config.name,
                                badge: viewModel.freshCounts[config.name] ?? 0
                            )
                        }
                        .listRowBackground(
                            viewModel.selectedCommodity?.name == config.name
                                ? AgriPulseTheme.primary.opacity(0.15) : Color.clear
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

    private func sidebarRow(icon: String, name: String, badge: Int) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(AgriPulseTheme.mutedForeground.opacity(0.6))
                .frame(width: 18)

            Text(name)
                .font(.subheadline)
                .foregroundStyle(AgriPulseTheme.foreground)

            Spacer()

            if badge > 0 {
                Text("\(badge)")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AgriPulseTheme.primary.opacity(0.2))
                    .foregroundStyle(AgriPulseTheme.primary)
                    .clipShape(Capsule())
            }
        }
    }

    private func equityIcon(for name: String) -> String {
        switch name {
        case "Indian Equity": return "chart.line.uptrend.xyaxis"
        case "Global Equity": return "globe"
        case "Crypto": return "bitcoinsign.circle"
        case "Mutual Funds": return "chart.pie"
        default: return "chart.line.uptrend.xyaxis"
        }
    }
}
