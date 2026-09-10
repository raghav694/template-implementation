import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:app_template/core/network/json_map.dart';

part 'pending_event.freezed.dart';

@freezed
abstract class PendingEvent with _$PendingEvent {
  const factory PendingEvent({
    required String id,
    required String eventName,
    @Default({}) Map<String, dynamic> payload,
    String? state,
  }) = _PendingEvent;

  factory PendingEvent.fromJson(Map<String, dynamic> json) {
    return PendingEvent(
      id: json['id'] as String? ?? '',
      eventName: json['event_name'] as String? ?? '',
      payload: JsonMap.of(json['payload']),
      state: json['state'] as String?,
    );
  }
}

@freezed
abstract class PendingEventsResponse with _$PendingEventsResponse {
  const factory PendingEventsResponse({
    @Default([]) List<PendingEvent> events,
  }) = _PendingEventsResponse;

  factory PendingEventsResponse.fromJson(Map<String, dynamic> json) {
    return PendingEventsResponse(events: eventsFrom(json));
  }

  static List<PendingEvent> eventsFrom(dynamic data) {
    final raw = switch (data) {
      final List list => list,
      final Map map => map['events'] ?? map['data'],
      _ => const [],
    };
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => PendingEvent.fromJson(Map<String, dynamic>.from(item)))
        .where((event) => event.id.isNotEmpty && event.eventName.isNotEmpty)
        .toList();
  }
}
