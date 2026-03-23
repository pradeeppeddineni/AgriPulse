# AgriPulse

A commodity intelligence app for Indian agricultural markets. Track news, prices, policy events, and equity data across 30+ commodities, built for farmers, traders, analysts, and agri professionals.

Available on the App Store.

---

## What It Does

**News Feed**
Aggregates news from 50+ sources for each commodity using precision search queries. Sources include Economic Times, The Hindu, Krishi Jagran, AgriWatch, iGrain, Reuters, Bloomberg, LiveMint, PIB (Press Information Bureau), and more. No algorithm, no noise — just relevant commodity news filtered to what matters.

**Equity and Markets**
Tracks Nifty, Sensex, BSE, NSE, global equity indices, crypto, and commodity-linked mutual funds. Keeps agri market movements alongside the broader financial context.

**Commodity Calendar**
130+ key dates including USDA reports, RBI policy decisions, crop sowing and harvest seasons, MSP announcements, import/export policy windows, and government procurement cycles.

**Agri Weather Intelligence**
IMD forecasts, El Nino/La Nina outlook, and monsoon updates relevant to crop planning.

**Save and Export**
Bookmark articles and export them as PDFs for offline use, reporting, or sharing.

**Commodities Covered**
Wheat, Maize, Paddy/Rice, Chana, Tur Dal, Urad Dal, Moong Dal, Masoor Dal, Soybean, Mustard/Rapeseed, Groundnut, Sunflower, Castor, Cotton, Sugarcane/Sugar, Onion, Potato, Tomato, Palm Oil, Guar, Cumin, Turmeric, Coriander, Pepper, Cardamom, and more.

---

## Design Decisions

- No account required. No login, no sign-up.
- No ads. No tracking. No analytics SDKs.
- All data stored locally on device only.
- Works on iPhone and iPad with adaptive layout (TabView on iPhone, NavigationSplitView on iPad).
- Dark theme by default.
- Background refresh for up-to-date news without opening the app.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift 5.9+ |
| UI Framework | SwiftUI |
| Persistence | SwiftData |
| Networking | URLSession + RSS parsing |
| News Sources | Google News RSS, PIB.gov.in, direct RSS feeds |
| CI/CD | Codemagic |
| Minimum iOS | iOS 17 |
| Platforms | iPhone, iPad |

---

## Project Structure

```
AgriPulse/
├── AgriPulseApp.swift          # App entry point, SwiftData container setup
├── Constants/
│   ├── CommoditySeeds.swift    # Commodity definitions and search queries
│   ├── CalendarEvents.swift    # Agricultural calendar event data
│   └── KeywordLists.swift      # Filter keywords per commodity
├── Models/
│   ├── Commodity.swift         # SwiftData commodity model
│   ├── NewsItem.swift          # SwiftData news article model
│   └── CalendarEvent.swift     # Calendar event model
├── Services/
│   ├── NewsService.swift       # Main news orchestration
│   ├── RSSFetcher.swift        # RSS feed fetching and parsing
│   ├── PIBService.swift        # Press Information Bureau integration
│   ├── NewsFilterEngine.swift  # Relevance filtering logic
│   └── BackgroundRefreshManager.swift  # Background fetch handling
├── ViewModels/
│   ├── NewsFeedViewModel.swift
│   ├── EquityViewModel.swift
│   ├── CalendarViewModel.swift
│   ├── SavedArticlesViewModel.swift
│   └── SidebarViewModel.swift
├── Views/
│   ├── ContentView.swift       # Root view, iPhone/iPad layout switching
│   ├── SidebarView.swift       # iPad sidebar commodity selector
│   ├── News/                   # News feed and article card views
│   ├── Equity/                 # Market and equity views
│   ├── Calendar/               # Commodity calendar view
│   └── Saved/                  # Bookmarks and PDF export
└── Theme/
    └── AgriPulseTheme.swift    # Colors, fonts, design tokens
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

Build and run on your target device or simulator. No additional dependencies or package manager setup required.

---

## Privacy

AgriPulse does not collect, store, or transmit any personal data. All news is fetched from publicly available RSS feeds and cached locally on your device. See [PRIVACY_POLICY.md](PRIVACY_POLICY.md) for the full policy.

---

## License

MIT License. See [LICENSE](LICENSE) for details.

---

## Contributing

Issues and pull requests are welcome. If you want to add a commodity, improve search queries for an existing one, or add a news source, the best place to start is `Constants/CommoditySeeds.swift`.

---

*Built for India's agri community. Data sourced from publicly available RSS feeds and government sources.*
