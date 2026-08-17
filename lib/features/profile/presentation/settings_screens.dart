import 'package:flutter/material.dart';
import 'package:smart_nagpur/core/theme/theme.dart';
import 'package:smart_nagpur/state/app_controller.dart';

class SavedLocationsScreen extends StatelessWidget {
  const SavedLocationsScreen({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final address = controller.profile?.address.trim() ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Locations')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (address.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.bookmark_border, size: 44),
                    const SizedBox(height: 10),
                    const Text('No home address saved'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/profile/edit'),
                      child: const Text('Add in Profile'),
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.home_outlined)),
                title: const Text('Home'),
                subtitle: Text(address),
                trailing: IconButton(
                  tooltip: 'Edit home address',
                  onPressed: () =>
                      Navigator.pushNamed(context, '/profile/edit'),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ),
            ),
          const SizedBox(height: 16),
          const Text(
            'Saved personal locations never replace the location selected for a civic report.',
          ),
        ],
      ),
    );
  }
}

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _important = true;
  bool _requests = true;
  bool _updates = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _DemoSettingsNotice(),
          const SizedBox(height: 14),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Important alerts'),
                  subtitle: const Text('Urgent demo civic notices'),
                  value: _important,
                  onChanged: (value) => setState(() => _important = value),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Request updates'),
                  subtitle: const Text('Complaint and vendor activity'),
                  value: _requests,
                  onChanged: (value) => setState(() => _requests = value),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('City updates'),
                  subtitle: const Text('News and announcements'),
                  value: _updates,
                  onChanged: (value) => setState(() => _updates = value),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('Language')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ListTile(
              leading: Icon(
                controller.locale.languageCode == 'en'
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              title: const Text('English'),
              subtitle: const Text('Primary MVP language'),
              onTap: () => controller.changeLocale(const Locale('en')),
            ),
            ListTile(
              leading: Icon(
                controller.locale.languageCode == 'mr'
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              title: const Text('मराठी'),
              subtitle: const Text('Localization structure preview'),
              onTap: () => controller.changeLocale(const Locale('mr')),
            ),
            const SizedBox(height: 14),
            const _DemoSettingsNotice(
              text:
                  'English is complete for the MVP. Marathi structure and core navigation translations are prepared; remaining content is marked for translation review.',
            ),
          ],
        ),
      ),
    );
  }
}

class InformationScreen extends StatelessWidget {
  const InformationScreen({
    required this.title,
    required this.icon,
    required this.sections,
    super.key,
  });

  final String title;
  final IconData icon;
  final List<InformationSection> sections;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 32, color: AppColors.primary),
          ),
          const SizedBox(height: 22),
          for (final section in sections) ...[
            Text(section.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 7),
            Text(section.body),
            const SizedBox(height: 22),
          ],
        ],
      ),
    );
  }
}

class InformationSection {
  const InformationSection(this.title, this.body);

  final String title;
  final String body;
}

class _DemoSettingsNotice extends StatelessWidget {
  const _DemoSettingsNotice({
    this.text =
        'These preferences control the in-app demo only. OS push notifications are not enabled.',
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.infoSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.info),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
