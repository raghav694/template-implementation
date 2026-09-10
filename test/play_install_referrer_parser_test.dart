import 'package:app_template/core/attribution/play_install_referrer_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses utm and short_id from a Play referrer string', () {
    final params = parseInstallReferrer(
      'utm_source=google-play&utm_medium=organic&short_id=abc123&ref=campaign',
    );
    expect(params['utm_source'], 'google-play');
    expect(params['utm_medium'], 'organic');
    expect(params['short_id'], 'abc123');
    expect(params['ref'], 'campaign');
  });

  test('url-decodes values', () {
    final params = parseInstallReferrer('utm_source=facebook%20ads');
    expect(params['utm_source'], 'facebook ads');
  });
}
