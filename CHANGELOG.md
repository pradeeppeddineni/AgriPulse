# Changelog

All notable changes to AgriPulse are documented here.

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
