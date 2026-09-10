import 'dart:async';
import 'dart:convert';

import 'package:app_template/core/config/app_config.dart';
import 'package:app_template/core/error/exceptions.dart';
import 'package:app_template/core/network/app_api_client.dart';
import 'package:app_template/core/network/auth_token_store.dart';
import 'package:app_template/core/network/json_map.dart';
import 'package:app_template/core/network/rest_session.dart';
import 'package:app_template/features/auth/data/datasources/auth_api_service.dart';
import 'package:app_template/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:app_template/features/auth/data/models/auth_api_models.dart';
import 'package:app_template/features/auth/data/models/user_model.dart';
import 'package:app_template/features/auth/data/models/verify_otp_response.dart';

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({
    required AuthApiService authApi,
    required AppApiClient client,
    required AuthTokenStore tokenStore,
    required RestSession session,
  }) : _authApi = authApi,
       _client = client,
       _tokenStore = tokenStore,
       _session = session;

  final AuthApiService _authApi;
  final AppApiClient _client;
  final AuthTokenStore _tokenStore;
  final RestSession _session;
  var _hydrated = false;

  /// Restores tokens from disk only. Must not await network — the splash
  /// screen is gated on this stream's first event.
  Future<void> _hydrate() async {
    if (_hydrated) return;
    _hydrated = true;
    await _tokenStore.load();
    if (!_tokenStore.hasSession) return;
    final cached = _userFromStoredJson(_tokenStore.userJson);
    if (cached != null) {
      _session.restore(cached);
    }
    unawaited(_refreshProfile());
  }

  Future<void> _refreshProfile() async {
    try {
      await getCurrentUserDocument();
    } catch (_) {
      // Cached profile is enough until the next 401.
    }
  }

  @override
  Stream<UserModel?> authStateChanges() async* {
    await _hydrate();
    yield* _session.changes;
  }

  @override
  Future<String> sendPhoneVerification(String phoneNumber) async {
    final tenant = _tenantCode;
    await _client.runAuth(
      () => _authApi.sendOtp(tenant, SendOtpRequest(phone: phoneNumber)),
    );
    return phoneNumber;
  }

  @override
  Future<UserModel> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final tenant = _tenantCode;
    final response = await _client.runAuth(
      () => _authApi.verifyOtp(
        tenant,
        VerifyOtpRequest(phone: verificationId, otp: smsCode),
      ),
    );
    return _persistSession(response);
  }

  @override
  Future<UserModel> verifyTruecallerLogin({
    required String authorizationCode,
    required String codeVerifier,
  }) async {
    final tenant = _tenantCode;
    final response = await _client.runAuth(
      () => _authApi.verifyTruecaller(
        tenant,
        VerifyTruecallerRequest(
          authorizationCode: authorizationCode,
          codeVerifier: codeVerifier,
        ),
      ),
    );
    return _persistSession(response);
  }

  Future<UserModel> _persistSession(VerifyOtpResponse response) async {
    final user = response.user;
    final access = response.tokens.accessToken;
    if (access.isEmpty) {
      throw const AuthException('Login succeeded but no access token returned');
    }
    await _tokenStore.save(
      accessToken: access,
      refreshToken: response.tokens.refreshToken,
      userJson: jsonEncode(user.toStoreJson()),
    );
    _session.emit(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    await _tokenStore.clear();
    _session.emit(null);
  }

  @override
  Future<UserModel?> getCurrentUserDocument() async {
    if (!_tokenStore.hasSession) return _session.user;
    final user = await _client.runAuth(_loadProfile);
    await _tokenStore.save(
      accessToken: _tokenStore.accessToken ?? '',
      refreshToken: _tokenStore.refreshToken ?? '',
      userJson: jsonEncode(user.toStoreJson()),
    );
    _session.emit(user);
    return user;
  }

  Future<UserModel> _loadProfile() {
    final tenant = _tenantCode;
    final userId = _session.user?.id.trim() ?? '';
    if (userId.isNotEmpty) {
      return _authApi.getProfileByUserId(tenant, userId);
    }
    final phone = _session.user?.phone.trim() ?? '';
    if (phone.isEmpty) {
      throw const AuthException('No user id or phone to load profile');
    }
    return _authApi.getProfileByPhone(tenant, phone: phone);
  }

  static String get _tenantCode {
    final tenant = AppConfig.authTenantId;
    if (tenant.isEmpty) {
      throw const ServerException('AUTH_TENANT_ID is not configured');
    }
    return tenant;
  }

  static UserModel? _userFromStoredJson(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return UserModel.fromJson(JsonMap.of(jsonDecode(raw)));
    } catch (_) {
      return null;
    }
  }
}
