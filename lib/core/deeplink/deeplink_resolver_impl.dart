import 'package:app_template/core/deeplink/deeplink_api_models.dart';
import 'package:app_template/core/deeplink/deeplink_api_service.dart';
import 'package:app_template/core/deeplink/deeplink_resolver.dart';
import 'package:app_template/core/logging/app_log.dart';
import 'package:app_template/core/network/app_api_client.dart';

class DeeplinkResolverImpl implements DeeplinkResolver {
  DeeplinkResolverImpl(this._deeplinks, this._client);

  final DeeplinkApiService _deeplinks;
  final AppApiClient _client;

  @override
  Future<Uri?> resolve({String? link, String? shortId}) async {
    final hasLink = link != null && link.isNotEmpty;
    final hasShortId = shortId != null && shortId.isNotEmpty;
    if (!hasLink && !hasShortId) return null;

    try {
      final response = await _client.run(
        () => _deeplinks.resolve(
          ResolveDeeplinkRequest(
            link: hasLink ? link : null,
            shortId: hasShortId ? shortId : null,
          ),
        ),
      );
      final original = response.resolvedUrl;
      if (original == null) return null;
      return Uri.tryParse(original);
    } catch (error, stackTrace) {
      AppLog.e('Deeplink resolve failed', error, stackTrace);
      return null;
    }
  }
}
