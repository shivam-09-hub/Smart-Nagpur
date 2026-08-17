import 'package:smart_nagpur/domain/domain.dart';

abstract class StaffAuthGateway {
  Future<StaffProfile?> getCurrentStaff();
  Future<StaffProfile> loginStaff(String email, String password);
  Future<void> logoutStaff();
  Future<void> setDutyStatus(bool isOnDuty);
  Future<bool> isStaffAuthenticated();
}
