# AgriPulse — Complete Backlog (Bugs + Enhancements)

> Generated: 2026-03-27 | Current Version: v1.2 | App Store ID: 6760972266

---

## PART 1: BUGS (v1.2)

---

### BUG-01: Raw HTML/URLs showing in news card snippets
**Priority:** High
**Affected areas:** Wheat, Paddy, Chana, Mutual Funds, Saved Articles

**Problem:**
Some news cards display raw HTML like `<a href="https://news.google.com/rss/articles/CBMizgFBVV95cUx...` instead of clean snippet text. The `stripHTML()` function in `RSSFetcher.swift` is not catching all HTML patterns from Google News RSS feeds. Some articles come with `<a>` tags wrapping the entire snippet, and the current regex/stripping logic fails to clean them.

**Root cause:**
Google News RSS returns two formats for `<description>`:
1. Plain text with HTML entities (handled correctly)
2. Full `<a href="...">text</a>` wrapped content (NOT handled — the anchor tag with long Google News redirect URLs passes through)

**Suggested fix:**
- In `RSSFetcher.swift` → `stripHTML()`: Add a more aggressive HTML tag removal regex that handles `<a href="...">` tags specifically, including multi-line/long URLs
- Also run `stripHTML()` on existing stored articles via a one-time migration in `AgriPulseApp.swift` to clean up already-fetched articles
- Test against these specific patterns: `<a href="https://news.google.com/rss/articles/...">text</a>` and bare `https://news.google.com/rss/articles/...` URLs

**Files to modify:**
- `AgriPulse/Services/RSSFetcher.swift` — fix `stripHTML()`
- `AgriPulse/AgriPulseApp.swift` — add migration to clean existing articles

---

### BUG-02: AI Summary displaying raw Response object
**Priority:** High
**Affected areas:** Sugar/ChiniMandi articles, possibly others

**Problem:**
AI Summary shows `Response<String>(userPrompt: "Daily Sugar Market Update By Vizzie – 27/03/2026 - ChiniMandi. Daily Sugar..."` instead of the actual summary. The FoundationModels `Response<String>` object is being stored/displayed as its `.description` string representation rather than extracting the `.output` or actual response text.

**Works correctly for:** Precious Metals (Silver/Economic Times) — so the summarization pipeline works, but the response extraction is inconsistent.

**Also broken for Chana:** AI Summarize outputs "this is an AgriWatch article" — the summarization service is likely failing to extract the article body from AgriWatch's HTML structure, so it falls back to summarizing the page metadata/boilerplate instead of the actual content.

**Root cause (two issues):**
1. `SummarizationService.swift` — the `Response<String>` return value is being converted to string via `.description` instead of accessing the actual output property (e.g., `.output` or similar)
2. Article body extraction fails for some sources (AgriWatch, ChiniMandi) — the HTML parsing doesn't find `<article>` or content divs, so it passes boilerplate/nav text to the model

**Suggested fix:**
- In `SummarizationService.swift`: Change how the FoundationModels response is extracted — use the correct property to get the generated text (likely `.output` or the string value, not `.description`)
- Improve HTML content extraction: Add fallback selectors for common article body patterns (`<div class="entry-content">`, `<div class="article-body">`, `<main>`, etc.)
- Add a minimum content length check — if extracted body is < 100 chars, skip summarization rather than summarizing garbage

**Files to modify:**
- `AgriPulse/Services/SummarizationService.swift`

---

### BUG-03: News retention too short (7-8 days instead of 30)
**Priority:** High
**Affected areas:** All commodity tabs

**Problem:**
Users can only see ~7-8 days of news in commodity tabs. The target retention is:
- **General commodities:** 30 days
- **Wheat:** 365 days (currently showing only ~32 days, should be more)
- **Latest tab:** 48 hours only (articles older than 48hrs should disappear from Latest but remain in their commodity tab for 30 days)

**Root cause:**
The RSS fetch uses `tbs=qdr:h24` (last 24 hours only) in Google News queries. Over time, if the app isn't refreshed frequently enough, articles from days when no refresh happened are simply never fetched. Combined with the 2-hour background refresh (which iOS may throttle), the effective coverage is much less than 30 days.

**Suggested fix:**
- Change the Google News time parameter from `tbs=qdr:h24` to `tbs=qdr:d7` (last 7 days) for regular fetches — this ensures overlapping coverage even with infrequent refreshes
- For Wheat specifically, consider using `tbs=qdr:m1` (last month) or removing the time filter entirely and relying on the 365-day age cutoff in code
- In `NewsFeedViewModel.swift`: Filter the Latest tab query to only show articles with `publishedAt` within the last 48 hours
- Ensure `NewsService.swift` cleanup routine uses the correct age cutoffs: 30 days for general, 365 for Wheat
- Consider adding a "deep refresh" that runs less frequently (e.g., once daily) with a wider time window

**Files to modify:**
- `AgriPulse/Services/RSSFetcher.swift` — change `tbs` parameter
- `AgriPulse/Services/NewsService.swift` — verify cleanup cutoffs
- `AgriPulse/ViewModels/NewsFeedViewModel.swift` — 48hr filter for Latest

---

### BUG-04: iOS app missing ~30-50% articles vs Replit web app
**Priority:** High
**Affected areas:** All commodities, especially Sugar, Ethanol, Chana, Wheat, Currency

**Problem:**
Deep comparison between Replit Commodity-Watcher-3 and AgriPulse iOS reveals significant content gaps:

| Commodity | Replit Queries | iOS Queries | Gap |
|-----------|---------------|-------------|-----|
| Sugar | 8 | 4 | -50% |
| Ethanol/DDGS | 9 | 4 | -55% |
| Chana | 8 | 5 | -37% |
| Wheat | 9 | 6 | -33% |
| Currency | 6 | 4 | -33% |
| Chilli | 6 | 4 | -33% |

Additionally, 20+ news source domains in Replit's site-specific queries are absent from iOS:
- hindustantimes.com, indianexpress.com, ndtv.com, livemint.com
- businessline.com, financialexpress.com, moneycontrol.com
- thehansindia.com, telegraphindia.com, deccanherald.com, lokmattimes.com
- reuters.com, bloomberg.com, cnbc.com, wsj.com
- coindesk.com, cointelegraph.com, upstox.com
- freshplaza.com, freshfruitportal.com

Also missing: 4 specialized fetchers (PIB direct scrape, DGFT, IMD, Packaging) and 7 noise filter patterns.

**Suggested fix:**
- Port ALL missing search queries from `Commodity-Watcher-3/server/routes.ts` commodity definitions into `CommoditySeeds.swift`
- Add the missing 20+ news source domains to the relevant site-specific queries
- Add the 7 missing noise patterns to `KeywordLists.swift` ("gram panchayat", "gram sabha", sports-specific patterns, crime/legal patterns)
- Consider implementing specialized fetchers for PIB, DGFT, IMD, Packaging (see ENH-07)

**Files to modify:**
- `AgriPulse/Constants/CommoditySeeds.swift` — add missing queries and sources
- `AgriPulse/Constants/KeywordLists.swift` — add missing noise patterns

---

### BUG-05: Empty commodity tabs (Cotton Seed Oil, Psyllium)
**Priority:** High
**Affected areas:** Cotton Seed Oil, Psyllium/Isabgol tabs

**Problem:**
These commodity tabs show zero articles despite having search queries defined.

**Root cause (likely):**
- Search queries may be too specific or niche for Google News to return results
- Keyword title filters may be rejecting all results (the title must contain commodity-specific keywords)
- These are low-volume commodities — 24-hour RSS window (`tbs=qdr:h24`) may frequently return zero results, and without accumulation over time, the tabs stay empty

**Suggested fix:**
- Widen the time window for these low-volume commodities (use `tbs=qdr:d7` or `tbs=qdr:d30`)
- Review and broaden search queries — compare with Replit versions
- Loosen title keyword requirements for low-volume commodities (perhaps accept if ANY word from the commodity name appears, not requiring specific keyword matches)
- Add more synonym/alternative terms (e.g., Psyllium: "isabgol", "husk", "psyllium husk export India")

**Files to modify:**
- `AgriPulse/Constants/CommoditySeeds.swift` — broaden queries
- `AgriPulse/Services/RSSFetcher.swift` — wider time window for low-volume commodities
- `AgriPulse/Services/NewsFilterEngine.swift` — loosen filters for specific commodities

---

### BUG-06: IMD/Advisories missing ICAR and agricultural institute news
**Priority:** High
**Affected areas:** IMD/ICAR Advisories special commodity

**Problem:**
Replit Commodity-Watcher-3 (`/commodity/186`) shows 100 IMD/Advisories updates including ICAR articles (Oilseed Kisan Mela, ICAR-CRIDA climate resilience, ICAR-CIPHET, Indian Council of Agricultural Research highlights). The iOS app shows almost none of these.

**Root cause:**
Replit has a dedicated `server/imd.ts` fetcher with 12 specialized search terms (IMD, ICAR, agromet, KVK advisories) and a 60-day age cutoff. AgriPulse uses only 2 standard Google News queries for IMD/Advisories with a 24-hour window.

**Suggested fix:**
- Port all 12 search queries from Replit's `server/imd.ts` into the IMD/Advisories commodity in `CommoditySeeds.swift`
- Key queries to add: `"ICAR" India agriculture advisory`, `"agromet advisory" India forecast`, `"KVK" Krishi Vigyan Kendra advisory`, `"Indian Council of Agricultural Research"`, `ICAR-CRIDA OR ICAR-CIPHET OR ICAR-IARI`
- Increase age cutoff for IMD/Advisories to 60 days (matching Replit)
- Consider adding direct scraping of ICAR website as a future enhancement

**Files to modify:**
- `AgriPulse/Constants/CommoditySeeds.swift` — add ICAR/IMD queries
- `AgriPulse/Services/NewsService.swift` — set 60-day cutoff for IMD/Advisories

---

### BUG-07: Maize news not appearing in Latest tab
**Priority:** Medium
**Affected areas:** Latest Updates tab

**Problem:**
A BREAKING Maize article ("CM Chandrababu Naidu urges Centre to fully support maize farmers", 40M ago) appears in Grains > Maize but doesn't show in Latest Updates (synced at the same time, 08:55 PM). Latest tab shows Precious Metals, Currency, Cocoa but no Maize articles.

**Root cause (likely):**
The Latest tab aggregates articles using a query that may filter by `isGlobal` or specific commodity types. It might only pull from "market" commodities (Crude, Precious Metals, Currency) and "special" commodities, excluding regular commodities like Maize from the Grains group.

**Suggested fix:**
- In `NewsFeedViewModel.swift`: Ensure the Latest tab query fetches ALL recent articles across ALL commodities (regular + special + market + equity), sorted by `publishedAt` descending
- Apply the 48-hour cutoff for Latest (see BUG-03)
- Verify the SwiftData predicate for the Latest feed includes all commodity types

**Files to modify:**
- `AgriPulse/ViewModels/NewsFeedViewModel.swift` — fix Latest query to include all commodities

---

### BUG-08: India/Global misclassification
**Priority:** Medium
**Affected areas:** Wheat, Currency, and likely others

**Problem:**
- MillenniumPost article about CM Yogi and UP wheat procurement is tagged "Global" — clearly India news
- "Forex reserves fall for third week" (Business Standard) tagged "Global" in app but "India" in Replit
- dailynews.lk (Sri Lanka) articles leaking into India wheat results

**Root cause:**
The `isGlobalQuery()` function in `RSSFetcher.swift` determines India/Global based on the QUERY string, not the article content. If the query doesn't contain India-specific terms, the article defaults to Global. The India keyword check in `NewsFilterEngine.swift` scans article title/snippet for India mentions, but this result may not override the query-level classification.

**Suggested fix:**
- Add more India detection keywords to `KeywordLists.swift`: CM (Chief Minister), state abbreviations (UP, MP, AP, TN), government body names (NAFED, FCI, APMC), "procurement", "mandi", "MSP", "quintal"
- Make article-level India detection OVERRIDE query-level Global flag — if the article title/snippet contains India keywords, mark it as India regardless of query classification
- Add Sri Lanka / foreign country exclusion for India-only commodities (filter out .lk, .pk, .bd domains for domestic commodities)

**Files to modify:**
- `AgriPulse/Constants/KeywordLists.swift` — add India keywords
- `AgriPulse/Services/NewsFilterEngine.swift` — article-level India override logic
- `AgriPulse/Services/RSSFetcher.swift` — potentially adjust `isGlobalQuery()`

---

### BUG-09: Currency tab missing many articles vs Replit
**Priority:** Medium
**Affected areas:** Currency commodity (Others group)

**Problem:**
Replit has 32 Currency articles (Rupee all-time low, NDTV Profit, Scroll.in, The Hindu, indtoday). iOS app has only ~3-4 articles.

**Root cause:**
iOS has 4 Currency search queries vs Replit's 6. Missing queries:
- Rupee falls/slides/drops/record low specific query
- RBI intervention forex market query
- Macro impact query (imported inflation, remittance, oil import)

Also missing source domains: ndtv.com, moneycontrol.com, financialexpress.com, reuters.com, upstox.com

**Suggested fix:**
- Port all 6 Currency queries from Replit's commodity definitions into `CommoditySeeds.swift`
- Add missing site domains to the Currency queries
- This is a subset of BUG-04 but called out specifically due to the severity (32 vs 3 articles)

**Files to modify:**
- `AgriPulse/Constants/CommoditySeeds.swift` — update Currency queries

---

### BUG-10: Poor font contrast on older news cards
**Priority:** Medium
**Affected areas:** All "normal" age-level cards (articles older than 24 hours)

**Problem:**
BREAKING (red, < 1hr) and HOT (green, 1-8hr) cards have good text contrast. But "FRESH" (8-24hr) and "NORMAL" (> 24hr) cards have very dim text that's hard to read against the dark background. Most visible in Grains > Wheat (2D AGO cards).

**Root cause:**
`AgriPulseTheme.swift` likely defines age-level colors with reduced opacity or dim text colors for older articles. The "normal" level was probably designed to visually de-emphasize older news, but went too far.

**Suggested fix:**
- In `AgriPulseTheme.swift`: Increase the text color brightness/opacity for FRESH and NORMAL age levels
- Ensure minimum contrast ratio of 4.5:1 for body text against the card background (WCAG AA compliance)
- Keep the visual hierarchy (BREAKING > HOT > FRESH > NORMAL) but make NORMAL still clearly readable
- Consider brightening the card border/glow for NORMAL cards as well

**Files to modify:**
- `AgriPulse/Theme/AgriPulseTheme.swift` — adjust age-level colors
- `AgriPulse/Views/News/NewsCardView.swift` — if card-level styling overrides theme

---

### BUG-11: Equity Market access buried in side panel
**Priority:** Medium
**Affected areas:** Navigation / tab bar

**Problem:**
Equity Market (Indian Equity, Global Equity, Crypto, Mutual Funds) is only accessible via More > side panel. Users want quicker access. However, iOS limits the tab bar to 5 icons and all 5 are currently used (Latest, Saved, Weather, Grains, More).

**Options (pick one):**
1. **Configurable 4th tab** — Let users choose which group occupies the 4th tab position (Grains, Equity, Edible Oils, Spices) via a Preferences screen. Default to Grains. This aligns with the Commodity Preferences enhancement (ENH-06).
2. **Replace Weather tab** — If Weather is least-used, move it to the More panel and give Equity its spot.
3. **Equity quick-access in Latest** — Add an Equity ticker/carousel section at the top of the Latest Updates tab.
4. **Swipeable tab groups** — Make the 4th tab position swipeable between all groups (Grains → Equity → Edible Oils → Spices → etc.)

**Recommended:** Option 1 (configurable tab) — most flexible, ties into the Preferences feature, and respects the 5-icon limit.

**Files to modify:**
- `AgriPulse/Views/ContentView.swift` — make 4th tab configurable
- `AgriPulse/Models/` — add user preference for selected tab group
- New: `PreferencesView.swift` (can be part of ENH-06)

---

### BUG-12: Duplicate articles with different Google News URLs
**Priority:** Low
**Affected areas:** Wheat tab, possibly others

**Problem:**
Same Tribune India article ("Haunted by ghost paddy scam, Haryana government tightens wheat procurement norms") appears twice with different Google News redirect URLs. Current dedup checks by link, but Google News generates unique redirect URLs for the same article fetched from different queries.

**Root cause:**
Dedup in `RSSFetcher.swift` or `NewsFilterEngine.swift` compares article `link` field, but Google News wraps the actual article URL in a unique redirect URL per query. Two fetches of the same article produce different Google News links.

**Suggested fix:**
- Add title-based dedup: Before inserting a new article, check if an article with the same title (normalized — lowercased, trimmed, stripped of source suffix like " - Tribune India") already exists for the same commodity
- Optionally: Extract the actual destination URL from the Google News redirect and dedup on that
- Apply dedup at the SwiftData insert level in `NewsService.swift`

**Files to modify:**
- `AgriPulse/Services/NewsService.swift` — add title-based dedup
- `AgriPulse/Services/RSSFetcher.swift` — optionally extract real URLs

---

## PART 2: ENHANCEMENTS

---

### ENH-01: Pagination across all commodity tabs (50 per page)
**Version:** v1.2.1
**Priority:** High

**Current state:** Only Wheat (50/page) and PIB Updates (25/page) have pagination. All other commodities show all articles in a single scrollable list.

**What to build:**
- Apply 50 articles per page across ALL commodity tabs
- "Load More" button or infinite scroll at page bottom
- Status bar: "Page X of Y · Z articles total"
- Keep existing pagination logic in `NewsFeedViewModel.swift` but make it universal

**Files to modify:**
- `AgriPulse/ViewModels/NewsFeedViewModel.swift` — make pagination default for all commodities
- `AgriPulse/Views/News/NewsFeedView.swift` — ensure "Load More" UI works generically

---

### ENH-02: Side panel styling (match Replit design)
**Version:** v1.2.1
**Priority:** Medium

**What to build:**
- Branded header with AgriPulse logo/name
- Glassmorphism background (blur + transparency)
- Group icons matching the Replit web design
- Smooth slide-in animation

**Files to modify:**
- `AgriPulse/Views/SidePanelView.swift`
- `AgriPulse/Theme/AgriPulseTheme.swift`

---

### ENH-03: Swipe gesture for side panel
**Version:** v1.2.1
**Priority:** Medium

**What to build:**
- Swipe right from left edge to open side panel
- Swipe left to close
- Use `DragGesture` with threshold detection

**Files to modify:**
- `AgriPulse/Views/ContentView.swift` — add gesture recognizer
- `AgriPulse/Views/SidePanelView.swift` — handle gesture state

---

### ENH-04: Remember last selected sub-tab per group
**Version:** v1.2.1
**Priority:** Low

**Current state:** When navigating away from a group (e.g., Grains > Paddy) and coming back, it resets to the first sub-tab (Wheat).

**What to build:**
- Store last selected sub-tab index per group in `@AppStorage` or `UserDefaults`
- Restore on navigation back

**Files to modify:**
- `AgriPulse/Views/Groups/CommodityGroupView.swift`
- `AgriPulse/ViewModels/SidebarViewModel.swift`

---

### ENH-05: Pull-to-refresh with toast notification
**Version:** v1.2.1
**Priority:** Low

**What to build:**
- Pull-to-refresh gesture on all news list views
- After refresh completes, show a brief toast: "12 new articles found"
- Use SwiftUI `.refreshable` modifier

**Files to modify:**
- `AgriPulse/Views/News/NewsFeedView.swift`
- `AgriPulse/Views/Groups/CommodityGroupView.swift`

---

### ENH-06: Commodity Preferences screen
**Version:** v1.3
**Priority:** High

**What to build:**
- Toggle commodities on/off (hide ones user doesn't care about)
- Reorder favorites (drag to rearrange)
- Choose which group shows in the bottom tab bar (Grains, Equity, Edible Oils, Spices)
- Add `isEnabled: Bool` (default true) to Commodity SwiftData model
- Accessible from Settings/More tab

**Architecture:**
```
Commodity model changes:
  + isEnabled: Bool (default true)

New views:
  + PreferencesView (toggle commodities, select tab group)
```

**Files to modify:**
- `AgriPulse/Models/Commodity.swift` — add `isEnabled`
- New: `AgriPulse/Views/PreferencesView.swift`
- `AgriPulse/Views/ContentView.swift` — read tab group preference
- `AgriPulse/AgriPulseApp.swift` — migration for new field

---

### ENH-07: Dedicated fetchers for PIB, DGFT, IMD, Packaging
**Version:** v1.3
**Priority:** High

**What to build:**
Port Replit's 4 specialized content fetchers:

1. **PIB fetcher** — Direct scrape of `pib.gov.in/allRel.aspx` (past 7 days) + Google News fallback with 5 search terms + 25 agricultural keyword filter. Age cutoff: 90 days.
2. **DGFT fetcher** — 6 search terms combining site:dgft.gov.in and commodity keywords. Age cutoff: 90 days.
3. **IMD fetcher** — 12 search terms (IMD, ICAR, agromet, KVK). Age cutoff: 60 days.
4. **Packaging fetcher** — 12 specialized queries (BOPP, laminates, food packaging). Age cutoff: 30 days.

**Files to modify:**
- New: `AgriPulse/Services/DGFTFetcher.swift`
- New: `AgriPulse/Services/IMDFetcher.swift`
- New: `AgriPulse/Services/PackagingFetcher.swift`
- `AgriPulse/Services/PIBService.swift` — enhance with Replit logic
- `AgriPulse/Services/NewsService.swift` — integrate new fetchers

---

### ENH-08: PDF export with date range filtering
**Version:** v1.3
**Priority:** Medium

**What to build:**
- Date picker (month/year) before exporting saved articles to PDF
- Filter saved articles by selected date range
- Export only articles within the range

**Files to modify:**
- `AgriPulse/Views/Saved/PDFExportView.swift`
- `AgriPulse/ViewModels/SavedArticlesViewModel.swift`

---

### ENH-09: Commodity Calendar as dedicated tab or prominent placement
**Version:** v1.3
**Priority:** Medium

**What to build:**
- Either make Calendar a bottom tab (replacing one of the current 5) or add it as a prominent card/section in the Latest tab
- 130+ agricultural events already defined — just needs better discoverability

**Files to modify:**
- `AgriPulse/Views/ContentView.swift`
- `AgriPulse/Views/Calendar/CommodityCalendarView.swift`

---

### ENH-10: Collapsible search bar on mobile
**Version:** v1.3
**Priority:** Low

**What to build:**
- Search bar collapsed by default (shows as icon)
- Tap to expand, auto-collapse when scrolling down
- Saves screen real estate on smaller phones

**Files to modify:**
- `AgriPulse/Views/News/NewsFeedView.swift`

---

### ENH-11: Custom search queries per commodity
**Version:** v1.3-1.4
**Priority:** Medium

**What to build:**
- Settings view per commodity showing all Google News search queries
- Users can edit existing queries, add new ones (e.g., "Basmati Pusa 1121 Karnal")
- Toggle individual queries on/off
- Preview results before saving
- Store user queries separately from system queries

**Architecture:**
```
Commodity model changes:
  + userQueries: String? (JSON-encoded user-added queries)

New views:
  + CommoditySettingsView (edit queries per commodity)
```

**Files to modify:**
- `AgriPulse/Models/Commodity.swift` — add `userQueries`
- New: `AgriPulse/Views/CommoditySettingsView.swift`
- `AgriPulse/Services/RSSFetcher.swift` — merge user + system queries

---

### ENH-12: Custom RSS sources
**Version:** v1.3-1.4
**Priority:** Medium

**What to build:**
- "Add Source" button — paste any RSS feed URL
- Assign to an existing commodity or create a new one
- Validation: fetch the feed, show preview of articles before saving
- Stored in SwiftData

**Files to modify:**
- New: `AgriPulse/Views/AddSourceView.swift`
- `AgriPulse/Models/` — new RSSSource model
- `AgriPulse/Services/RSSFetcher.swift` — fetch from custom sources

---

### ENH-13: Push notifications for breaking news
**Version:** v1.4+
**Priority:** High

**What to build:**
- Local push notifications for articles < 30 minutes old
- Triggered during background refresh
- User can configure which commodities trigger notifications
- Uses `UNUserNotificationCenter`

**Files to modify:**
- `AgriPulse/Services/BackgroundRefreshManager.swift`
- `AgriPulse/AgriPulseApp.swift` — request notification permission
- New: `AgriPulse/Services/NotificationService.swift`

---

### ENH-14: iOS home screen price widgets
**Version:** v1.4+
**Priority:** High

**What to build:**
- WidgetKit extension showing key commodity prices
- Small widget: 1 commodity price
- Medium widget: 3-4 commodity prices
- Requires a price data source (see ENH-15)

**Files to modify:**
- New: `AgriPulseWidget/` widget extension target
- Xcode project configuration for widget extension

---

### ENH-15: Mandi price data (AGMARKNET API)
**Version:** v1.4+
**Priority:** High

**What to build:**
- Integrate AGMARKNET API for live mandi prices
- Price cards in commodity views showing current rates
- Historical price data for trends
- Powers the widget (ENH-14) and charts (ENH-17)

**Files to modify:**
- New: `AgriPulse/Services/PriceService.swift`
- New: `AgriPulse/Models/PriceData.swift`
- `AgriPulse/Views/News/NewsFeedView.swift` — price card section

---

### ENH-16: Watchlist (top 5 personalized feed)
**Version:** v1.4+
**Priority:** Medium

**What to build:**
- Users pick their top 5 commodities
- Dedicated "My Watchlist" section in Latest tab or as a separate view
- Quick-access to favorite commodities without navigating groups

**Files to modify:**
- `AgriPulse/Models/Commodity.swift` — add `isWatchlisted: Bool`
- New: `AgriPulse/Views/WatchlistView.swift`

---

### ENH-17: Price trend charts
**Version:** v1.4+
**Priority:** Medium

**What to build:**
- Line charts showing price trends for key commodities (like TempTracker has for temperatures)
- Daily/weekly/monthly views
- Requires price data (ENH-15)
- Use Swift Charts framework

**Files to modify:**
- New: `AgriPulse/Views/Charts/PriceChartView.swift`

---

### ENH-18: Native share sheet for articles
**Version:** v1.4+
**Priority:** Medium

**What to build:**
- Share button on each news card
- Opens iOS share sheet with article title + URL
- Pre-formatted text for WhatsApp/Telegram sharing

**Files to modify:**
- `AgriPulse/Views/News/NewsCardView.swift` — add share button
- Use `ShareLink` (SwiftUI) or `UIActivityViewController`

---

### ENH-19: WhatsApp/Telegram formatted sharing
**Version:** v1.4+
**Priority:** High

**What to build:**
- One-tap share formatted article summaries
- Format: Bold title + snippet + source + link
- Deep link to WhatsApp/Telegram if installed
- Extends ENH-18 with formatted text

**Files to modify:**
- Same as ENH-18 + formatting logic

---

### ENH-20: iPad split view
**Version:** v1.4+
**Priority:** Low

**What to build:**
- `NavigationSplitView` showing group list on left + article list on right
- Already partially implemented for iPad — needs polish

**Files to modify:**
- `AgriPulse/Views/ContentView.swift`
- `AgriPulse/Views/SidebarView.swift`

---

### ENH-21: App Store Optimization
**Version:** v1.4+
**Priority:** Medium

**What to build:**
- Better App Store keywords targeting agricultural traders/farmers
- Localized description in Hindi
- Better screenshots showcasing key features

**Files to modify:**
- App Store Connect metadata (not code)
- `AgriPulse/screenshots/generate.py` — new screenshots

---

### ENH-22: Rate/review prompt
**Version:** v1.4+
**Priority:** Medium

**What to build:**
- Use `SKStoreReviewController.requestReview()` after 5th app session
- Track session count in `@AppStorage`
- Show max once per 3 months

**Files to modify:**
- `AgriPulse/AgriPulseApp.swift` — session tracking + review prompt

---

### ENH-23: Cross-promote Commodity-Watcher web version
**Version:** v1.4+
**Priority:** Low

**What to build:**
- "Web Version" link in Settings/About section
- Opens Replit-hosted Commodity-Watcher in Safari

**Files to modify:**
- `AgriPulse/Views/` — add to More/Settings section

---

### ENH-24: Fully custom commodities
**Version:** v1.4+
**Priority:** Low

**What to build:**
- User creates a brand new commodity (e.g., "Jute", "Rubber")
- Define name, search queries, title keywords
- Assign to an existing group or create a custom group
- Basically a user-facing version of `CommoditySeeds`

**Architecture:**
```
Commodity model changes:
  + isCustom: Bool (default false)
  + userQueries: String? (user-added queries, JSON)

New views:
  + CreateCommodityView
  + CommoditySettingsView (edit queries/keywords)
  + AddSourceView (paste RSS URL, assign to commodity)
```

**Files to modify:**
- `AgriPulse/Models/Commodity.swift`
- New: `AgriPulse/Views/CreateCommodityView.swift`
- `AgriPulse/Services/NewsService.swift` — handle custom commodities in refresh

---

## SUMMARY

| Category | Count | High | Medium | Low |
|----------|-------|------|--------|-----|
| Bugs | 12 | 6 | 5 | 1 |
| Enhancements | 24 | 7 | 9 | 8 |
| **Total** | **36** | **13** | **14** | **9** |

### Suggested execution order (bugs first):
1. BUG-01 (HTML stripping) + BUG-04 (missing queries/sources) — biggest user-visible impact
2. BUG-03 (retention) + BUG-05 (empty tabs) + BUG-06 (IMD/ICAR) — content coverage
3. BUG-02 (AI summary) + BUG-07 (Latest tab) + BUG-08 (India/Global) — data quality
4. BUG-10 (contrast) + BUG-09 (Currency) + BUG-12 (dedup) — polish
5. ENH-01 (pagination) + BUG-11 (Equity access) — UX
6. Then enhancements by version target
