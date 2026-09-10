import 'package:shared_preferences/shared_preferences.dart';

/// Persists REST JWTs. Access tokens are refreshed via
/// `POST /auth/refresh` before a 401 signs the user out.
class AuthTokenStore {
  static const _accessKey = 'app_rest_access_token';
  static const _refreshKey = 'app_rest_refresh_token';
  static const _userJsonKey = 'app_rest_user_json';

  String? _accessToken;
  String? _refreshToken;
  String? _userJson;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  String? get userJson => _userJson;
  bool get hasSession => _accessToken != null && _accessToken!.isNotEmpty;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(_accessKey);
    _refreshToken = prefs.getString(_refreshKey);
    _userJson = prefs.getString(_userJsonKey);
  }

  Future<void> save({
    required String accessToken,
    required String refreshToken,
    required String userJson,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _userJson = userJson;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessKey, accessToken);
    await prefs.setString(_refreshKey, refreshToken);
    await prefs.setString(_userJsonKey, userJson);
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) {
    return save(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userJson: _userJson ?? '',
    );
  }

  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    _userJson = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
    await prefs.remove(_userJsonKey);
  }
}
