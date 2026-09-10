/// Parses a Play Install Referrer string (`utm_source=…&utm_medium=…&short_id=…`).
Map<String, String> parseInstallReferrer(String referrer) {
  final result = <String, String>{};
  for (final pair in referrer.split('&')) {
    final parts = pair.split('=');
    if (parts.length != 2 || parts[0].isEmpty) continue;
    result[parts[0]] = Uri.decodeComponent(parts[1]);
  }
  return result;
}
