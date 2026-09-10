/// Store-update and maintenance flags from Remote Config, optionally
/// overlaid with `GET /api/v1/config/status`.
class AppConfigStatus {
  const AppConfigStatus({
    this.forceUpdate = false,
    this.isUnderMaintenance = false,
    this.title,
    this.message,
  });

  static const idle = AppConfigStatus();

  final bool forceUpdate;
  final bool isUnderMaintenance;
  final String? title;
  final String? message;

  /// Either source can turn a flag on. Non-empty [other] copy wins.
  AppConfigStatus mergedWith(AppConfigStatus other) {
    return AppConfigStatus(
      forceUpdate: forceUpdate || other.forceUpdate,
      isUnderMaintenance: isUnderMaintenance || other.isUnderMaintenance,
      title: _prefer(other.title, title),
      message: _prefer(other.message, message),
    );
  }

  AppConfigStatus copyWith({
    bool? forceUpdate,
    bool? isUnderMaintenance,
    String? title,
    String? message,
  }) {
    return AppConfigStatus(
      forceUpdate: forceUpdate ?? this.forceUpdate,
      isUnderMaintenance: isUnderMaintenance ?? this.isUnderMaintenance,
      title: title ?? this.title,
      message: message ?? this.message,
    );
  }

  static String? _prefer(String? primary, String? fallback) {
    final a = primary?.trim();
    if (a != null && a.isNotEmpty) return a;
    final b = fallback?.trim();
    if (b != null && b.isNotEmpty) return b;
    return null;
  }

  static Map<String, dynamic> asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  /// Accepts a raw JSON body or a `{ "data": { ... } }` wrapper.
  factory AppConfigStatus.fromJson(Map<String, dynamic> json) {
    final map = asMap(json);
    final nested = map['data'];
    final source = nested is Map ? asMap(nested) : map;
    return AppConfigStatus(
      forceUpdate: _asBool(source['force_update']) ?? false,
      isUnderMaintenance: _asBool(source['is_app_under_maintenance']) ?? false,
      title: source['title'] as String?,
      message: source['message'] as String?,
    );
  }

  factory AppConfigStatus.fromResponse(dynamic body) {
    return AppConfigStatus.fromJson(asMap(body));
  }

  static bool? _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase().trim();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
    return null;
  }
}
