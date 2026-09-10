import 'dart:convert';

import 'package:capslock_payments_sdk/capslock_payments_sdk.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:app_template/core/error/exceptions.dart';

/// Dio adapter for the SDK's [HttpCheckoutTransport].
///
/// Capslock checkout is a separate origin from [AppApiClient] and does not
/// send the app JWT. Gateway (Cashfree / PhonePe) is chosen server-side.
class CapslockHttpSender {
  CapslockHttpSender._();

  static final Dio _dio =
      Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 20),
            responseType: ResponseType.plain,
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          ),
        )
        ..interceptors.addAll([
          if (kDebugMode)
            LogInterceptor(requestBody: true, responseBody: false),
        ]);

  static Future<CheckoutHttpResponse> send(CheckoutHttpRequest request) async {
    try {
      final response = await _dio.requestUri<String>(
        request.uri,
        data: request.body,
        options: Options(method: request.method),
      );
      return CheckoutHttpResponse(
        statusCode: response.statusCode ?? 0,
        body: response.data ?? '',
      );
    } on DioException catch (error) {
      final status = error.response?.statusCode ?? 0;
      final body = _bodyOf(error.response?.data);
      if (status > 0) {
        return CheckoutHttpResponse(statusCode: status, body: body);
      }
      throw NetworkException(error.message ?? 'Network connection failed');
    }
  }

  static String _bodyOf(dynamic data) {
    if (data == null) return '';
    if (data is String) return data;
    try {
      return jsonEncode(data);
    } catch (_) {
      return data.toString();
    }
  }
}
