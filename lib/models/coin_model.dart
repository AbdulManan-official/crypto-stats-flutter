// ─── Global Stats Model ───────────────────────────────────────────────────────
class GlobalStats {
  final int totalCoins;
  final int totalMarkets;
  final int totalExchanges;
  final String totalMarketCap;
  final String total24hVolume;
  final double btcDominance;

  const GlobalStats({
    required this.totalCoins,
    required this.totalMarkets,
    required this.totalExchanges,
    required this.totalMarketCap,
    required this.total24hVolume,
    required this.btcDominance,
  });

  factory GlobalStats.fromJson(Map<String, dynamic> json) {
    return GlobalStats(
      totalCoins: json['totalCoins'] as int? ?? 0,
      totalMarkets: json['totalMarkets'] as int? ?? 0,
      totalExchanges: json['totalExchanges'] as int? ?? 0,
      totalMarketCap: json['totalMarketCap'] as String? ?? '0',
      total24hVolume: json['total24hVolume'] as String? ?? '0',
      btcDominance: double.tryParse(
        json['btcDominance']?.toString() ?? '0',
      ) ??
          0.0,
    );
  }
}

// ─── Coin Model ───────────────────────────────────────────────────────────────
class CoinModel {
  final String uuid;
  final String symbol;
  final String name;
  final String? iconUrl;
  final String? price;
  final String? marketCap;
  final String? change;         // % change (e.g. "2.45" or "-1.20")
  final String? volume24h;
  final int rank;
  final List<String> sparkline; // price history points for chart
  final bool listedAt;          // true = recently listed

  const CoinModel({
    required this.uuid,
    required this.symbol,
    required this.name,
    this.iconUrl,
    this.price,
    this.marketCap,
    this.change,
    this.volume24h,
    required this.rank,
    this.sparkline = const [],
    this.listedAt = false,
  });

  factory CoinModel.fromJson(Map<String, dynamic> json) {
    final rawSparkline = json['sparkline'] as List<dynamic>? ?? [];
    final sparkline = rawSparkline
        .where((e) => e != null)
        .map((e) => e.toString())
        .toList();

    return CoinModel(
      uuid: json['uuid'] as String? ?? '',
      symbol: json['symbol'] as String? ?? '',
      name: json['name'] as String? ?? '',
      iconUrl: json['iconUrl'] as String?,
      price: json['price'] as String?,
      marketCap: json['marketCap'] as String?,
      change: json['change'] as String?,
      volume24h: json['24hVolume'] as String?,
      rank: int.tryParse(json['rank']?.toString() ?? '0') ?? 0,
      sparkline: sparkline,
      listedAt: json['listedAt'] != null,
    );
  }

  // Helpers
  double get priceDouble => double.tryParse(price ?? '0') ?? 0.0;
  double get changeDouble => double.tryParse(change ?? '0') ?? 0.0;
  bool get isPositive => changeDouble >= 0;
  double get marketCapDouble => double.tryParse(marketCap ?? '0') ?? 0.0;
  double get volumeDouble => double.tryParse(volume24h ?? '0') ?? 0.0;

  /// Safe sparkline as list of doubles for fl_chart
  List<double> get sparklineDoubles {
    return sparkline
        .map((e) => double.tryParse(e) ?? 0.0)
        .toList();
  }
}

// ─── Coins Response Wrapper ───────────────────────────────────────────────────
class CoinsResponse {
  final List<CoinModel> coins;
  final int total;
  final GlobalStats? stats;

  const CoinsResponse({
    required this.coins,
    required this.total,
    this.stats,
  });

  factory CoinsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final coinsList = data['coins'] as List<dynamic>? ?? [];
    final statsData = data['stats'] as Map<String, dynamic>?;

    return CoinsResponse(
      coins: coinsList
          .map((e) => CoinModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (statsData?['total'] as int?) ?? coinsList.length,
      stats: statsData != null ? GlobalStats.fromJson(statsData) : null,
    );
  }
}

// ─── Coin Detail Model ────────────────────────────────────────────────────────
class CoinDetail {
  final String uuid;
  final String symbol;
  final String name;
  final String? iconUrl;
  final String? description;
  final String? price;
  final String? marketCap;
  final String? change;
  final String? volume24h;
  final String? allTimeHigh;
  final int rank;
  final List<String> sparkline;
  final List<CoinLink> links;
  final String? websiteUrl;

  const CoinDetail({
    required this.uuid,
    required this.symbol,
    required this.name,
    this.iconUrl,
    this.description,
    this.price,
    this.marketCap,
    this.change,
    this.volume24h,
    this.allTimeHigh,
    required this.rank,
    this.sparkline = const [],
    this.links = const [],
    this.websiteUrl,
  });

  factory CoinDetail.fromJson(Map<String, dynamic> json) {
    final rawSparkline = json['sparkline'] as List<dynamic>? ?? [];
    final sparkline = rawSparkline
        .where((e) => e != null)
        .map((e) => e.toString())
        .toList();

    final rawLinks = json['links'] as List<dynamic>? ?? [];
    final links = rawLinks
        .map((e) => CoinLink.fromJson(e as Map<String, dynamic>))
        .toList();

    return CoinDetail(
      uuid: json['uuid'] as String? ?? '',
      symbol: json['symbol'] as String? ?? '',
      name: json['name'] as String? ?? '',
      iconUrl: json['iconUrl'] as String?,
      description: json['description'] as String?,
      price: json['price'] as String?,
      marketCap: json['marketCap'] as String?,
      change: json['change'] as String?,
      volume24h: json['24hVolume'] as String?,
      allTimeHigh: (json['allTimeHigh'] as Map<String, dynamic>?)?['price'] as String?,
      rank: json['rank'] as int? ?? 0,
      sparkline: sparkline,
      links: links,
      websiteUrl: json['websiteUrl'] as String?,
    );
  }

  double get priceDouble => double.tryParse(price ?? '0') ?? 0.0;
  double get changeDouble => double.tryParse(change ?? '0') ?? 0.0;
  bool get isPositive => changeDouble >= 0;
  double get marketCapDouble => double.tryParse(marketCap ?? '0') ?? 0.0;
  double get volumeDouble => double.tryParse(volume24h ?? '0') ?? 0.0;

  List<double> get sparklineDoubles =>
      sparkline.map((e) => double.tryParse(e) ?? 0.0).toList();
}

// ─── Coin Link Model ──────────────────────────────────────────────────────────
class CoinLink {
  final String name;
  final String url;
  final String type;

  const CoinLink({
    required this.name,
    required this.url,
    required this.type,
  });

  factory CoinLink.fromJson(Map<String, dynamic> json) {
    return CoinLink(
      name: json['name'] as String? ?? '',
      url: json['url'] as String? ?? '',
      type: json['type'] as String? ?? '',
    );
  }
}