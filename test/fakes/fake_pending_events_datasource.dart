import 'package:app_template/features/analytics/data/pending_event.dart';
import 'package:app_template/features/analytics/data/pending_events_datasource.dart';

class FakePendingEventsDataSource implements PendingEventsDataSource {
  FakePendingEventsDataSource({this.events = const [], this.listError});

  List<PendingEvent> events;
  Object? listError;
  final markedDone = <String>[];
  final markDoneErrors = <String, Object>{};

  @override
  Future<List<PendingEvent>> listPending() async {
    if (listError != null) throw listError!;
    return List.of(events);
  }

  @override
  Future<void> markDone(String eventId) async {
    final error = markDoneErrors[eventId];
    if (error != null) throw error;
    markedDone.add(eventId);
  }
}
