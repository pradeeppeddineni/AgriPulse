import SwiftUI

struct NewsCardView: View {
    let item: NewsItem
    var commodityName: String?
    var index: Int = 0
    var onToggleSave: (() -> Void)?
    var onSummarize: (() -> Void)?
    @State private var appeared = false
    @State private var isSummarizing = false
    @State private var summaryExpanded = false

    var body: some View {
        let (level, ageLabel) = AgeLevel.from(publishedAt: item.publishedAt)

        Link(destination: URL(string: item.link) ?? URL(string: "https://google.com")!) {
            VStack(alignment: .leading, spacing: 10) {
                // Accent bar for breaking/hot/fresh
                if level == .breaking || level == .hot || level == .fresh {
                    Rectangle()
                        .fill(level.accentColor.gradient)
                        .frame(height: 2.5)
                }

                VStack(alignment: .leading, spacing: 8) {
                    // Top row: badges + save button
                    HStack(alignment: .top) {
                        HStack(spacing: 6) {
                            // Age badge
                            AgeBadge(level: level, label: ageLabel)

                            // India / Global badge
                            Text(item.isGlobal ? "Global" : "India")
                                .font(.system(size: 10, weight: .semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(
                                    (item.isGlobal ? AgriPulseTheme.globalSky : AgriPulseTheme.indiaGreen)
                                        .opacity(0.12)
                                )
                                .foregroundStyle(item.isGlobal ? AgriPulseTheme.globalSky : AgriPulseTheme.indiaGreen)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(
                                            (item.isGlobal ? AgriPulseTheme.globalSky : AgriPulseTheme.indiaGreen).opacity(0.25),
                                            lineWidth: 1
                                        )
                                )

                            // Commodity pill
                            if let name = commodityName {
                                Text(name)
                                    .font(.system(size: 10, weight: .semibold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(AgriPulseTheme.primary.opacity(0.08))
                                    .foregroundStyle(AgriPulseTheme.primary.opacity(0.8))
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 5)
                                            .stroke(AgriPulseTheme.primary.opacity(0.25), lineWidth: 1)
                                    )
                            }
                        }

                        Spacer()

                        // Save button
                        Button {
                            onToggleSave?()
                        } label: {
                            Image(systemName: item.isSaved ? "bookmark.fill" : "bookmark")
                                .font(.system(size: 13))
                                .foregroundStyle(item.isSaved ? AgriPulseTheme.primary : AgriPulseTheme.mutedForeground.opacity(0.4))
                        }
                        .buttonStyle(.plain)
                    }

                    // Title
                    Text(item.title)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(AgriPulseTheme.foreground.opacity(level.titleOpacity))
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)

                    // Snippet
                    if !item.snippet.isEmpty {
                        Text(item.snippet)
                            .font(.system(size: 12))
                            .foregroundStyle(AgriPulseTheme.mutedForeground.opacity(level == .old ? 0.4 : 0.75))
                            .lineLimit(2)
                    }

                    // AI Summary
                    if let summary = item.summary {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                summaryExpanded.toggle()
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 5) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 10))
                                        .foregroundStyle(AgriPulseTheme.primary.opacity(0.7))
                                    Text("AI Summary")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(AgriPulseTheme.primary.opacity(0.7))
                                    Spacer()
                                    Image(systemName: summaryExpanded ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 9))
                                        .foregroundStyle(AgriPulseTheme.mutedForeground.opacity(0.5))
                                }
                                if summaryExpanded {
                                    Text(summary)
                                        .font(.system(size: 11.5, design: .rounded))
                                        .foregroundStyle(AgriPulseTheme.foreground.opacity(0.75))
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                } else {
                                    Text(summary)
                                        .font(.system(size: 11.5, design: .rounded))
                                        .foregroundStyle(AgriPulseTheme.foreground.opacity(0.75))
                                        .lineLimit(2)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(8)
                        .background(AgriPulseTheme.primary.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(AgriPulseTheme.primary.opacity(0.12), lineWidth: 1)
                        )
                    } else if #available(iOS 26.0, *), SummarizationService.shared.isAvailable {
                        Button {
                            isSummarizing = true
                            onSummarize?()
                        } label: {
                            HStack(spacing: 4) {
                                if isSummarizing {
                                    ProgressView()
                                        .controlSize(.mini)
                                        .tint(AgriPulseTheme.primary.opacity(0.7))
                                } else {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 10))
                                }
                                Text(isSummarizing ? "Summarizing..." : "Summarize")
                                    .font(.system(size: 10.5, weight: .semibold))
                            }
                            .foregroundStyle(AgriPulseTheme.primary.opacity(0.7))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(AgriPulseTheme.primary.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                        .disabled(isSummarizing)
                        .onChange(of: item.summary) {
                            isSummarizing = false
                        }
                    }

                    // Footer
                    Divider()
                        .overlay(Color.white.opacity(0.07))

                    HStack {
                        Text(item.source)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(AgriPulseTheme.mutedForeground.opacity(level == .old ? 0.3 : 0.55))
                            .textCase(.uppercase)
                            .lineLimit(1)

                        Spacer()

                        HStack(spacing: 3) {
                            Text("Read")
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 9))
                        }
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundStyle(AgriPulseTheme.primary.opacity(0.7))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
                .padding(.top, (level == .breaking || level == .hot || level == .fresh) ? 8 : 14)
            }
            .background(level.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(level.accentColor.opacity(level == .normal || level == .old ? 0.12 : 0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3).delay(Double(min(index, 10)) * 0.04)) {
                appeared = true
            }
        }
    }
}

struct AgeBadge: View {
    let level: AgeLevel
    let label: String

    var body: some View {
        Text("\(level.prefix)\(label)")
            .font(.system(size: 10, weight: level == .breaking || level == .hot ? .bold : .semibold))
            .textCase(.uppercase)
            .tracking(0.5)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(level.accentColor.opacity(0.12))
            .foregroundStyle(level.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(level.accentColor.opacity(0.3), lineWidth: 1)
            )
    }
}
