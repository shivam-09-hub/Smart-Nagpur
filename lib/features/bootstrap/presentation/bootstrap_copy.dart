/// English source copy for the app entry experience.
///
/// Keeping this copy outside widgets makes the screens straightforward to
/// migrate to generated ARB localizations when Marathi translations land.
abstract final class BootstrapCopy {
  static const appName = 'NGP Seva';
  static const appNameMarathi = 'एनजीपी सेवा';
  static const cityServices = 'One city. Connected services.';
  static const skip = 'Skip';
  static const next = 'Next';
  static const getStarted = 'Get Started';
  static const pageAnnouncement = 'Onboarding page';

  static const onboardingItems = <OnboardingCopy>[
    OnboardingCopy(
      title: 'Everything your city needs, in one place.',
      description:
          'Explore civic services, useful city information and important updates from one simple app.',
    ),
    OnboardingCopy(
      title: 'Report problems with your location and photos.',
      description:
          'Help explain an issue clearly by adding a photo and confirming its exact location.',
    ),
    OnboardingCopy(
      title: 'Track what happens next.',
      description:
          'Keep your request number handy and follow every update from submission to resolution.',
    ),
  ];
}

class OnboardingCopy {
  const OnboardingCopy({required this.title, required this.description});

  final String title;
  final String description;
}
