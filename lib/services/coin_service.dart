import 'package:dio/dio.dart';
import '../models/coin_model.dart';
import '../utils/api_client.dart';

class CoinService {
  CoinService._();
  static final CoinService instance = CoinService._();

  final Dio _dio = ApiClient.instance.dio;

  // ─── Get Global Stats ───────────────────────────────────────────────────────
  /// Fetches global crypto market stats: totalCoins, marketCap, volume, etc.
  Future<GlobalStats> getGlobalStats() async {
    try {
      final response = await _dio.get('/stats');
      final data = response.data['data'] as Map<String, dynamic>;
      return GlobalStats.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── Get Coins List ─────────────────────────────────────────────────────────
  /// Fetches paginated list of coins with sparkline + stats.
  /// [limit] — number of coins per page (default 20)
  /// [offset] — pagination offset
  /// [timePeriod] — '3h' | '24h' | '7d' | '30d' | '3m' | '1y' | '3y' | '5y'
  /// [orderBy] — 'marketCap' | 'price' | 'volume' | 'change'
  Future<CoinsResponse> getCoins({
    int limit = 20,
    int offset = 0,
    String timePeriod = '24h',
    String orderBy = 'marketCap',
  }) async {
    try {
      final response = await _dio.get(
        '/coins',
        queryParameters: {
          'limit': limit,
          'offset': offset,
          'timePeriod': timePeriod,
          'orderBy': orderBy,
          'referenceCurrencyUuid': 'yhjMzLPhuIDl', // USD
        },
      );
      return CoinsResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── Search Coins ───────────────────────────────────────────────────────────
  /// Search coins by name or symbol.
  Future<List<CoinModel>> searchCoins(String query) async {
    try {
      final response = await _dio.get(
        '/search-suggestions',
        queryParameters: {'query': query},
      );
      final data = response.data['data'] as Map<String, dynamic>;
      final coins = data['coins'] as List<dynamic>? ?? [];
      return coins
          .map((e) => CoinModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── Get Coin Detail ────────────────────────────────────────────────────────
  /// Fetches full details for a single coin by UUID.
  /// [timePeriod] controls the sparkline range.
  Future<CoinDetail> getCoinDetail(
      String uuid, {
        String timePeriod = '7d',
      }) async {
    try {
      final response = await _dio.get(
        '/coin/$uuid',
        queryParameters: {
          'timePeriod': timePeriod,
          'referenceCurrencyUuid': 'yhjMzLPhuIDl', // USD
        },
      );
      final data = response.data['data'] as Map<String, dynamic>;
      final coin = data['coin'] as Map<String, dynamic>;
      return CoinDetail.fromJson(coin);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── Get Coin Price History ─────────────────────────────────────────────────
  /// Returns list of [timePeriod, price] pairs for charting.
  Future<List<Map<String, dynamic>>> getCoinHistory(
      String uuid, {
        String timePeriod = '7d',
      }) async {
    try {
      final response = await _dio.get(
        '/coin/$uuid/history',
        queryParameters: {
          'timePeriod': timePeriod,
          'referenceCurrencyUuid': 'yhjMzLPhuIDl',
        },
      );
      final data = response.data['data'] as Map<String, dynamic>;
      final history = data['history'] as List<dynamic>? ?? [];
      return history
          .where((e) => e['price'] != null)
          .map((e) => {
        'price': double.tryParse(e['price'].toString()) ?? 0.0,
        'timestamp': e['timestamp'] as int? ?? 0,
      })
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── Error Handler ──────────────────────────────────────────────────────────
  Exception _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return Exception('Connection timed out. Check your internet.');
      case DioExceptionType.connectionError:
        return Exception('No internet connection.');
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        final msg = e.response?.data?['message'] ?? 'Server error';
        return Exception('[$code] $msg');
      case DioExceptionType.cancel:
        return Exception('Request was cancelled.');
      default:
        return Exception('Something went wrong. Try again.');
    }
  }
}