import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig(String apiBaseUrl, {bool allowLocalHttp = kDebugMode})
    : apiBaseUri = _parse(apiBaseUrl, allowLocalHttp);

  factory AppConfig.fromEnvironment() =>
      AppConfig(const String.fromEnvironment('API_BASE_URL'));

  final Uri? apiBaseUri;

  static Uri? _parse(String value, bool allowLocalHttp) {
    if (value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    const localHosts = {'10.0.2.2', '127.0.0.1', 'localhost'};
    if (uri == null ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        !(uri.scheme == 'https' ||
            (allowLocalHttp &&
                uri.scheme == 'http' &&
                localHosts.contains(uri.host)))) {
      throw const FormatException(
        'API_BASE_URL must be HTTPS, or local HTTP in a debug build, '
        'without credentials, query or fragment.',
      );
    }
    return uri.replace(
      path: uri.path.endsWith('/') ? uri.path : '${uri.path}/',
    );
  }
}
