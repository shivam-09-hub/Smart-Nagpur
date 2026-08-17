import 'package:flutter/material.dart';
import 'package:smart_nagpur/core/config/config.dart';
import 'package:smart_nagpur/core/theme/theme.dart';
import 'package:smart_nagpur/data/adapters/supabase_staff_auth_gateway.dart';
import 'package:smart_nagpur/data/adapters/supabase_staff_data_gateway.dart';
import 'package:smart_nagpur/features/staff/presentation/staff_login_screen.dart';
import 'package:smart_nagpur/features/staff/presentation/staff_shell.dart';
import 'package:smart_nagpur/state/staff_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = SupabaseConfig.fromEnvironment();
  config.validate();
  await Supabase.initialize(
    url: config.projectUrl,
    publishableKey: config.publishableKey,
    debug: false,
  );

  runApp(const StaffApp());
}

class StaffApp extends StatefulWidget {
  const StaffApp({super.key});

  @override
  State<StaffApp> createState() => _StaffAppState();
}

class _StaffAppState extends State<StaffApp> {
  late final StaffController _staffController;

  @override
  void initState() {
    super.initState();
    final supabaseClient = Supabase.instance.client;

    _staffController = StaffController(
      authGateway: SupabaseStaffAuthGateway(client: supabaseClient),
      dataGateway: SupabaseStaffDataGateway(client: supabaseClient),
    );

    // Verify existing session
    _staffController.checkAuthStatus();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Nagpur Staff',
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: ListenableBuilder(
        listenable: _staffController,
        builder: (context, _) {
          if (_staffController.isAuthenticated) {
            return StaffShell(controller: _staffController);
          }
          return StaffLoginScreen(controller: _staffController);
        },
      ),
    );
  }
}
