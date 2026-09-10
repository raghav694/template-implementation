import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:app_template/core/config/app_config.dart';
import 'package:app_template/core/network/api_routes.dart';
import 'package:app_template/core/network/auth_token_store.dart';
import 'package:app_template/core/network/rest_session.dart';

/// Intercepts 401s and refreshes the access token:
/// `POST /public/tenants/{tenant}/token/refresh` with `{ refresh_token }`.
///
/// Concurrent 401s share one refresh. A separate [Dio] is used so the
/// refresh call cannot recurse into this interceptor.
class TokenRefreshInterceptor extends Interceptor {
  TokenRefreshInterceptor({
    required Dio refreshDio,
    required AuthTokenStore tokenStore,
    required RestSession session,
  }) : _refreshDio = refreshDio,
       _tokenStore = tokenStore,
       _session = session;

  final Dio _refreshDio;
  final AuthTokenStore _tokenStore;
  final RestSession _session;

  var _isRefreshing = false;
  Completer<String?>? _refreshCompleter;

  static bool _isExcluded(String path) {
    return ApiRoutes.isUnauthenticatedAuthPath(path);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401 ||
        _isExcluded(err.requestOptions.path)) {
      handler.next(err);
      return;
    }

    final currentAccess = _tokenStore.accessToken;
    final requestAuth = err.requestOptions.headers['Authorization'] as String?;
    if (currentAccess != null &&
        currentAccess.isNotEmpty &&
        requestAuth != null &&
        requestAuth != 'Bearer $currentAccess') {
      try {
        final response = await _retry(err.requestOptions, currentAccess);
        handler.resolve(response);
      } catch (_) {
        handler.next(err);
      }
      return;
    }

    if (_isRefreshing) {
      try {
        final newToken = await _refreshCompleter?.future;
        if (newToken != null) {
          final response = await _retry(err.requestOptions, newToken);
          handler.resolve(response);
        } else {
          handler.next(err);
        }
      } catch (_) {
        handler.next(err);
      }
      return;
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<String?>();

    try {
      final refreshToken = _tokenStore.refreshToken;
      if (refreshToken == null ||
          refreshToken.isEmpty ||
          !AppConfig.hasAuthConfig) {
        await _signOut();
        _refreshCompleter!.complete(null);
        handler.next(err);
        return;
      }

      final response = await _refreshDio.post<Map<String, dynamic>>(
        ApiRoutes.refreshTokenFor(AppConfig.authTenantId),
        data: {'refresh_token': refreshToken},
      );
      final tokens = _tokensFrom(response.data);
      final access = tokens.accessToken;
      if (access.isEmpty) {
        throw StateError('Refresh succeeded but no access token returned');
      }

      await _tokenStore.saveTokens(
        accessToken: access,
        refreshToken: tokens.refreshToken.isNotEmpty
            ? tokens.refreshToken
            : refreshToken,
      );
      _refreshCompleter!.complete(access);

      final retryResponse = await _retry(err.requestOptions, access);
      handler.resolve(retryResponse);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Token refresh failed: $error');
      }
      if (!_refreshCompleter!.isCompleted) {
        _refreshCompleter!.complete(null);
      }
      await _signOut();
      handler.next(err);
    } finally {
      _isRefreshing = false;
      _refreshCompleter = null;
    }
  }

  Future<void> _signOut() async {
    await _tokenStore.clear();
    _session.emit(null);
  }

  Future<Response<dynamic>> _retry(
    RequestOptions requestOptions,
    String accessToken,
  ) {
    final headers = Map<String, dynamic>.from(requestOptions.headers);
    headers['Authorization'] = 'Bearer $accessToken';

    return _refreshDio.fetch(requestOptions.copyWith(headers: headers));
  }

  static ({String accessToken, String refreshToken}) _tokensFrom(dynamic data) {
    Map<String, dynamic> asMap(dynamic value) {
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value);
      return {};
    }

    final root = asMap(data);
    final nested = asMap(root['tokens']);
    final source = nested.isNotEmpty ? nested : root;
    return (
      accessToken: source['access_token'] as String? ?? '',
      refreshToken: source['refresh_token'] as String? ?? '',
    );
  }
}
