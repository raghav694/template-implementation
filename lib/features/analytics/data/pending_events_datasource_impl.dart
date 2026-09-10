import 'package:flutter/foundation.dart';

import 'package:app_template/core/network/app_api_client.dart';
import 'package:app_template/features/analytics/data/events_api_service.dart';
import 'package:app_template/features/analytics/data/pending_event.dart';
import 'package:app_template/features/analytics/data/pending_events_datasource.dart';

class PendingEventsDataSourceImpl implements PendingEventsDataSource {
  PendingEventsDataSourceImpl(this._events, this._client);

  final EventsApiService _events;
  final AppApiClient _client;

  @override
  Future<List<PendingEvent>> listPending() async {
    final response = await _client.run(_events.listPending);
    return response.events;
  }

  @override
  Future<void> markDone(String eventId) async {
    await _client.run(() => _events.markDone(eventId));
  }

  @visibleForTesting
  static List<PendingEvent> parseList(dynamic data) {
    return PendingEventsResponse.eventsFrom(data);
  }
}
