import 'package:flutter/material.dart';
import 'package:smart_nagpur/core/config/config.dart';
import 'package:smart_nagpur/core/theme/theme.dart';
import 'package:smart_nagpur/data/adapters/supabase_admin_auth_gateway.dart';
import 'package:smart_nagpur/data/adapters/supabase_admin_data_gateway.dart';
import 'package:smart_nagpur/features/admin/presentation/admin_complaints_screen.dart';
import 'package:smart_nagpur/features/admin/presentation/admin_complaint_detail_screen.dart';
import 'package:smart_nagpur/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:smart_nagpur/features/admin/presentation/admin_login_screen.dart';
import 'package:smart_nagpur/features/admin/presentation/admin_notifications_screen.dart';
import 'package:smart_nagpur/features/admin/presentation/admin_users_screen.dart';
import 'package:smart_nagpur/features/admin/presentation/admin_vendor_detail_screen.dart';
import 'package:smart_nagpur/features/admin/presentation/admin_vendors_screen.dart';
import 'package:smart_nagpur/state/admin_controller.dart';
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

  runApp(const AdminApp());
}

class AdminApp extends StatefulWidget {
  const AdminApp({super.key});

  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  late final AdminController _adminController;

  @override
  void initState() {
    super.initState();
    final supabaseClient = Supabase.instance.client;

    _adminController = AdminController(
      authGateway: SupabaseAdminAuthGateway(client: supabaseClient),
      dataGateway: SupabaseAdminDataGateway(client: supabaseClient),
    );

    // Check auth status
    _adminController.checkAuthStatus();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Nagpur Admin',
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      home: ListenableBuilder(
        listenable: _adminController,
        builder: (context, _) {
          if (_adminController.isAuthenticated) {
            return AdminShell(controller: _adminController);
          }
          return AdminLoginScreen(controller: _adminController);
        },
      ),
      onGenerateRoute: (settings) {
        return _buildRoute(settings, _adminController);
      },
    );
  }

  Route<dynamic> _buildRoute(
    RouteSettings settings,
    AdminController controller,
  ) {
    switch (settings.name) {
      case '/admin/login':
        return MaterialPageRoute(
          builder: (_) => AdminLoginScreen(controller: controller),
        );
      case '/admin/dashboard':
        return MaterialPageRoute(
          builder: (_) => AdminDashboardScreen(controller: controller),
        );
      case '/admin/complaints':
        return MaterialPageRoute(
          builder: (_) => AdminComplaintsScreen(controller: controller),
        );
      case '/admin/complaint-detail':
        final complaintId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => AdminComplaintDetailScreen(
            controller: controller,
            complaintId: complaintId,
          ),
        );
      case '/admin/vendors':
        return MaterialPageRoute(
          builder: (_) => AdminVendorsScreen(controller: controller),
        );
      case '/admin/vendor-detail':
        final applicationId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => AdminVendorDetailScreen(
            controller: controller,
            applicationId: applicationId,
          ),
        );
      case '/admin/notifications':
        return MaterialPageRoute(
          builder: (_) => AdminNotificationsScreen(controller: controller),
        );
      case '/admin/users':
        return MaterialPageRoute(
          builder: (_) => AdminUsersScreen(controller: controller),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => AdminDashboardScreen(controller: controller),
        );
    }
  }
}

class AdminShell extends StatelessWidget {
  const AdminShell({required this.controller, super.key});

  final AdminController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Navigator(
        onGenerateRoute: (settings) {
          switch (settings.name ?? '') {
            case '/admin/dashboard':
              return MaterialPageRoute(
                builder: (_) => AdminDashboardScreen(controller: controller),
              );
            default:
              return MaterialPageRoute(
                builder: (_) => AdminDashboardScreen(controller: controller),
              );
          }
        },
      ),
    );
  }
}
