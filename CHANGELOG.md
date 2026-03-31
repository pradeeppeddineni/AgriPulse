# Changelog

All notable changes to AgriPulse are documented here.

## [1.5] - 2026-03-30 (Build 41)

### Added
- **Light mode** — full adaptive color system using UIColor dynamic providers; #F2F2F7 light background, white cards with soft shadows, deeper badge colors
- **Sun/moon theme toggle** — animated icon next to search bar with gradient colors, spring animation, haptic feedback, persists via @AppStorage
- **Favicon caching** — in-memory cache for source favicons, prevents repeated network requests during scroll
- **Background refresh** — BGAppRefreshTask registered and scheduled on launch + background entry; enables notifications when app is closed

### Changed
- Card layout reverted to compact style: uniform 14pt title font, top accent bar, tighter 12px spacing between cards, no hero card
- Pagination now scrolls to top when changing pages (NewsFeedView, CommodityGroupView, EquityMarketView)
- PIB keyword filtering tightened: removed broad words (food, seed, soil, cooperative), added noise patterns for non-agri government releases
- Source names preserve original casing (NDTV stays NDTV)
- Card tint halved for breaking/hot/fresh badges
- Side panel stays dark in both light and dark modes (intentional design choice)
- All hardcoded .dark references fixed for adaptive theme across every page

---

## [1.5] - 2026-03-28

### Added
- **Glassmorphism side panel** — ultra-thin material blur, gradient accent, branded header with app icon, press animation on menu items
- **Accessibility fallback** — solid background when Reduce Transparency is enabled
- **WhatsApp sharing** — one-tap share via `wa.me` universal link with bold formatting
- **Telegram sharing** — one-tap share via `t.me/share/url` universal link
- **Share confirmation dialog** — choose WhatsApp, Telegram, or More (iOS share sheet)
- **Push notifications** — local notifications for breaking news (articles < 30 min old)
- **Provisional authorization** — quiet notifications on first launch, no prompt shown
- **Notification upgrade** — auto-upgrades to full notifications after 3+ sessions
- **Notification categories** — "Read Article" and "Save for Later" action buttons
- **Notification deep linking** — tap notification to open the article
- **Foreground notifications** — breaking alerts shown even when app is open
- **Home screen widget** (source files) — small, medium, and lock screen sizes
- **Widget deep linking** — tap widget article to open it
- **Widget data pipeline** — latest articles pushed to shared UserDefaults for widget
- **App Store metadata** — optimized English + Hindi localization, keyword strategy

### Changed
- Share encoding now uses custom CharacterSet that properly encodes `*`, `_`, `~`, `&`, `+`, `#` for WhatsApp bold formatting
- Widget refresh interval reduced from 30 to 15 minutes
- Side panel width increased from 280 to 290, corner radius increased to 24

### Fixed
- WhatsApp bold text (`*title*`) not rendering due to `*` not being percent-encoded
- Telegram share falling back incorrectly — now uses universal links with web fallback

## [1.4] - 2026-03-28

### Added
- New app icon — wheat heartbeat logo with green background, edge-to-edge fill

### Fixed
- App icon black border — removed alpha channel, filled full area
- Text contrast improved across all views for better readability

## [1.3] - 2026-03-27

### Added
- **Pagination** across all commodity tabs (50 articles per page)
- **Native share sheet** (UIActivityViewController) on every news card
- **Swipe gesture** — swipe right from left edge to open side panel
- **Pull-to-refresh** on all news lists, group views, and equity view
- **Search bar** on news feed and saved articles
- **Rate/review prompt** after 5th session (max once per 90 days)
- **AI article summaries** using Apple FoundationModels (on-device)
- **Commodity Calendar** — full calendar view with 130+ agricultural events
- **Google News URL resolution** — resolves redirect URLs before sharing

### Fixed
- All 12 v1.2 bugs:
  - Raw HTML/URLs in news snippets
  - AI Summary displaying raw Response object
  - News retention too short (now 30 days default, 365 for Wheat)
  - Missing queries/sources vs Replit web app (added 30+ queries, 20+ sources)
  - Empty commodity tabs (Cotton Seed Oil, Psyllium)
  - IMD/Advisories missing ICAR articles
  - Maize not appearing in Latest tab
  - India/Global misclassification
  - Currency tab missing articles
  - Poor font contrast on older cards
  - Equity Market access buried in side panel
  - Duplicate articles with different Google News URLs

## [1.2] - 2026-03-26

### Added
- **6-tab navigation**: Latest, Saved, Weather, Grains, Equity, More
- **Grains tab** with horizontal sub-tabs (Wheat, Maize, Paddy, Chana, Ethanol)
- **Side panel** (More tab) slides from left with Command/Markets/Regulatory sections
- **CommodityGroupView** — generic group view with sub-tabs, reusable for all 7 market groups
- **Currency commodity** under Others group (INR/USD, forex, RBI)
- **7 market groups**: Grains, Edible Oils, Others, Fresh, Dry Fruits, Spices, Others-1
- **Pagination** for Wheat (50/page, 365-day window) and PIB Updates (25/page)
- **Fetching indicator** — animated pulsing dot (amber when syncing, green when idle)
- **Article count status bar** — "X of Y updates · page Z of N"
- **Commodity-specific noise filters** (Maize: cornrow/cornea, Wheat: grain of salt, etc.)
- **HTML stripping** in RSS snippets — no more raw `<a href>` tags showing

### Changed
- Bottom tab "Wheat" replaced with "Grains" (group of 5 commodities)
- Hamburger menu removed, replaced by More tab with full side panel
- iPad sidebar reorganized into Command/Markets/Equity/Regulatory sections
- Latest tab excludes Grains group commodities (they have their own tab)
- SidebarViewModel now tracks group-level fresh counts

### Fixed
- Raw HTML/URLs appearing in news snippets instead of clean text
- Snippet display showing `<a href="https://news.google.com/rss/...` markup

## [1.1] - 2026-03-25

### Added
- Tab layout sync between iPhone and iPad
- Equity market sub-tabs (Indian, Global, Crypto, Mutual Funds)
- Sync timestamp display
- Fresh count badges on tabs
- Equity filter improvements

### Changed
- Updated app icon
- Build number auto-increment from TestFlight

## [1.0] - 2026-03-22

### Added
- Initial App Store release
- News feed for 30+ agricultural commodities
- Google News RSS aggregation with multi-query search
- PIB (Press Information Bureau) integration
- Commodity Calendar with 130+ events
- Agri Weather intelligence
- Equity market tracking
- Saved articles with PDF export
- Background refresh (2-hour intervals)
- Dark theme with glassmorphism design
- iPhone and iPad adaptive layout
