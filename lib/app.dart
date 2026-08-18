import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:smart_nagpur/core/localization/app_strings.dart';
import 'package:smart_nagpur/core/theme/theme.dart';
import 'package:smart_nagpur/domain/domain.dart';
import 'package:smart_nagpur/features/auth/auth.dart';
import 'package:smart_nagpur/features/bootstrap/bootstrap.dart';
import 'package:smart_nagpur/features/complaints/complaints.dart';
import 'package:smart_nagpur/features/news/news.dart';
import 'package:smart_nagpur/features/profile/profile.dart';
import 'package:smart_nagpur/features/requests/requests.dart';
import 'package:smart_nagpur/features/search/search.dart';
import 'package:smart_nagpur/features/services/services.dart';
import 'package:smart_nagpur/features/shell/shell.dart';
import 'package:smart_nagpur/features/vendor/vendor.dart';
import 'package:smart_nagpur/state/app_controller.dart';

class SmartNagpurApp extends StatelessWidget {
  const SmartNagpurApp({required this.controller, super.key});

  final AppController controller;

  static final navigatorKey = GlobalKey<NavigatorState>();
  static final _routeTracker = _CurrentRouteTracker();
  static bool _authGuardScheduled = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        _scheduleAuthGuard();
        return MaterialApp(
          navigatorKey: navigatorKey,
          navigatorObservers: [_routeTracker],
          title: 'NGP Seva',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          locale: controller.locale,
          supportedLocales: AppStrings.supportedLocales,
          localizationsDelegates: const [
            AppStrings.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          initialRoute: '/',
          onGenerateRoute: _onGenerateRoute,
        );
      },
    );
  }

  void _scheduleAuthGuard() {
    final routeName = _routeTracker.currentRouteName;
    if (!controller.isInitialized ||
        routeName == null ||
        _isPublicRoute(routeName) ||
        _authGuardScheduled) {
      return;
    }
    final needsRecovery =
        controller.isPasswordRecovery && routeName != '/recover-password';
    final needsLogin = !controller.isAuthenticated;
    if (!needsRecovery && !needsLogin) {
      return;
    }
    _authGuardScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authGuardScheduled = false;
      final currentRouteName = _routeTracker.currentRouteName;
      if (!controller.isInitialized ||
          currentRouteName == null ||
          _isPublicRoute(currentRouteName)) {
        return;
      }
      if (controller.isPasswordRecovery &&
          currentRouteName != '/recover-password') {
        _replaceAll('/recover-password');
      } else if (!controller.isAuthenticated) {
        _replaceAll('/login');
      }
    });
  }

  static bool _isPublicRoute(String routeName) => const {
    '/',
    '/onboarding',
    '/login',
    '/register',
    '/forgot-password',
    '/verify',
    '/otp',
  }.contains(routeName);

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    final name = settings.name ?? '/';
    final arguments = settings.arguments;

    late final Widget screen;
    switch (name) {
      case '/':
        screen = SplashScreen(
          controller: controller,
          onOnboarding: () => _replaceAll('/onboarding'),
          onLogin: () => _replaceAll('/login'),
          onHome: () => _replaceAll('/home'),
          onPasswordRecovery: () => _replaceAll('/recover-password'),
        );
      case '/onboarding':
        screen = OnboardingScreen(
          controller: controller,
          onCompleted: () => _replaceAll('/login'),
        );
      case '/login':
        screen = LoginScreen(
          controller: controller,
          onAuthenticated: () => _replaceAll('/home'),
          onRegister: () => _replace('/register'),
          onForgotPassword: () => _push('/forgot-password'),
          onPasswordRecovery: () => _replaceAll('/recover-password'),
        );
      case '/register':
        screen = RegisterScreen(
          controller: controller,
          onRegistered: () => _replaceAll('/home'),
          onConfirmationRequired: () => _replaceAll('/login'),
          onLogin: () => _replace('/login'),
        );
      case '/forgot-password':
        screen = ForgotPasswordScreen(
          controller: controller,
          onLogin: () => _replace('/login'),
          onPasswordRecovery: () => _replaceAll('/recover-password'),
        );
      case '/recover-password':
        screen = PasswordRecoveryScreen(
          controller: controller,
          onCompleted: () => _replaceAll('/home'),
          onCancel: () => _replaceAll('/login'),
        );
      case '/verify':
      case '/otp':
        screen = VerificationScreen(
          destination: arguments is String ? arguments : 'your mobile number',
          onVerified: () => _replaceAll('/login'),
          onEdit: _pop,
        );
      case '/home':
        screen = AppShell(controller: controller);
      case '/services':
        screen = AppShell(controller: controller, initialIndex: 1);
      case '/requests':
        screen = AppShell(controller: controller, initialIndex: 2);
      case '/notifications':
        screen = AppShell(controller: controller, initialIndex: 3);
      case '/profile':
      case '/settings':
        screen = AppShell(controller: controller, initialIndex: 4);
      case '/news':
        screen = NewsScreen(items: controller.news);
      case '/search':
        screen = GlobalSearchScreen(
          initialQuery: arguments is String ? arguments : null,
          services: controller.services,
          news: controller.news,
        );
      case '/complaints/create':
      case '/complaints/location':
      case '/complaints/review':
      case '/complaints/success':
        final map = arguments is Map ? arguments : const <Object?, Object?>{};
        screen = ComplaintWizardScreen(
          controller: controller,
          serviceType: map['serviceType'] is ServiceType
              ? map['serviceType'] as ServiceType
              : ServiceType.roads,
          initialIssue: map['issue'] as String?,
        );
      case '/vendor/apply':
        final map = arguments is Map ? arguments : const <Object?, Object?>{};
        screen = VendorApplicationScreen(
          controller: controller,
          sourceAction: map['sourceAction'] as String?,
        );
      case '/vendor/application':
        if (arguments is VendorApplication) {
          screen = VendorApplicationDetailScreen(
            controller: controller,
            application: arguments,
          );
        } else if (arguments is String && arguments.isNotEmpty) {
          screen = VendorApplicationDetailScreen(
            controller: controller,
            applicationId: arguments,
          );
        } else {
          screen = VendorApplicationsScreen(controller: controller);
        }
      case '/vendor/zones':
        screen = VendorZonesScreen(controller: controller);
      case '/vendor/renew':
        screen = VendorRenewalScreen(controller: controller);
      case '/vendor/documents':
        screen = VendorDocumentsScreen(controller: controller);
      case '/profile/edit':
        screen = EditProfileScreen(controller: controller);
      case '/profile/saved-locations':
        screen = SavedLocationsScreen(controller: controller);
      case '/settings/notifications':
        screen = const NotificationSettingsScreen();
      case '/settings/language':
        screen = LanguageScreen(controller: controller);
      case '/settings/privacy':
        screen = const InformationScreen(
          title: 'Privacy',
          icon: Icons.privacy_tip_outlined,
          sections: [
            InformationSection(
              'Account and civic data',
              'Signed-in account data, complaints, applications and notifications are stored in the configured Supabase project. A private on-device cache supports reliable loading.',
            ),
            InformationSection(
              'Location and photos',
              'Location is requested only when you choose Use Current Location. Selected complaint photos and vendor documents are uploaded to private, access-controlled storage for signed-in accounts.',
            ),
            InformationSection(
              'Municipal integration status',
              'Supabase stores and synchronizes submissions, but this development project is not yet connected to an official municipal case-management system.',
            ),
          ],
        );
      case '/settings/help':
        screen = const InformationScreen(
          title: 'Help & Support',
          icon: Icons.help_outline,
          sections: [
            InformationSection(
              'Reporting a problem',
              'Choose a service, provide a clear description, confirm the problem location, and review the report before submitting.',
            ),
            InformationSection(
              'Device permissions',
              'If location or camera access is denied, select a location manually or choose an existing image.',
            ),
            InformationSection(
              'Development support',
              'This development build uses the configured Supabase backend. Municipal helpline and production support details will be configured before release.',
            ),
          ],
        );
      case '/settings/terms':
        screen = const InformationScreen(
          title: 'Terms & Conditions',
          icon: Icons.description_outlined,
          sections: [
            InformationSection(
              'Demonstration use',
              'This application demonstrates cloud-backed civic-service workflows. Supabase submissions are not yet official municipal complaints or applications.',
            ),
            InformationSection(
              'Accurate information',
              'Users should provide accurate, respectful information and avoid unsafe behavior when capturing photos or locations.',
            ),
            InformationSection(
              'Production review',
              'Final legal terms, retention rules and municipal service commitments require authorized review before public release.',
            ),
          ],
        );
      default:
        screen = _dynamicRoute(name, arguments);
    }

    return MaterialPageRoute<dynamic>(
      settings: settings,
      builder: (_) => screen,
    );
  }

  Widget _dynamicRoute(String name, Object? arguments) {
    if (name.startsWith('/services/')) {
      final type = _serviceTypeFromSlug(name.substring('/services/'.length));
      return type == null
          ? _UnknownRouteScreen(routeName: name)
          : ServiceDetailScreen(service: controller.serviceFor(type));
    }
    if (name.startsWith('/requests/')) {
      final id = name.substring('/requests/'.length);
      return RequestDetailScreen(controller: controller, requestId: id);
    }
    if (name.startsWith('/news/')) {
      final id = name.substring('/news/'.length);
      final item = arguments is NewsItem ? arguments : controller.newsById(id);
      return item == null
          ? _UnknownRouteScreen(routeName: name)
          : NewsDetailScreen(item: item, allItems: controller.news);
    }
    return _UnknownRouteScreen(routeName: name);
  }

  static void _push(String route, {Object? arguments}) {
    navigatorKey.currentState?.pushNamed(route, arguments: arguments);
  }

  static void _replace(String route) {
    navigatorKey.currentState?.pushReplacementNamed(route);
  }

  static void _replaceAll(String route) {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(route, (_) => false);
  }

  static void _pop() {
    navigatorKey.currentState?.maybePop();
  }

  ServiceType? _serviceTypeFromSlug(String slug) => switch (slug) {
    'vendor' => ServiceType.vendor,
    'waste' || 'garbage' => ServiceType.garbage,
    'water' => ServiceType.water,
    'roads' => ServiceType.roads,
    'animals' => ServiceType.animals,
    'drainage' => ServiceType.drainage,
    'streetlights' => ServiceType.streetlights,
    'public-spaces' => ServiceType.publicSpaces,
    'encroachment' => ServiceType.encroachment,
    'other' => ServiceType.other,
    _ => null,
  };
}

class _CurrentRouteTracker extends NavigatorObserver {
  String? currentRouteName;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    currentRouteName = route.settings.name;
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    currentRouteName = previousRoute?.settings.name;
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    currentRouteName = newRoute?.settings.name;
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (currentRouteName == route.settings.name) {
      currentRouteName = previousRoute?.settings.name;
    }
    super.didRemove(route, previousRoute);
  }
}

class _UnknownRouteScreen extends StatelessWidget {
  const _UnknownRouteScreen({required this.routeName});

  final String routeName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page unavailable')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off, size: 56),
              const SizedBox(height: 16),
              Text(
                'This page is not available.',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(routeName, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (_) => false,
                ),
                child: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
