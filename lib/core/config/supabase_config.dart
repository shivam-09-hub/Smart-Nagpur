import 'dart:convert';

class BackendConfigurationException implements Exception {
  const BackendConfigurationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SupabaseConfig {
  const SupabaseConfig({
    required this.projectUrl,
    required this.publishableKey,
  });

  static const defaultProjectUrl = 'https://hcpcycfvupjuklhcaxzg.supabase.co';
  static const defaultPublishableKey =
      'sb_publishable_bKO_IvESPlRkSNT1er_lgw_1MYoES5Y';
  static const authCallbackUrl = 'com.smartnagpur.citizen://login-callback/';

  final String projectUrl;
  final String publishableKey;

  factory SupabaseConfig.fromEnvironment() {
    const url = String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: defaultProjectUrl,
    );
    const key = String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
      defaultValue: defaultPublishableKey,
    );
    return SupabaseConfig.fromValues(projectUrl: url, publishableKey: key);
  }

  factory SupabaseConfig.fromValues({
    required String projectUrl,
    required String publishableKey,
  }) {
    var normalizedUrl = projectUrl.trim();
    normalizedUrl = normalizedUrl.replaceFirst(
      RegExp(r'/rest/v1/?$', caseSensitive: false),
      '',
    );
    normalizedUrl = normalizedUrl.replaceFirst(RegExp(r'/$'), '');
    return SupabaseConfig(
      projectUrl: normalizedUrl,
      publishableKey: publishableKey.trim(),
    );
  }

  void validate() {
    final uri = Uri.tryParse(projectUrl);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        !uri.host.endsWith('.supabase.co')) {
      throw const BackendConfigurationException(
        'SUPABASE_URL must be an HTTPS Supabase project URL.',
      );
    }
    if (publishableKey.isEmpty ||
        publishableKey.startsWith('sb_secret_') ||
        publishableKey.startsWith('service_role')) {
      throw const BackendConfigurationException(
        'Use a Supabase publishable key in the mobile app, never a secret key.',
      );
    }
    final supportedClientKey =
        publishableKey.startsWith('sb_publishable_') ||
        _isLegacyAnonKey(publishableKey);
    if (!supportedClientKey) {
      throw const BackendConfigurationException(
        'SUPABASE_PUBLISHABLE_KEY is missing or invalid.',
      );
    }
  }

  static bool _isLegacyAnonKey(String key) {
    final segments = key.split('.');
    if (segments.length != 3) return false;
    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(segments[1]))),
      );
      return payload is Map<String, dynamic> && payload['role'] == 'anon';
    } catch (_) {
      return false;
    }
  }
}
