import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'package:app_template/core/network/api_routes.dart';
import 'package:app_template/features/analytics/data/pending_event.dart';

part 'events_api_service.g.dart';

@RestApi()
abstract class EventsApiService {
  factory EventsApiService(Dio dio) = _EventsApiService;

  @GET(ApiRoutes.pendingEvents)
  Future<PendingEventsResponse> listPending();

  @POST(ApiRoutes.markEventDonePath)
  Future<HttpResponse<dynamic>> markDone(@Path('id') String eventId);
}
