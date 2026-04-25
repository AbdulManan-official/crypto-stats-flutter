# CryptoTrack — Project Reference

## Overview
Flutter crypto tracker app using the Coinranking API v2.
Displays global market stats, top coins list, sparklines, price charts, and coin details.

---

## Tech Stack

| Layer | Package |
|-------|---------|
| State | `get ^4.6.6` (GetX) |
| HTTP | `dio ^5.9.1` |
| Charts | `fl_chart ^1.1.0` |
| Shimmer | `shimmer ^3.0.0` |
| Fonts | `google_fonts ^6.2.1` |
| SVG Icons | `flutter_svg ^2.0.10` |
| Formatting | `intl ^0.20.1` |

---

## Folder Structure

```
lib/
├── utils/
│   ├── api_client.dart       ← Dio singleton + API key + interceptors
│   ├── app_theme.dart        ← AppColors + AppTheme.dark (Inter font)
│   └── responsive.dart       ← Responsive helpers + BuildContext extensions
├── models/
│   └── coin_model.dart       ← GlobalStats, CoinModel, CoinsResponse,
│                                CoinDetail, CoinLink
├── services/
│   └── coin_service.dart     ← All API calls (singleton)
├── viewmodels/
│   └── coin_viewmodel.dart   ← GetX controller (all state + business logic)
├── screens/
│   ├── home_screen.dart      ← Stats + coin list + search + filters
│   ├── detail_screen.dart    ← Price chart + stats + about
│   └── widgets.dart          ← All reusable widgets
└── main.dart                 ← App entry, GetX init, theme
```

---

## API

**Base URL:** `https://api.coinranking.com/v2`
**Auth header:** `x-access-token: DHYX0XOIUG7NPCI`
**Reference currency UUID (USD):** `yhjMzLPhuIDl`

### Endpoints Used

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/stats` | Global market stats |
| GET | `/coins` | Paginated coins list |
| GET | `/coin/:uuid` | Single coin detail |
| GET | `/coin/:uuid/history` | Price history for chart |
| GET | `/search-suggestions?query=` | Search coins |

### Query Params — `/coins`
- `limit` — items per page (default 20)
- `offset` — pagination offset
- `timePeriod` — `3h | 24h | 7d | 30d | 3m | 1y`
- `orderBy` — `marketCap | price | volume | change`
- `referenceCurrencyUuid` — `yhjMzLPhuIDl` (USD)

---

## State — CoinViewModel

All state lives in `CoinViewModel` (registered via `Get.put` in `main.dart`).

### Key Observables

```dart
Rx<GlobalStats?>    stats              // global market data
RxBool              statsLoading
RxString            statsError

RxList<CoinModel>   coins              // paginated list
RxBool              coinsLoading
RxBool              coinsLoadingMore
RxString            coinsError

Rx<CoinDetail?>     selectedCoin       // detail screen
RxBool              detailLoading

RxList<Map>         priceHistory       // chart data [{price, timestamp}]
RxBool              historyLoading

RxList<CoinModel>   searchResults
RxBool              searchLoading
RxString            searchQuery        // debounced 400ms

RxString            selectedTimePeriod // '24h' default
RxString            selectedOrderBy    // 'marketCap' default
```

### Key Methods

```dart
fetchStats()                          // load global stats
fetchCoins({refresh: true})           // load/refresh coin list
loadMoreCoins()                       // pagination — call on scroll end
refreshAll()                          // pull-to-refresh both
setTimePeriod(period)                 // filter + auto-refresh
setOrderBy(orderBy)                   // sort + auto-refresh
fetchCoinDetail(uuid)                 // load detail screen data
fetchPriceHistory(uuid, timePeriod)   // load chart data
onSearchChanged(query)                // triggers debounced search
clearSearch()                         // clear search state
```

---

## Colors — AppColors

```dart
AppColors.background    // #0A0A0F  — scaffold bg
AppColors.surface       // #13131A  — cards bg
AppColors.card          // #1C1C26  — widget cards
AppColors.cardLight     // #242432  — elevated cards
AppColors.primary       // #3B82F6  — blue accent
AppColors.primaryLight  // #60A5FA
AppColors.primaryGlow   // #333B82F6 — 20% opacity blue
AppColors.textPrimary   // #F1F5F9
AppColors.textSecondary // #94A3B8
AppColors.textMuted     // #475569
AppColors.success       // #22C55E  — green (positive change)
AppColors.error         // #EF4444  — red (negative change)
AppColors.warning       // #F59E0B  — orange
AppColors.border        // #1E1E2E
AppColors.shimmerBase      // shimmer base color
AppColors.shimmerHighlight // shimmer highlight color
```

---

## Widgets — widgets.dart

| Widget | Purpose |
|--------|---------|
| `CoinCard` | Full coin row: rank + icon + name + sparkline + price + change |
| `StatCard` | Label + value + optional icon for stats grid |
| `CoinIcon` | SVG/PNG coin icon with fallback placeholder |
| `MiniSparkline` | Small fl_chart line chart for coin list |
| `ChangeBadge` | Green/red % badge with arrow icon |
| `TimePeriodSelector` | Animated horizontal pill period filter |
| `SectionHeader` | Title + optional right action link |
| `AppErrorWidget` | Error with retry (inline or fullscreen) |
| `AppEmptyWidget` | Empty state with icon + action |
| `LoadMoreIndicator` | Spinner for pagination bottom |
| `CoinListShimmer` | List of 8 `CoinCardShimmer` skeletons |
| `StatsRowShimmer` | Row of 2 `StatCardShimmer` skeletons |

### Formatters (in widgets.dart)
```dart
formatPrice(double)    // $42,123.45 or $0.000123 for tiny coins
formatCompact(double)  // $1.23T / $456.78B / $12.34M
formatChange(double)   // +2.45% / -1.20%
```

---

## Responsive

```dart
// BuildContext extensions
context.screenWidth
context.screenHeight
context.isMobile       // < 600
context.isTablet       // 600–1024
context.isDesktop      // > 1024
context.wp(50)         // 50% of screen width
context.hp(30)         // 30% of screen height
context.horizontalPadding  // EdgeInsets: 16 mobile, 32 tablet, 64 desktop

// Static helpers
Responsive.adaptive(context, mobile: x, tablet: y, desktop: z)
```

---

## Navigation

```dart
// Home → Detail
Get.to(() => DetailScreen(coin: coin));

// Back
Get.back();
```

Always call before navigating to detail:
```dart
vm.fetchCoinDetail(coin.uuid);
vm.fetchPriceHistory(coin.uuid, timePeriod: '7d');
```

---

## Adding a New Screen

1. Create `lib/screens/new_screen.dart`
2. Add methods to `CoinViewModel` if needed
3. Add new service methods to `CoinService` if new endpoint
4. Add models to `coin_model.dart` if new response shape
5. Navigate via `Get.to(() => NewScreen())`

---

## Common Patterns

### Obx reactive widget
```dart
Obx(() => vm.coinsLoading.value
  ? CoinListShimmer()
  : CoinList(coins: vm.coins))
```

### Pull to refresh
```dart
RefreshIndicator(
  onRefresh: vm.refreshAll,
  child: ListView(...)
)
```

### Pagination trigger
```dart
// At end of SliverList, check and trigger
if (index == vm.coins.length) {
  vm.loadMoreCoins();
  return LoadMoreIndicator();
}
```

### Handle all 4 states
```dart
if (vm.loading.value)        → show shimmer
if (vm.error.value.isNotEmpty && vm.data.isEmpty) → show AppErrorWidget
if (vm.data.isEmpty)         → show AppEmptyWidget
else                         → show real data
```

---

## pubspec.yaml Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  dio: ^5.9.1
  get: ^4.6.6
  shimmer: ^3.0.0
  fl_chart: ^1.1.0
  google_fonts: ^6.2.1
  flutter_svg: ^2.0.10
  intl: ^0.20.1
```
