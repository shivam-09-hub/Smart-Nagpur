import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_nagpur/core/config/config.dart';

void main() {
  group('SupabaseConfig', () {
    test('normalizes a REST endpoint to its project URL', () {
      final config = SupabaseConfig.fromValues(
        projectUrl: ' https://example-project.supabase.co/rest/v1/ ',
        publishableKey: 'sb_publishable_mobile_test_key',
      );

      expect(config.projectUrl, 'https://example-project.supabase.co');
      expect(config.publishableKey, 'sb_publishable_mobile_test_key');
      expect(config.validate, returnsNormally);
    });

    test('accepts a publishable client key', () {
      final config = SupabaseConfig.fromValues(
        projectUrl: 'https://example-project.supabase.co',
        publishableKey: 'sb_publishable_safe_for_mobile_clients',
      );

      expect(config.validate, returnsNormally);
    });

    test('accepts only anon-role legacy JWT client keys', () {
      String jwtForRole(String role) {
        final header = base64Url.encode(utf8.encode('{"alg":"HS256"}'));
        final payload = base64Url.encode(
          utf8.encode(jsonEncode({'role': role})),
        );
        return '$header.$payload.signature';
      }

      final anonConfig = SupabaseConfig.fromValues(
        projectUrl: 'https://example-project.supabase.co',
        publishableKey: jwtForRole('anon'),
      );
      final serviceRoleConfig = SupabaseConfig.fromValues(
        projectUrl: 'https://example-project.supabase.co',
        publishableKey: jwtForRole('service_role'),
      );

      expect(anonConfig.validate, returnsNormally);
      expect(
        serviceRoleConfig.validate,
        throwsA(isA<BackendConfigurationException>()),
      );
    });

    test('rejects a missing publishable key', () {
      final config = SupabaseConfig.fromValues(
        projectUrl: 'https://example-project.supabase.co',
        publishableKey: '   ',
      );

      expect(config.validate, throwsA(isA<BackendConfigurationException>()));
    });

    test('rejects secret and service-role keys', () {
      for (final key in [
        'sb_secret_must_not_ship',
        'service_role_must_not_ship',
      ]) {
        final config = SupabaseConfig.fromValues(
          projectUrl: 'https://example-project.supabase.co',
          publishableKey: key,
        );

        expect(
          config.validate,
          throwsA(isA<BackendConfigurationException>()),
          reason: '$key must never be accepted by a mobile build',
        );
      }
    });
  });
}
