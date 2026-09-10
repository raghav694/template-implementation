import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:app_template/core/config/app_config.dart';
import 'package:app_template/core/error/exceptions.dart';
import 'package:app_template/core/network/auth_token_store.dart';
import 'package:app_template/core/network/rest_session.dart';
import 'package:app_template/core/network/token_refresh_interceptor.dart';

/// Shared Dio (auth header, refresh, logging) used by Retrofit services.
///
/// [dio] talks to [AppConfig.apiBaseUrl] (events, deeplinks, config).
/// [authDio] talks to [AppConfig.authOrigin] (OTP, refresh, profile).
class AppApiClient {
  AppApiClient({
    required AuthTokenStore tokenStore,
    required RestSession session,
    Dio? dio,
    Dio? authDio,
  }) : _tokenStore = tokenStore {
    final appOrigin = AppConfig.apiBaseUrl;
    final authOrigin = AppConfig.authOrigin;

    _refreshDio = _createDio(authOrigin);
    final refreshInterceptor = TokenRefreshInterceptor(
      refreshDio: _refreshDio,
      tokenStore: tokenStore,
      session: session,
    );

    _dio = dio ?? _createDio(appOrigin);
    if (dio == null) {
      _installInterceptors(_dio, refreshInterceptor);
    }

    if (authDio != null) {
      _authDio = authDio;
    } else if (authOrigin == appOrigin) {
      _authDio = _dio;
    } else {
      _authDio = _createDio(authOrigin);
      _installInterceptors(_authDio, refreshInterceptor);
    }
  }

  late final Dio _dio;
  late final Dio _authDio;
  late final Dio _refreshDio;
  final AuthTokenStore _tokenStore;

  Dio get dio => _dio;

  Dio get authDio => _authDio;

  static Dio _createDio(String baseUrl) {
    return Dio()
      ..options.baseUrl = baseUrl
      ..options.connectTimeout = const Duration(seconds: 15)
      ..options.receiveTimeout = const Duration(seconds: 20)
      ..options.headers['Accept'] = 'application/json'
      ..options.headers['Content-Type'] = 'application/json';
  }

  void _installInterceptors(Dio dio, TokenRefreshInterceptor refresh) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _tokenStore.accessToken;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
    dio.interceptors.add(refresh);
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: false),
      );
    }
  }

  /// Runs a Retrofit call against [dio] ([AppConfig.apiBaseUrl]).
  Future<T> run<T>(Future<T> Function() request) async {
    if (AppConfig.apiBaseUrl.isEmpty) {
      throw const ServerException('API_BASE_URL is not configured');
    }
    return _mapErrors(request);
  }

  /// Runs a Retrofit call against [authDio] ([AppConfig.authOrigin]).
  Future<T> runAuth<T>(Future<T> Function() request) async {
    if (!AppConfig.hasAuthConfig) {
      throw const ServerException(
        'AUTH_BASE_URL and AUTH_TENANT_ID are not configured',
      );
    }
    return _mapErrors(request);
  }

  Future<T> _mapErrors<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw toException(error);
    }
  }

  static Exception toException(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return NetworkException(error.message ?? 'Network connection failed');
    }
    final status = error.response?.statusCode;
    final message = _messageFrom(error.response?.data) ?? error.message;
    if (status == 401 || status == 403) {
      return AuthException(message ?? 'Unauthorized', code: '$status');
    }
    return ServerException(message ?? 'Request failed');
  }

  static String? _messageFrom(dynamic data) {
    if (data is Map) {
      final error = data['error'];
      if (error is Map && error['message'] is String) {
        return error['message'] as String;
      }
      if (data['message'] is String) return data['message'] as String;
    }
    return null;
  }
}
