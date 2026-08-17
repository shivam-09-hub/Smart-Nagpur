import 'package:flutter/material.dart';
import 'package:smart_nagpur/state/app_controller.dart';

import '../bootstrap_copy.dart';
import '../widgets/smart_nagpur_brand.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.controller,
    required this.onCompleted,
  });

  final AppController controller;
  final VoidCallback onCompleted;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _page = 0;
  bool _isCompleting = false;
  String? _errorMessage;

  bool get _isLast => _page == BootstrapCopy.onboardingItems.length - 1;

  Future<void> _finish() async {
    if (_isCompleting) return;
    setState(() {
      _isCompleting = true;
      _errorMessage = null;
    });
    try {
      await widget.controller.completeOnboarding();
      if (mounted) widget.onCompleted();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isCompleting = false;
        _errorMessage = 'Your preference could not be saved. Please try again.';
      });
    }
  }

  Future<void> _next() async {
    if (_isLast) {
      await _finish();
      return;
    }
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 6),
              child: Row(
                children: [
                  const Expanded(
                    child: SmartNagpurBrand(compact: true, showTagline: false),
                  ),
                  TextButton(
                    onPressed: _isCompleting ? null : _finish,
                    child: const Text(BootstrapCopy.skip),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: BootstrapCopy.onboardingItems.length,
                onPageChanged: (value) => setState(() => _page = value),
                itemBuilder: (context, index) => _OnboardingPage(
                  index: index,
                  copy: BootstrapCopy.onboardingItems[index],
                ),
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: Semantics(
                  liveRegion: true,
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: scheme.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Row(
                children: [
                  Semantics(
                    label:
                        '${BootstrapCopy.pageAnnouncement} ${_page + 1} of ${BootstrapCopy.onboardingItems.length}',
                    child: Row(
                      children: List.generate(
                        BootstrapCopy.onboardingItems.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: index == _page ? 24 : 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 7),
                          decoration: BoxDecoration(
                            color: index == _page
                                ? scheme.primary
                                : scheme.outlineVariant,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _isCompleting ? null : _next,
                    iconAlignment: IconAlignment.end,
                    icon: _isCompleting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _isLast
                                ? Icons.check_rounded
                                : Icons.arrow_forward_rounded,
                          ),
                    label: Text(
                      _isLast ? BootstrapCopy.getStarted : BootstrapCopy.next,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.index, required this.copy});

  final int index;
  final OnboardingCopy copy;

  static const _icons = <IconData>[
    Icons.apps_rounded,
    Icons.add_a_photo_rounded,
    Icons.route_rounded,
  ];

  static const _supportingIcons = <List<IconData>>[
    [
      Icons.water_drop_rounded,
      Icons.lightbulb_rounded,
      Icons.storefront_rounded,
    ],
    [
      Icons.my_location_rounded,
      Icons.photo_camera_rounded,
      Icons.task_alt_rounded,
    ],
    [
      Icons.receipt_long_rounded,
      Icons.notifications_rounded,
      Icons.check_circle_rounded,
    ],
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      namesRoute: true,
      label: '${copy.title} ${copy.description}',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final illustrationHeight = (constraints.maxHeight * .46).clamp(
            210.0,
            350.0,
          );
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  children: [
                    SizedBox(
                      height: illustrationHeight,
                      child: _FeatureIllustration(
                        primaryIcon: _icons[index],
                        supportingIcons: _supportingIcons[index],
                      ),
                    ),
                    const SizedBox(height: 26),
                    Text(
                      copy.title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.18,
                        letterSpacing: -.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      copy.description,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FeatureIllustration extends StatelessWidget {
  const _FeatureIllustration({
    required this.primaryIcon,
    required this.supportingIcons,
  });

  final IconData primaryIcon;
  final List<IconData> supportingIcons;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: .64),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 154,
          height: 154,
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(42),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: .1),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Icon(primaryIcon, size: 76, color: scheme.primary),
        ),
        for (var i = 0; i < supportingIcons.length; i++)
          Align(
            alignment: switch (i) {
              0 => const Alignment(-.82, -.66),
              1 => const Alignment(.9, -.12),
              _ => const Alignment(-.55, .84),
            },
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Icon(
                supportingIcons[i],
                color: scheme.secondary,
                size: 27,
              ),
            ),
          ),
      ],
    );
  }
}
