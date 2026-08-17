import 'package:flutter/material.dart';
import 'package:smart_nagpur/core/theme/theme.dart';
import 'package:smart_nagpur/core/widgets/states.dart';
import 'package:smart_nagpur/domain/domain.dart';
import 'package:smart_nagpur/state/app_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final profile = controller.profile;
        if (profile == null) {
          return const Scaffold(
            body: EmptyState(
              icon: Icons.person_off_outlined,
              title: 'Profile unavailable',
              message: 'Sign in again to restore your profile and civic data.',
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            actions: [
              IconButton(
                tooltip: 'Edit profile',
                onPressed: () => Navigator.pushNamed(context, '/profile/edit'),
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              children: [
                _ProfileHeader(profile: profile),
                const SizedBox(height: 20),
                _DataModeCard(
                  isDemo: controller.isDemoMode,
                  isOffline: controller.isOffline,
                ),
                const SizedBox(height: 24),
                _SettingsGroup(
                  title: 'Your activity',
                  items: [
                    _SettingsItem(
                      icon: Icons.assignment_outlined,
                      title: 'My Requests',
                      subtitle: '${controller.complaints.length} reports',
                      route: '/requests',
                    ),
                    _SettingsItem(
                      icon: Icons.storefront_outlined,
                      title: 'My Vendor Applications',
                      subtitle:
                          '${controller.vendorApplications.length} applications',
                      route: '/vendor/application',
                    ),
                    const _SettingsItem(
                      icon: Icons.folder_copy_outlined,
                      title: 'My Documents',
                      route: '/vendor/documents',
                    ),
                    const _SettingsItem(
                      icon: Icons.bookmark_border,
                      title: 'Saved Locations',
                      route: '/profile/saved-locations',
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const _SettingsGroup(
                  title: 'Preferences',
                  items: [
                    _SettingsItem(
                      icon: Icons.notifications_outlined,
                      title: 'Notification Settings',
                      route: '/settings/notifications',
                    ),
                    _SettingsItem(
                      icon: Icons.language,
                      title: 'Language',
                      route: '/settings/language',
                    ),
                    _SettingsItem(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy',
                      route: '/settings/privacy',
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const _SettingsGroup(
                  title: 'Support and legal',
                  items: [
                    _SettingsItem(
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      route: '/settings/help',
                    ),
                    _SettingsItem(
                      icon: Icons.description_outlined,
                      title: 'Terms & Conditions',
                      route: '/settings/terms',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () => _confirmLogout(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: Text(
          controller.isDemoMode
              ? 'This ends the current demo session.'
              : 'Your Supabase account and cloud records will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (shouldLogout != true) return;
    await controller.logout();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.raised,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            child: Text(
              profile.initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 5),
                Text(
                  '+91 ${profile.phone}',
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  profile.email,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.86)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DataModeCard extends StatelessWidget {
  const _DataModeCard({required this.isDemo, required this.isOffline});

  final bool isDemo;
  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.infoSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(
            isDemo
                ? Icons.science_outlined
                : isOffline
                ? Icons.cloud_off_outlined
                : Icons.cloud_done_outlined,
            color: AppColors.info,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isDemo
                  ? 'Demo mode · sample records stay on this device'
                  : isOffline
                  ? 'Offline · showing the most recently saved cloud data'
                  : 'Connected securely to Supabase',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.items});

  final String title;
  final List<_SettingsItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 9),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                items[index],
                if (index != items.length - 1)
                  const Divider(height: 1, indent: 58),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.route,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String route;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.pushNamed(context, route),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({required this.controller, super.key});

  final AppController controller;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _address;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile =
        widget.controller.profile ??
        const UserProfile(name: '', phone: '', email: '');
    _name = TextEditingController(text: profile.name);
    _phone = TextEditingController(text: profile.phone);
    _email = TextEditingController(text: profile.email);
    _address = TextEditingController(text: profile.address);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => value == null || value.trim().length < 2
                    ? 'Enter your full name.'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  prefixText: '+91 ',
                ),
                validator: (value) =>
                    value == null || !RegExp(r'^\d{10}$').hasMatch(value.trim())
                    ? 'Enter a valid 10-digit number.'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _email,
                enabled:
                    !widget.controller.usesCloudBackend ||
                    widget.controller.isDemoMode,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  helperText:
                      widget.controller.usesCloudBackend &&
                          !widget.controller.isDemoMode
                      ? 'Your verified sign-in email cannot be changed here.'
                      : null,
                ),
                validator: (value) => value == null || !value.contains('@')
                    ? 'Enter a valid email.'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _address,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Home address',
                  helperText: 'This is not used as a problem location.',
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.controller.updateProfile(
        UserProfile(
          name: _name.text.trim(),
          phone: _phone.text.trim(),
          email: _email.text.trim(),
          address: _address.text.trim(),
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile could not be saved. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
