import 'package:smart_nagpur/data/gateways/admin_auth_gateway.dart';
import 'package:smart_nagpur/domain/domain.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAdminAuthGateway implements AdminAuthGateway {
  const SupabaseAdminAuthGateway({required this.client});

  final SupabaseClient client;

  @override
  Future<AdminProfile?> getCurrentAdmin() async {
    try {
      final user = client.auth.currentUser;
      if (user == null) return null;

      final response = await client
          .from('admin_profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) return null;
      return AdminProfile.fromJson(Map<String, Object?>.from(response));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AdminProfile> loginAdmin(String email, String password) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) throw Exception('Login failed');

      // Update last login
      await client
          .from('admin_profiles')
          .update({'last_login_at': DateTime.now().toIso8601String()})
          .eq('id', user.id);

      // Get admin profile
      final adminResponse = await client
          .from('admin_profiles')
          .select()
          .eq('id', user.id)
          .single();

      return AdminProfile.fromJson(Map<String, Object?>.from(adminResponse));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> logoutAdmin() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateAdminProfile(AdminProfile profile) async {
    try {
      await client
          .from('admin_profiles')
          .update({
            'name': profile.name,
            'phone': profile.phone,
            'is_active': profile.isActive,
          })
          .eq('id', profile.id);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> changeAdminPassword(
    String oldPassword,
    String newPassword,
  ) async {
    try {
      await client.auth.updateUser(UserAttributes(password: newPassword));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> isAdminAuthenticated() async {
    try {
      final user = client.auth.currentUser;
      if (user == null) return false;

      final response = await client
          .from('admin_profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) return false;

      final profile = AdminProfile.fromJson(
        Map<String, Object?>.from(response),
      );
      return profile.isActive;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<AdminProfile?> getAdminById(String adminId) async {
    try {
      final response = await client
          .from('admin_profiles')
          .select()
          .eq('id', adminId)
          .maybeSingle();

      if (response == null) return null;
      return AdminProfile.fromJson(Map<String, Object?>.from(response));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<AdminProfile>> getAllAdmins() async {
    try {
      final response = await client
          .from('admin_profiles')
          .select()
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((item) => AdminProfile.fromJson(Map<String, Object?>.from(item)))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> createAdmin(
    String email,
    String password,
    AdminProfile profile,
  ) async {
    try {
      // Create auth user
      final response = await client.auth.admin.createUser(
        AdminUserAttributes(
          email: email,
          password: password,
          emailConfirm: true,
        ),
      );

      // Create admin profile
      await client.from('admin_profiles').insert({
        'id': response.user!.id,
        'name': profile.name,
        'email': email,
        'phone': profile.phone,
        'role': profile.role.name,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deactivateAdmin(String adminId) async {
    try {
      await client
          .from('admin_profiles')
          .update({'is_active': false})
          .eq('id', adminId);
    } catch (e) {
      rethrow;
    }
  }
}
