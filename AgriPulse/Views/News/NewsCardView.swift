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
    @State private var showShareOptions = false

    /// True if the snippet is just the title repeated (common with Google News RSS)
    private var isSnippetDuplicateOfTitle: Bool {
        let normalizedSnippet = item.snippet.lowercased()
            .replacingOccurrences(of: item.source.lowercased(), with: "")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedTitle = item.title.lowercased()
            .replacingOccurrences(of: " - \(item.source.lowercased())", with: "")
            .replacingOccurrences(of: " | \(item.source.lowercased())", with: "")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return normalizedSnippet == normalizedTitle
            || normalizedTitle.hasPrefix(normalizedSnippet)
            || normalizedSnippet.hasPrefix(normalizedTitle)
    }

    /// Custom encoding that also encodes *, _, ~ (WhatsApp formatting chars) and &, #, +
    private static let shareEncodingAllowed: CharacterSet = {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "*_~`&+#")
        return allowed
    }()

    private func formatShareText(url: String) -> String {
        let snippetLine = item.snippet.isEmpty || isSnippetDuplicateOfTitle ? "" : "\n\(item.snippet)\n"
        let commodityLine = commodityName.map { " · \($0)" } ?? ""
        return "*\(item.title)*\n\(snippetLine)\(item.source)\(commodityLine) · via AgriPulse\n\(url)"
    }

    private func shareArticle() {
        Task {
            let articleURL = await resolveRedirect(item.link)
            let shareText = formatShareText(url: articleURL)

            await MainActor.run {
                let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = windowScene.windows.first?.rootViewController {
                    var presenter = rootVC
                    while let presented = presenter.presentedViewController {
                        presenter = presented
                    }
                    activityVC.popoverPresentationController?.sourceView = presenter.view
                    presenter.present(activityVC, animated: true)
                }
            }
        }
    }

    private func shareToWhatsApp() {
        Task {
            let articleURL = await resolveRedirect(item.link)
            let shareText = formatShareText(url: articleURL)
            guard let encoded = shareText.addingPercentEncoding(withAllowedCharacters: Self.shareEncodingAllowed) else { return }
            // Universal link with web fallback if WhatsApp not installed
            if let url = URL(string: "https://wa.me/?text=\(encoded)") {
                await MainActor.run { UIApplication.shared.open(url) }
            }
        }
    }

    private func shareToTelegram() {
        Task {
            let articleURL = await resolveRedirect(item.link)
            let shareText = formatShareText(url: articleURL)
            guard let encodedText = shareText.addingPercentEncoding(withAllowedCharacters: Self.shareEncodingAllowed),
                  let encodedURL = articleURL.addingPercentEncoding(withAllowedCharacters: Self.shareEncodingAllowed) else { return }
            // Universal link with web fallback if Telegram not installed
            if let url = URL(string: "https://t.me/share/url?url=\(encodedURL)&text=\(encodedText)") {
                await MainActor.run { UIApplication.shared.open(url) }
            }
        }
    }

    /// Follow redirects to resolve Google News URLs to actual article URLs.
    private func resolveRedirect(_ urlString: String) async -> String {
        guard let url = URL(string: urlString),
              urlString.contains("news.google.com") else { return urlString }

        do {
            var request = URLRequest(url: url, timeoutInterval: 10)
            request.httpMethod = "GET"
            request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")

            let (data, response) = try await URLSession.shared.data(for: request)

            if let finalURL = (response as? HTTPURLResponse)?.url ?? response.url,
               !finalURL.absoluteString.contains("news.google.com") {
                return finalURL.absoluteString
            }

            if let html = String(data: data, encoding: .utf8) {
                if let range = html.range(of: #"data-n-au="([^"]+)""#, options: .regularExpression),
                   let urlRange = html.range(of: #"(?<=data-n-au=")[^"]+"#, options: .regularExpression) {
                    let _ = range
                    return String(html[urlRange])
                }
                if let urlRange = html.range(of: #"<a[^>]+href="(https?://(?!news\.google\.com)[^"]+)"#, options: .regularExpression) {
                    let match = String(html[urlRange])
                    if let hrefRange = match.range(of: #"https?://[^"]+"#, options: .regularExpression) {
                        return String(match[hrefRange])
                    }
                }
            }

            return urlString
        } catch {
            return urlString
        }
    }

    var body: some View {
        let (level, ageLabel) = AgeLevel.from(publishedAt: item.publishedAt)

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
                                .foregroundStyle(item.isSaved ? AgriPulseTheme.primary : AgriPulseTheme.mutedForeground.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                    }

                    // Title
                    Text(item.title)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(AgriPulseTheme.foreground.opacity(level.titleOpacity))
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)

                    // Snippet (hide if it's just the title repeated)
                    if !item.snippet.isEmpty && !isSnippetDuplicateOfTitle {
                        Text(item.snippet)
                            .font(.system(size: 12))
                            .foregroundStyle(AgriPulseTheme.mutedForeground.opacity(level == .old ? 0.65 : 0.9))
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
                                        .foregroundStyle(AgriPulseTheme.primary)
                                    Text("AI Summary")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(AgriPulseTheme.primary)
                                    Spacer()
                                    Image(systemName: summaryExpanded ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 9))
                                        .foregroundStyle(AgriPulseTheme.mutedForeground.opacity(0.8))
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
                                        .tint(AgriPulseTheme.primary)
                                } else {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 10))
                                }
                                Text(isSummarizing ? "Summarizing..." : "Summarize")
                                    .font(.system(size: 10.5, weight: .semibold))
                            }
                            .foregroundStyle(AgriPulseTheme.primary)
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
                            .foregroundStyle(AgriPulseTheme.mutedForeground.opacity(level == .old ? 0.6 : 0.9))
                            .textCase(.uppercase)
                            .lineLimit(1)

                        Spacer()

                        // Share button with options
                        Button {
                            showShareOptions = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 11))
                                .foregroundStyle(AgriPulseTheme.mutedForeground.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                        .confirmationDialog("Share Article", isPresented: $showShareOptions) {
                            Button {
                                shareToWhatsApp()
                            } label: {
                                Label("WhatsApp", systemImage: "message.fill")
                            }
                            Button {
                                shareToTelegram()
                            } label: {
                                Label("Telegram", systemImage: "paperplane.fill")
                            }
                            Button {
                                shareArticle()
                            } label: {
                                Label("More...", systemImage: "square.and.arrow.up")
                            }
                        }

                        Link(destination: URL(string: item.link) ?? URL(string: "https://google.com")!) {
                            HStack(spacing: 3) {
                                Text("Read")
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 9))
                            }
                            .font(.system(size: 10.5, weight: .semibold))
                            .foregroundStyle(AgriPulseTheme.primary)
                        }
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
            .onTapGesture {
                if let url = URL(string: item.link) {
                    UIApplication.shared.open(url)
                }
            }
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
