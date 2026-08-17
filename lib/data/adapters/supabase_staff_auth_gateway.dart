import 'package:flutter/foundation.dart';
import 'package:smart_nagpur/data/gateways/staff_auth_gateway.dart';
import 'package:smart_nagpur/domain/domain.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStaffAuthGateway implements StaffAuthGateway {
  const SupabaseStaffAuthGateway({required this.client});

  final SupabaseClient client;

  @override
  Future<StaffProfile?> getCurrentStaff() async {
    try {
      final user = client.auth.currentUser;
      if (user == null) return null;

      final response = await client
          .from('staff_profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        await client.auth.signOut();
        return null;
      }

      final profile = StaffProfile.fromJson(Map<String, Object?>.from(response));
      if (!profile.isActive) {
        await client.auth.signOut();
        return null;
      }

      return profile;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<StaffProfile> loginStaff(String email, String password) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();

      // 1. Authenticate with Supabase Auth
      final authResponse = await client.auth.signInWithPassword(
        email: normalizedEmail,
        password: password,
      );

      final user = authResponse.user;
      if (user == null) {
        throw const AuthException('Authentication failed. No user returned.');
      }

      // 2. Query staff profile
      final profileResponse = await client
          .from('staff_profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profileResponse == null) {
        // Not a registered staff member
        await client.auth.signOut();
        throw Exception(
          'No municipal staff profile found for this account. Please contact your administrator.',
        );
      }

      final profile = StaffProfile.fromJson(
        Map<String, Object?>.from(profileResponse),
      );

      // 3. Verify active status
      if (!profile.isActive) {
        await client.auth.signOut();
        throw Exception(
          'Your staff account is currently inactive. Please contact the administrator.',
        );
      }

      // 4. Update last active timestamp
      try {
        await client
            .from('staff_profiles')
            .update({'last_active_at': DateTime.now().toIso8601String()})
            .eq('id', user.id);
      } catch (_) {}

      return profile;
    } catch (e, stack) {
      debugPrint('[StaffAuth] Login failed for $email: $e\n$stack');
      if (e is AuthException) {
        throw Exception(e.message.isNotEmpty ? e.message : 'Invalid staff credentials. Please try again.');
      }
      rethrow;
    }
  }

  @override
  Future<void> logoutStaff() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> setDutyStatus(bool isOnDuty) async {
    try {
      final user = client.auth.currentUser;
      if (user == null) {
        throw Exception('Staff is not authenticated.');
      }

      await client.from('staff_profiles').update({
        'is_on_duty': isOnDuty,
        'last_active_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> isStaffAuthenticated() async {
    final user = client.auth.currentUser;
    if (user == null) return false;
    final staff = await getCurrentStaff();
    return staff != null && staff.isActive;
  }
}
