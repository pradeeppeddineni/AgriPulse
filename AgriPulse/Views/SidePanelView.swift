import SwiftUI

struct SidePanelView: View {
    @Binding var isPresented: Bool
    let viewModel: SidebarViewModel
    let onSelectTab: (ContentView.AppTab) -> Void
    let onSelectGroup: (CommoditySeeds.MarketGroup) -> Void
    let onSelectCommodity: (Commodity) -> Void
    let onShowCalendar: () -> Void
    var onSelectEquity: (() -> Void)?

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private let panelWidth: CGFloat = 290

    var body: some View {
        ZStack(alignment: .leading) {
            // Dark overlay with blur
            Color.black.opacity(isPresented ? 0.55 : 0)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            // Panel
            HStack(spacing: 0) {
                panelContent
                    .frame(width: panelWidth)
                    .background {
                        ZStack {
                            if reduceTransparency {
                                // Solid fallback for accessibility
                                AgriPulseTheme.sidebar
                            } else {
                                // Base: ultra-thin material for glassmorphism
                                Rectangle()
                                    .fill(.ultraThinMaterial)
                                    .environment(\.colorScheme, .dark)

                                // Overlay: deep navy tint for brand consistency
                                AgriPulseTheme.sidebar.opacity(0.82)
                            }

                            // Gradient accent along the top
                            LinearGradient(
                                colors: [
                                    AgriPulseTheme.primary.opacity(0.12),
                                    AgriPulseTheme.primary.opacity(0.03),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .center
                            )

                            // Subtle edge highlight
                            HStack {
                                Spacer()
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [AgriPulseTheme.primary.opacity(0.15), Color.clear],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: 1)
                            }
                        }
                    }
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 24,
                            topTrailingRadius: 24
                        )
                    )
                    .shadow(color: AgriPulseTheme.primary.opacity(0.08), radius: 30, x: 8)
                    .shadow(color: .black.opacity(0.4), radius: 20, x: 5)
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
            // Brand header with glassmorphism card
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    // App icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        AgriPulseTheme.primary,
                                        AgriPulseTheme.primary.opacity(0.7)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)

                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("AgriPulse")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, AgriPulseTheme.primary.opacity(0.9)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        Text("MARKET INTELLIGENCE")
                            .font(.system(size: 8.5, weight: .bold))
                            .tracking(2.5)
                            .foregroundStyle(AgriPulseTheme.mutedForeground.opacity(0.5))
                    }
                }

                // Version pill
                HStack(spacing: 6) {
                    Circle()
                        .fill(AgriPulseTheme.freshEmerald)
                        .frame(width: 6, height: 6)
                    Text("v1.5 · Live")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(AgriPulseTheme.mutedForeground.opacity(0.6))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            .padding(.bottom, 18)

            // Divider with gradient
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [AgriPulseTheme.primary.opacity(0.3), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.horizontal, 16)

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
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 9.5, weight: .bold))
                .tracking(2)
                .foregroundStyle(AgriPulseTheme.primary.opacity(0.5))

            Rectangle()
                .fill(AgriPulseTheme.primary.opacity(0.1))
                .frame(height: 1)
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 6)
    }

    private func menuItem(icon: String, label: String, badge: Int = 0, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AgriPulseTheme.primary.opacity(0.7))
                    .frame(width: 20)

                Text(label)
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundStyle(AgriPulseTheme.foreground.opacity(0.9))

                Spacer()

                if badge > 0 {
                    Text("\(badge)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .frame(minWidth: 20, minHeight: 20)
                        .background(
                            Capsule()
                                .fill(AgriPulseTheme.primary.opacity(0.6))
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.001))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(MenuItemButtonStyle())
    }
}

// Custom button style with hover/press effect
private struct MenuItemButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(configuration.isPressed ? AgriPulseTheme.primary.opacity(0.08) : Color.clear)
                    .padding(.horizontal, 8)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
