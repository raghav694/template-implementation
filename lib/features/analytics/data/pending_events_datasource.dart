import 'package:app_template/features/analytics/data/pending_event.dart';

abstract class PendingEventsDataSource {
  Future<List<PendingEvent>> listPending();

  Future<void> markDone(String eventId);
}
