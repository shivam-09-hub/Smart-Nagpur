import 'package:smart_nagpur/domain/domain.dart';

abstract class AdminAuthGateway {
  Future<AdminProfile?> getCurrentAdmin();
  Future<AdminProfile> loginAdmin(String email, String password);
  Future<void> logoutAdmin();
  Future<void> updateAdminProfile(AdminProfile profile);
  Future<void> changeAdminPassword(String oldPassword, String newPassword);
  Future<bool> isAdminAuthenticated();
  Future<AdminProfile?> getAdminById(String adminId);
  Future<List<AdminProfile>> getAllAdmins();
  Future<void> createAdmin(String email, String password, AdminProfile profile);
  Future<void> deactivateAdmin(String adminId);
}
