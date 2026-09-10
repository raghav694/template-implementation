import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Local record of an in-flight checkout. Written on Continue, enriched
/// when `initiatePayment` returns, cleared after `addBalanceSuccess` is sent.
class PendingPurchase {
  const PendingPurchase({
    required this.eventId,
    required this.userId,
    required this.planId,
    required this.initiatedAtMs,
    required this.subscriptionStatus,
    this.amountInr,
    this.subscriptionId,
    this.paymentId,
    this.trialAmount,
    this.subscriptionAmount,
    this.mediaURL,
    this.planFrequency,
    this.isPayAsYouGo = false,
    this.paymentApps = const [],
    this.selectedPackageName,
    this.paymentMethod,
  });

  final String eventId;
  final String userId;
  final String planId;
  final int initiatedAtMs;
  final String subscriptionStatus;
  final double? amountInr;
  final String? subscriptionId;
  final String? paymentId;
  final int? trialAmount;
  final int? subscriptionAmount;
  final String? mediaURL;
  final String? planFrequency;
  final bool isPayAsYouGo;
  final List<String> paymentApps;
  final String? selectedPackageName;
  final String? paymentMethod;

  bool get isFirstPurchase => subscriptionStatus == 'free';

  PendingPurchase withCheckout({
    required String subscriptionId,
    required String paymentId,
    String? planId,
  }) {
    return PendingPurchase(
      eventId: eventId,
      userId: userId,
      planId: (planId != null && planId.isNotEmpty) ? planId : this.planId,
      initiatedAtMs: initiatedAtMs,
      subscriptionStatus: subscriptionStatus,
      amountInr: amountInr,
      subscriptionId: subscriptionId,
      paymentId: paymentId,
      trialAmount: trialAmount,
      subscriptionAmount: subscriptionAmount,
      mediaURL: mediaURL,
      planFrequency: planFrequency,
      isPayAsYouGo: isPayAsYouGo,
      paymentApps: paymentApps,
      selectedPackageName: selectedPackageName,
      paymentMethod: paymentMethod,
    );
  }

  Map<String, dynamic> toJson() => {
    'eventId': eventId,
    'userId': userId,
    'planId': planId,
    'initiatedAtMs': initiatedAtMs,
    'subscriptionStatus': subscriptionStatus,
    if (amountInr != null) 'amountInr': amountInr,
    if (subscriptionId != null) 'subscriptionId': subscriptionId,
    if (paymentId != null) 'paymentId': paymentId,
    if (trialAmount != null) 'trialAmount': trialAmount,
    if (subscriptionAmount != null) 'subscriptionAmount': subscriptionAmount,
    if (mediaURL != null) 'mediaURL': mediaURL,
    if (planFrequency != null) 'planFrequency': planFrequency,
    'isPayAsYouGo': isPayAsYouGo,
    'paymentApps': paymentApps,
    if (selectedPackageName != null) 'selectedPackageName': selectedPackageName,
    if (paymentMethod != null) 'paymentMethod': paymentMethod,
  };

  factory PendingPurchase.fromJson(Map<String, dynamic> json) {
    final appsRaw = json['paymentApps'];
    final apps = appsRaw is List
        ? appsRaw.map((e) => e.toString()).toList()
        : const <String>[];
    return PendingPurchase(
      eventId: json['eventId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      planId: json['planId'] as String? ?? '',
      initiatedAtMs: (json['initiatedAtMs'] as num?)?.toInt() ?? 0,
      subscriptionStatus: json['subscriptionStatus'] as String? ?? 'free',
      amountInr: (json['amountInr'] as num?)?.toDouble(),
      subscriptionId: json['subscriptionId'] as String?,
      paymentId: json['paymentId'] as String?,
      trialAmount: (json['trialAmount'] as num?)?.toInt(),
      subscriptionAmount: (json['subscriptionAmount'] as num?)?.toInt(),
      mediaURL: json['mediaURL'] as String?,
      planFrequency: json['planFrequency'] as String?,
      isPayAsYouGo: json['isPayAsYouGo'] as bool? ?? false,
      paymentApps: apps,
      selectedPackageName: json['selectedPackageName'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
    );
  }
}

class PendingPurchaseCache {
  PendingPurchaseCache({SharedPreferences? prefs}) : _prefsOverride = prefs;

  static const _pendingKey = 'pending_add_balance_success';
  static const _reportedKey = 'reported_add_balance_success_ids';
  static const _maxAge = Duration(days: 7);

  final SharedPreferences? _prefsOverride;

  Future<SharedPreferences> get _prefs async =>
      _prefsOverride ?? SharedPreferences.getInstance();

  Future<void> markInitiated({
    required String userId,
    required String planId,
    required String subscriptionStatus,
    double? amountInr,
    int? trialAmount,
    int? subscriptionAmount,
    String? mediaURL,
    String? planFrequency,
    bool isPayAsYouGo = false,
    List<String> paymentApps = const [],
    String? selectedPackageName,
    String? paymentMethod,
  }) async {
    final prefs = await _prefs;
    await prefs.setString(
      _pendingKey,
      jsonEncode(
        PendingPurchase(
          eventId: _uuidV4(),
          userId: userId,
          planId: planId,
          initiatedAtMs: DateTime.now().millisecondsSinceEpoch,
          subscriptionStatus: subscriptionStatus,
          amountInr: amountInr,
          trialAmount: trialAmount,
          subscriptionAmount: subscriptionAmount,
          mediaURL: mediaURL,
          planFrequency: planFrequency,
          isPayAsYouGo: isPayAsYouGo,
          paymentApps: paymentApps,
          selectedPackageName: selectedPackageName,
          paymentMethod: paymentMethod,
        ).toJson(),
      ),
    );
  }

  Future<void> attachCheckout({
    required String subscriptionId,
    required String paymentId,
    String? planId,
  }) async {
    final current = await readPending();
    if (current == null) return;
    final prefs = await _prefs;
    await prefs.setString(
      _pendingKey,
      jsonEncode(
        current
            .withCheckout(
              subscriptionId: subscriptionId,
              paymentId: paymentId,
              planId: planId,
            )
            .toJson(),
      ),
    );
  }

  Future<PendingPurchase?> readPending() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_pendingKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final pending = PendingPurchase.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      final age = DateTime.now().millisecondsSinceEpoch - pending.initiatedAtMs;
      if (pending.userId.isEmpty || age > _maxAge.inMilliseconds) {
        await clearPending();
        return null;
      }
      return pending;
    } catch (_) {
      await clearPending();
      return null;
    }
  }

  Future<void> clearPending() async {
    final prefs = await _prefs;
    await prefs.remove(_pendingKey);
  }

  Future<bool> hasReported(String? id) async {
    if (id == null || id.isEmpty) return false;
    final prefs = await _prefs;
    return (prefs.getStringList(_reportedKey) ?? const []).contains(id);
  }

  Future<void> markReported(String? id) async {
    if (id == null || id.isEmpty) return;
    final prefs = await _prefs;
    final ids = [...?prefs.getStringList(_reportedKey)];
    if (ids.contains(id)) return;
    ids.add(id);
    if (ids.length > 32) {
      ids.removeRange(0, ids.length - 32);
    }
    await prefs.setStringList(_reportedKey, ids);
  }

  static String _uuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int index) => bytes[index].toRadixString(16).padLeft(2, '0');
    return '${hex(0)}${hex(1)}${hex(2)}${hex(3)}-'
        '${hex(4)}${hex(5)}-'
        '${hex(6)}${hex(7)}-'
        '${hex(8)}${hex(9)}-'
        '${hex(10)}${hex(11)}${hex(12)}${hex(13)}${hex(14)}${hex(15)}';
  }
}
