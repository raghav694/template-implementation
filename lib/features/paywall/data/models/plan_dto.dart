import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:app_template/core/network/json_map.dart';
import 'package:app_template/features/paywall/domain/entities/plan.dart';

part 'plan_dto.freezed.dart';

@freezed
abstract class PlanDto with _$PlanDto {
  const PlanDto._();

  const factory PlanDto({
    required String id,
    required String label,
    required int priceAmount,
    required String billingCycle,
    @Default(PlanCategory.recurring) PlanCategory category,
    @Default('INR') String currencyCode,
    int? originalPriceAmount,
    @Default(0) int trialDays,
    int? trialAmount,
    String? videoUrl,
  }) = _PlanDto;

  factory PlanDto.fromJson(Map<String, dynamic> json, {String? fallbackId}) {
    final amountPaise = _intOf(json['amount_paise']);
    final originalPaise = _intOf(
      json['original_amount_paise'] ?? json['originalAmountPaise'],
    );
    final trialAmountPaise = _intOf(
      json['trial_amount'] ?? json['trial_amount_paise'],
    );
    final priceInr = _intOf(json['price_inr'] ?? json['priceInr']);
    final originalInr = _intOf(
      json['original_price_inr'] ?? json['originalPriceInr'],
    );
    final trialInr = _intOf(json['trial_amount_inr'] ?? json['trialAmountInr']);

    final name = (json['name'] as String?)?.trim();
    final label = (json['label'] as String?)?.trim();
    final videoUrl =
        (json['video_url'] as String? ?? json['videoUrl'] as String?)?.trim();
    final currency =
        (json['currency'] as String? ?? json['currency_code'] as String?)
            ?.trim();
    final billingCycle =
        json['frequency'] as String? ??
        json['billing_cycle'] as String? ??
        json['billingCycle'] as String? ??
        'month';

    return PlanDto(
      id:
          json['id'] as String? ??
          json['plan_id'] as String? ??
          fallbackId ??
          '',
      label: (label?.isNotEmpty == true)
          ? label!
          : (name?.isNotEmpty == true ? name! : 'Premium'),
      priceAmount: amountPaise != null
          ? (amountPaise / 100).round()
          : (priceInr ?? 0),
      originalPriceAmount: originalPaise != null
          ? (originalPaise / 100).round()
          : originalInr,
      billingCycle: billingCycle,
      category: PlanCategory.parse(
        json['category'] as String? ??
            json['plan_category'] as String? ??
            json['billing_kind'] as String? ??
            json['plan_type'] as String? ??
            json['type'] as String?,
      ),
      currencyCode: currency?.isNotEmpty == true ? currency! : 'INR',
      trialDays:
          _intOf(
            json['trial_period'] ?? json['trial_days'] ?? json['trialDays'],
          ) ??
          0,
      trialAmount: trialAmountPaise != null
          ? (trialAmountPaise / 100).round()
          : trialInr,
      videoUrl: videoUrl?.isNotEmpty == true ? videoUrl : null,
    );
  }

  Plan toEntity() => Plan(
    id: id,
    label: label,
    priceAmount: priceAmount,
    originalPriceAmount: originalPriceAmount,
    billingCycle: billingCycle,
    category: category,
    currencyCode: currencyCode,
    trialDays: trialDays,
    trialAmount: trialAmount,
    videoUrl: videoUrl,
  );

  static int? _intOf(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

@freezed
abstract class PlansResponse with _$PlansResponse {
  const factory PlansResponse({@Default([]) List<PlanDto> plans}) =
      _PlansResponse;

  factory PlansResponse.fromJson(Map<String, dynamic> json) {
    final map = JsonMap.of(json);
    final raw = map['plans'] ?? map['data'] ?? map['items'];
    final items = raw is List ? raw : const [];
    final plans = <PlanDto>[];
    for (final item in items) {
      final plan = PlanDto.fromJson(JsonMap.of(item));
      if (plan.id.isNotEmpty) plans.add(plan);
    }
    return PlansResponse(plans: plans);
  }
}
