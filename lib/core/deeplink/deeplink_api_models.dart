import 'package:freezed_annotation/freezed_annotation.dart';

part 'deeplink_api_models.freezed.dart';

@freezed
abstract class ResolveDeeplinkRequest with _$ResolveDeeplinkRequest {
  const ResolveDeeplinkRequest._();

  const factory ResolveDeeplinkRequest({String? link, String? shortId}) =
      _ResolveDeeplinkRequest;

  Map<String, dynamic> toJson() {
    final linkValue = link;
    final shortIdValue = shortId;
    return {
      if (linkValue != null && linkValue.isNotEmpty) 'link': linkValue,
      if (shortIdValue != null && shortIdValue.isNotEmpty)
        'short_id': shortIdValue,
    };
  }
}

@freezed
abstract class ResolveDeeplinkResponse with _$ResolveDeeplinkResponse {
  const ResolveDeeplinkResponse._();

  const factory ResolveDeeplinkResponse({String? originalUrl}) =
      _ResolveDeeplinkResponse;

  factory ResolveDeeplinkResponse.fromJson(Map<String, dynamic> json) {
    final url =
        json['original_url'] as String? ??
        json['originalUrl'] as String? ??
        json['url'] as String?;
    return ResolveDeeplinkResponse(originalUrl: url);
  }

  String? get resolvedUrl {
    final value = originalUrl?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }
}
