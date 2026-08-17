import 'dart:async';

import 'package:flutter/material.dart';
import 'package:smart_nagpur/state/app_controller.dart';

import '../widgets/smart_nagpur_brand.dart';

/// Resolves persisted app state and forwards the user to the correct entry
/// route. Navigation remains callback-driven so this screen does not own a
/// particular routing package.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.controller,
    required this.onOnboarding,
    required this.onLogin,
    required this.onHome,
    required this.onPasswordRecovery,
    this.minimumDisplayTime = const Duration(milliseconds: 1200),
  });

  final AppController controller;
  final VoidCallback onOnboarding;
  final VoidCallback onLogin;
  final VoidCallback onHome;
  final VoidCallback onPasswordRecovery;
  final Duration minimumDisplayTime;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  String? _errorMessage;
  bool _hasRouted = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _scale = Tween<double>(begin: .94, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_resolveDestination());
    });
  }

  Future<void> _resolveDestination() async {
    if (_hasRouted) return;
    if (mounted) setState(() => _errorMessage = null);

    try {
      await Future.wait<void>([
        widget.controller.initialize(),
        Future<void>.delayed(widget.minimumDisplayTime),
      ]);
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'We could not prepare the app. Check your device storage and try again.';
        });
      }
      return;
    }

    if (!mounted || _hasRouted) return;
    // An unavailable remote gateway is a successful offline initialization
    // when a matching signed-in user's cache has already been restored.
    // Repository/configuration failures leave the controller uninitialized and
    // must continue to block routing.
    if (!widget.controller.isInitialized) {
      setState(
        () => _errorMessage =
            widget.controller.error ??
            'We could not prepare the app. Please try again.',
      );
      return;
    }

    _hasRouted = true;
    if (!widget.controller.hasCompletedOnboarding) {
      widget.onOnboarding();
    } else if (widget.controller.isPasswordRecovery) {
      widget.onPasswordRecovery();
    } else if (!widget.controller.isAuthenticated) {
      widget.onLogin();
    } else {
      widget.onHome();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [scheme.primary, scheme.primary.withValues(alpha: .84)],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(child: _CityPattern()),
            SafeArea(
              minimum: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  FadeTransition(
                    opacity: _fade,
                    child: ScaleTransition(
                      scale: _scale,
                      child: const SmartNagpurBrand(light: true),
                    ),
                  ),
                  const Spacer(flex: 3),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _errorMessage == null
                        ? Column(
                            key: const ValueKey('loading'),
                            children: [
                              const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.4,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Connecting you to Nagpur',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: .84),
                                ),
                              ),
                            ],
                          )
                        : _SplashError(
                            key: const ValueKey('error'),
                            message: _errorMessage!,
                            onRetry: _resolveDestination,
                          ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashError extends StatelessWidget {
  const _SplashError({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .13),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: .25)),
        ),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_rounded, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onRetry,
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CityPattern extends StatelessWidget {
  const _CityPattern();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(child: CustomPaint(painter: _CityPatternPainter()));
  }
}

class _CityPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: .065);
    final horizon = size.height * .78;
    const buildingWidth = 44.0;
    for (var i = 0; i < (size.width / buildingWidth).ceil() + 1; i++) {
      final height = 45.0 + ((i * 31) % 92);
      final left = i * buildingWidth - 8;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, horizon - height, buildingWidth - 5, height),
          const Radius.circular(4),
        ),
        paint,
      );
    }
    canvas.drawCircle(
      Offset(size.width * .82, size.height * .16),
      size.shortestSide * .24,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
