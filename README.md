# AgriPulse

A commodity intelligence app for Indian agricultural markets. Track news, prices, policy events, and equity data across 40+ commodities, built for farmers, traders, analysts, and agri professionals.

[![App Store](https://img.shields.io/badge/App_Store-Available-blue?logo=apple)](https://apps.apple.com/app/agripulse/id6760972266)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![CI/CD](https://img.shields.io/badge/CI%2FCD-Codemagic-orange?logo=codemagic)](https://codemagic.io)

---

## What It Does

**News Feed**
Aggregates news from 50+ sources for each commodity using precision search queries. Sources include Economic Times, The Hindu, Krishi Jagran, AgriWatch, iGrain, Reuters, Bloomberg, LiveMint, PIB (Press Information Bureau), and more. Multi-layer relevance filtering removes noise — no recipes, no horoscopes, no irrelevant results.

**WhatsApp & Telegram Sharing**
One-tap sharing to WhatsApp and Telegram with formatted text (bold titles, source attribution). Uses universal links with built-in web fallback. Also supports native iOS share sheet for any other app.

**Push Notifications**
Breaking news alerts for articles less than 30 minutes old. Starts with provisional (quiet) notifications — no prompt shown. Upgrades to full notifications after user engagement. Notification actions: "Read Article" opens the link, "Save for Later" bookmarks it.

**Home Screen Widget**
WidgetKit-powered breaking news widget in three sizes — small (single headline), medium (3 headlines), and lock screen (rectangular). Deep links to articles on tap. Refreshes every 15 minutes.

**Commodity Groups**
Commodities organized into 7 market groups — Grains, Edible Oils, Others, Fresh Produce, Dry Fruits, Spices, and Others-1 — each with horizontal sub-tab navigation. Last selected sub-tab is remembered per group.

**Equity and Markets**
Tracks Indian equity (Nifty, Sensex), global indices, crypto, and commodity-linked mutual funds with dedicated sub-tabs per category.

**Commodity Calendar**
130+ key dates including USDA reports, RBI policy decisions, crop sowing and harvest seasons, MSP announcements, import/export policy windows, and government procurement cycles.

**Agri Weather Intelligence**
IMD forecasts, El Nino/La Nina outlook, and monsoon updates relevant to crop planning.

**Save and Export**
Bookmark articles and export them as PDFs for offline use, reporting, or sharing.

**AI Summaries**
Apple Intelligence-powered article summaries with expand/collapse toggle.

**Commodities Covered (40+)**

| Group | Commodities |
|-------|-------------|
| Grains | Wheat, Maize, Paddy/Rice, Chana, Ethanol/DDGS |
| Edible Oils | Palm Oil, Rice Bran Oil, Soyabean, Sunflower, Cotton Seed Oil |
| Others | Crude, Precious Metals, Currency |
| Fresh | Potato, Cabbage/Carrot, Ring Beans, Onion |
| Dry Fruits | Cashew, Almond, Raisins, Groundnut, Oats, Psyllium |
| Spices | Chilli, Turmeric, Black Pepper, Cardamom |
| Others-1 | Sugar, Milk/Dairy, Cocoa |
| Equity | Indian Equity, Global Equity, Crypto, Mutual Funds |
| Regulatory | Packaging, PIB Updates, DGFT Updates, IMD Advisories |

---

## Design Decisions

- No account required. No login, no sign-up.
- No ads. No tracking. No analytics SDKs.
- All data stored locally on device only.
- Works on iPhone and iPad with adaptive layout (TabView on iPhone, NavigationSplitView on iPad).
- Dark theme by default with glassmorphism side panel (blur material + navy tint).
- Accessibility: solid fallback when Reduce Transparency is enabled.
- Background refresh for up-to-date news without opening the app.
- 5-tab navigation: Latest, Saved, Equity, Grains, More.
- Side panel (More tab) for full commodity access with Command/Markets/Regulatory sections.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift 5.9+ |
| UI Framework | SwiftUI |
| Persistence | SwiftData |
| Networking | URLSession + FeedKit (RSS parsing) |
| HTML Parsing | SwiftSoup (PIB scraping) |
| AI | Apple FoundationModels (on-device summarization) |
| Notifications | UNUserNotificationCenter (local, provisional + full) |
| Widgets | WidgetKit (small, medium, lock screen) |
| News Sources | Google News RSS, PIB.gov.in |
| CI/CD | Codemagic (Mac Mini M2, auto TestFlight) |
| Minimum iOS | iOS 17 |
| Platforms | iPhone, iPad |

---

## Project Structure

```
AgriPulse/
├── AgriPulseApp.swift              # App entry point, SwiftData setup, migrations
├── Constants/
│   ├── CommoditySeeds.swift        # 40+ commodity definitions, search queries, MarketGroup
│   ├── CalendarEvents.swift        # 130+ agricultural calendar events
│   └── KeywordLists.swift          # Per-commodity keywords, noise filters
├── Models/
│   ├── Commodity.swift             # SwiftData commodity model
│   ├── NewsItem.swift              # SwiftData news article model
│   └── CalendarEvent.swift         # Calendar event model
├── Services/
│   ├── NewsService.swift           # News orchestration + refresh + widget data
│   ├── RSSFetcher.swift            # RSS fetching, HTML stripping, dedup
│   ├── PIBService.swift            # Press Information Bureau scraping
│   ├── NewsFilterEngine.swift      # Relevance + noise filtering
│   ├── NotificationService.swift   # Push notifications, categories, actions
│   ├── SummarizationService.swift  # Apple Intelligence article summaries
│   └── BackgroundRefreshManager.swift
├── ViewModels/
│   ├── NewsFeedViewModel.swift     # News feed + pagination logic
│   ├── EquityViewModel.swift       # Equity market data
│   ├── CalendarViewModel.swift     # Calendar event filtering
│   ├── SavedArticlesViewModel.swift
│   └── SidebarViewModel.swift      # Group-level fresh counts
├── Views/
│   ├── ContentView.swift           # 5-tab layout, side panel integration
│   ├── SidebarView.swift           # iPad sidebar (Command/Markets/Regulatory)
│   ├── SidePanelView.swift         # iPhone glassmorphism side panel
│   ├── Groups/
│   │   └── CommodityGroupView.swift  # Generic group view with remembered sub-tabs
│   ├── News/
│   │   ├── NewsFeedView.swift      # News list + pagination controls
│   │   └── NewsCardView.swift      # Article card (age badges, share, WA/TG)
│   ├── Equity/
│   │   └── EquityMarketView.swift  # Equity sub-tabs (Indian/Global/Crypto/MF)
│   ├── Calendar/
│   │   └── CommodityCalendarView.swift
│   ├── Saved/
│   │   ├── SavedArticlesView.swift
│   │   └── PDFExportView.swift
│   └── Common/
│       ├── BadgeViews.swift
│       └── RefreshButton.swift
├── Theme/
│   └── AgriPulseTheme.swift        # Colors, fonts, age-level styling
└── AgriPulseWidget/                # WidgetKit extension (needs Xcode target setup)
    ├── AgriPulseWidgetBundle.swift
    └── BreakingNewsWidget.swift    # Small, medium, lock screen widgets
```

---

## Building Locally

Requirements:
- Xcode 15 or later
- iOS 17 SDK
- A device or simulator running iOS 17+

```bash
git clone https://github.com/pradeeppeddineni/AgriPulse.git
cd AgriPulse
open AgriPulse.xcodeproj
```

Build and run on your target device or simulator. Swift Package Manager resolves FeedKit and SwiftSoup automatically.

### Adding the Widget Extension
1. In Xcode: File > New > Target > Widget Extension
2. Name it `AgriPulseWidget`, uncheck "Include Configuration App Intent"
3. Delete auto-generated files, use existing files in `AgriPulseWidget/`
4. Add App Groups capability to both targets: `group.com.agripulse.app`

---

## CI/CD

Builds are handled by [Codemagic](https://codemagic.io) on Mac Mini M2 cloud machines:

```
git push → Codemagic triggers → Resolve packages → Lint → Security scan → Tests → Build → TestFlight
```

Pipeline includes: Swift lint, SAST security scan, pen test audit, dependency vulnerability check, unit tests, performance audit. Build numbers auto-increment from the latest TestFlight build. See `codemagic.yaml` for the full pipeline.

Deploy commands via `appstore_connect.py`:
```bash
python3 appstore_connect.py build --wait          # Trigger build
python3 appstore_connect.py testflight --whats-new "..."  # Send to TestFlight
python3 appstore_connect.py full --version 1.5 --whats-new "..."  # Full pipeline
```

---

## Privacy

AgriPulse does not collect, store, or transmit any personal data. All news is fetched from publicly available RSS feeds and cached locally on your device. See [PRIVACY_POLICY.md](PRIVACY_POLICY.md) for the full policy.

---

## License

MIT License. See [LICENSE](LICENSE) for details.

---

## Contributing

Issues and pull requests are welcome. To add a commodity or improve search queries, start with `Constants/CommoditySeeds.swift`. To add a news source or adjust filtering, see `Services/RSSFetcher.swift` and `Constants/KeywordLists.swift`.

---

*Built for India's agri community. Data sourced from publicly available RSS feeds and government sources.*
