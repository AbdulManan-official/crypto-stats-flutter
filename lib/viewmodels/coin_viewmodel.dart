import 'package:get/get.dart';
import '../models/coin_model.dart';
import '../services/coin_service.dart';

class CoinViewModel extends GetxController {
  final _service = CoinService.instance;

  // ─── State ──────────────────────────────────────────────────────────────────

  // Global Stats
  final Rx<GlobalStats?> stats = Rx<GlobalStats?>(null);
  final RxBool statsLoading = true.obs;
  final RxString statsError = ''.obs;

  // Coins List
  final RxList<CoinModel> coins = <CoinModel>[].obs;
  final RxBool coinsLoading = true.obs;
  final RxBool coinsLoadingMore = false.obs;
  final RxString coinsError = ''.obs;
  final RxInt totalCoins = 0.obs;

  // Coin Detail
  final Rx<CoinDetail?> selectedCoin = Rx<CoinDetail?>(null);
  final RxBool detailLoading = false.obs;
  final RxString detailError = ''.obs;

  // Price History
  final RxList<Map<String, dynamic>> priceHistory =
      <Map<String, dynamic>>[].obs;
  final RxBool historyLoading = false.obs;

  // Search
  final RxList<CoinModel> searchResults = <CoinModel>[].obs;
  final RxBool searchLoading = false.obs;
  final RxString searchQuery = ''.obs;

  // Filters
  final RxString selectedTimePeriod = '24h'.obs;
  final RxString selectedOrderBy = 'marketCap'.obs;

  // Pagination
  static const int _pageSize = 20;
  int _offset = 0;
  bool _hasMore = true;

  // ─── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _loadInitialData();

    // Debounce search — waits 400ms after user stops typing
    debounce(
      searchQuery,
      (_) => _performSearch(searchQuery.value),
      time: const Duration(milliseconds: 400),
    );
  }

  // ─── Initial Load ────────────────────────────────────────────────────────────

  Future<void> _loadInitialData() async {
    await Future.wait([fetchStats(), fetchCoins(refresh: true)]);
  }

  // ─── Global Stats ────────────────────────────────────────────────────────────

  Future<void> fetchStats() async {
    statsLoading.value = true;
    statsError.value = '';
    try {
      stats.value = await _service.getGlobalStats();
    } catch (e) {
      statsError.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      statsLoading.value = false;
    }
  }

  // ─── Coins List ──────────────────────────────────────────────────────────────

  Future<void> fetchCoins({bool refresh = false}) async {
    if (refresh) {
      _offset = 0;
      _hasMore = true;
      coinsLoading.value = true;
      coinsError.value = '';
    }

    if (!_hasMore) return;

    try {
      final response = await _service.getCoins(
        limit: _pageSize,
        offset: _offset,
        timePeriod: selectedTimePeriod.value,
        orderBy: selectedOrderBy.value,
      );

      if (refresh) {
        coins.value = response.coins;
      } else {
        coins.addAll(response.coins);
      }

      totalCoins.value = response.total;
      _offset += response.coins.length;
      _hasMore = response.coins.length == _pageSize;
    } catch (e) {
      coinsError.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      coinsLoading.value = false;
      coinsLoadingMore.value = false;
    }
  }

  Future<void> loadMoreCoins() async {
    if (coinsLoadingMore.value || !_hasMore) return;
    coinsLoadingMore.value = true;
    await fetchCoins();
  }

  Future<void> refreshAll() async {
    await Future.wait([fetchStats(), fetchCoins(refresh: true)]);
  }

  // ─── Filter / Sort ───────────────────────────────────────────────────────────

  void setTimePeriod(String period) {
    if (selectedTimePeriod.value == period) return;
    selectedTimePeriod.value = period;
    fetchCoins(refresh: true);
  }

  void setOrderBy(String orderBy) {
    if (selectedOrderBy.value == orderBy) return;
    selectedOrderBy.value = orderBy;
    fetchCoins(refresh: true);
  }

  // ─── Coin Detail ─────────────────────────────────────────────────────────────

  Future<void> fetchCoinDetail(String uuid) async {
    detailLoading.value = true;
    detailError.value = '';
    selectedCoin.value = null;
    try {
      selectedCoin.value = await _service.getCoinDetail(
        uuid,
        timePeriod: selectedTimePeriod.value,
      );
    } catch (e) {
      detailError.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      detailLoading.value = false;
    }
  }

  // ─── Price History ───────────────────────────────────────────────────────────

  Future<void> fetchPriceHistory(
    String uuid, {
    String timePeriod = '7d',
  }) async {
    historyLoading.value = true;
    priceHistory.clear();
    try {
      priceHistory.value = await _service.getCoinHistory(
        uuid,
        timePeriod: timePeriod,
      );
    } catch (e) {
      // history errors are non-critical, just clear
      priceHistory.clear();
    } finally {
      historyLoading.value = false;
    }
  }

  // ─── Search ──────────────────────────────────────────────────────────────────

  void onSearchChanged(String query) {
    searchQuery.value = query.trim();
    if (query.trim().isEmpty) {
      searchResults.clear();
      searchLoading.value = false;
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      searchResults.clear();
      return;
    }
    searchLoading.value = true;
    try {
      searchResults.value = await _service.searchCoins(query);
    } catch (e) {
      searchResults.clear();
    } finally {
      searchLoading.value = false;
    }
  }

  void clearSearch() {
    searchQuery.value = '';
    searchResults.clear();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  bool get hasMoreCoins => _hasMore;
  bool get isSearching => searchQuery.value.isNotEmpty;

  /// Available time period options
  static const List<String> timePeriods = [
    '3h',
    '24h',
    '7d',
    '30d',
    '3m',
    '1y',
  ];

  /// Available sort options
  static const List<String> orderByOptions = [
    'marketCap',
    'price',
    'volume',
    'change',
  ];

  static const Map<String, String> orderByLabels = {
    'marketCap': 'Market Cap',
    'price': 'Price',
    'volume': 'Volume',
    'change': 'Change',
  };
}
