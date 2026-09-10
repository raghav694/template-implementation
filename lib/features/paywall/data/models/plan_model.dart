import 'package:app_template/core/network/json_map.dart';
import 'package:app_template/features/paywall/data/models/plan_dto.dart';
import 'package:app_template/features/paywall/domain/entities/plan.dart';

/// Maps REST plan JSON onto [Plan]. Prefer [PlanDto] in new code.
class PlanModel {
  const PlanModel._();

  static Plan fromJson(Map<String, dynamic> json, {String? fallbackId}) {
    return PlanDto.fromJson(json, fallbackId: fallbackId).toEntity();
  }

  static Map<String, dynamic> asMap(dynamic value) => JsonMap.of(value);
}
