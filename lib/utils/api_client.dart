import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://api.coinranking.com/v2';
  static const String apiKey = 'coinranking41b95eff7ca7e2ea50b045abbdcd9da584d679d8c82efd80';
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
}

class ApiClient {
  ApiClient._();

  static final ApiClient _instance = ApiClient._();
  static ApiClient get instance => _instance;

  late final Dio _dio;

  Dio get dio => _dio;

  void init() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'x-access-token': ApiConstants.apiKey,
        },
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(),
      if (kDebugMode) _LogInterceptor(),
    ]);
  }
}

// Adds API key to every request automatically
class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['x-access-token'] = ApiConstants.apiKey;
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final message = _parseError(err);
    debugPrint('[API ERROR] $message');
    handler.next(err);
  }

  String _parseError(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out';
      case DioExceptionType.connectionError:
        return 'No internet connection';
      case DioExceptionType.badResponse:
        final code = err.response?.statusCode;
        return 'Server error: $code';
      case DioExceptionType.cancel:
        return 'Request cancelled';
      default:
        return 'Unexpected error: ${err.message}';
    }
  }
}

// Debug logger — only in debug mode
class _LogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('[API] --> ${options.method} ${options.path}');
    if (options.queryParameters.isNotEmpty) {
      debugPrint('[API] params: ${options.queryParameters}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('[API] <-- ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('[API] ERROR ${err.response?.statusCode} ${err.requestOptions.path}');
    handler.next(err);
  }
}