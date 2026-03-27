import SwiftUI

struct SidePanelView: View {
    @Binding var isPresented: Bool
    let viewModel: SidebarViewModel
    let onSelectTab: (ContentView.AppTab) -> Void
    let onSelectGroup: (CommoditySeeds.MarketGroup) -> Void
    let onSelectCommodity: (Commodity) -> Void
    let onShowCalendar: () -> Void
    var onSelectEquity: (() -> Void)?

    private let panelWidth: CGFloat = 280

    var body: some View {
        ZStack(alignment: .leading) {
            // Dark overlay
            Color.black.opacity(isPresented ? 0.5 : 0)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            // Panel
            HStack(spacing: 0) {
                panelContent
                    .frame(width: panelWidth)
                    .background(
                        AgriPulseTheme.card
                            .overlay(
                                LinearGradient(
                                    colors: [AgriPulseTheme.primary.opacity(0.03), Color.clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 20,
                            topTrailingRadius: 20
                        )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 5)
                    .offset(x: isPresented ? 0 : -panelWidth - 20)

                Spacer()
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isPresented)
        .ignoresSafeArea()
    }

    private func dismiss() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            isPresented = false
        }
    }

    private var panelContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Brand header
            HStack(spacing: 10) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AgriPulseTheme.primary)
                    .padding(6)
                    .background(AgriPulseTheme.primary.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 1) {
                    Text("AgriPulse")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, AgriPulseTheme.primary, .blue.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Text("MARKET INTELLIGENCE")
                        .font(.system(size: 8, weight: .semibold))
                        .tracking(2)
                        .foregroundStyle(AgriPulseTheme.mutedForeground.opacity(0.4))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 60)
            .padding(.bottom, 16)

            Divider().opacity(0.2).padding(.horizontal, 12)

            // Scrollable content
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 4) {
                    // COMMAND section
                    sectionHeader("COMMAND")

                    menuItem(icon: "globe", label: "Latest Updates", badge: viewModel.latestFreshCount) {
                        onSelectTab(.latest)
                        dismiss()
                    }
                    menuItem(icon: "bookmark.fill", label: "Saved Articles") {
                        onSelectTab(.saved)
                        dismiss()
                    }
                    menuItem(icon: "cloud.sun.fill", label: "Agri Weather", badge: viewModel.weatherFreshCount) {
                        if let commodity = viewModel.commodity(named: "Agri Weather") {
                            onSelectCommodity(commodity)
                        }
                        dismiss()
                    }
                    menuItem(icon: "calendar", label: "Commodity Calendar") {
                        onShowCalendar()
                        dismiss()
                    }
                    menuItem(icon: "chart.line.uptrend.xyaxis", label: "Equity Market", badge: viewModel.equityFreshCount) {
                        onSelectEquity?()
                        dismiss()
                    }

                    // MARKETS section
                    sectionHeader("MARKETS")

                    ForEach(CommoditySeeds.marketGroups) { group in
                        let fresh = viewModel.freshCountForGroup(group)
                        menuItem(icon: group.icon, label: group.label, badge: fresh) {
                            onSelectGroup(group)
                            dismiss()
                        }
                    }

                    // REGULATORY section
                    sectionHeader("REGULATORY")

                    let regulatoryConfig: [(icon: String, name: String)] = [
                        ("shippingbox.and.arrow.backward.fill", "Packaging"),
                        ("doc.text.fill", "PIB Updates"),
                        ("checkmark.shield.fill", "DGFT Updates"),
                        ("thermometer.medium", "IMD / Advisories"),
                    ]

                    ForEach(regulatoryConfig, id: \.name) { config in
                        let fresh = viewModel.freshCounts[config.name] ?? 0
                        menuItem(icon: config.icon, label: config.name, badge: fresh) {
                            if let commodity = viewModel.commodity(named: config.name) {
                                onSelectCommodity(commodity)
                            }
                            dismiss()
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding(.top, 8)
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 9.5, weight: .semibold))
            .tracking(1.8)
            .foregroundStyle(AgriPulseTheme.mutedForeground.opacity(0.4))
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 6)
    }

    private func menuItem(icon: String, label: String, badge: Int = 0, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(AgriPulseTheme.mutedForeground.opacity(0.6))
                    .frame(width: 18)

                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AgriPulseTheme.foreground)

                Spacer()

                if badge > 0 {
                    Text("\(badge)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(AgriPulseTheme.primary)
                        .padding(.horizontal, 6)
                        .frame(minWidth: 18, minHeight: 18)
                        .background(AgriPulseTheme.primary.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
