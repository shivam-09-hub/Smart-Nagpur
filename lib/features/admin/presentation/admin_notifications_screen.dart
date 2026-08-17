import 'package:flutter/material.dart';
import 'package:smart_nagpur/core/theme/theme.dart';
import 'package:smart_nagpur/domain/domain.dart';
import 'package:smart_nagpur/state/admin_controller.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({required this.controller, super.key});

  final AdminController controller;

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  NotificationCategory _selectedCategory = NotificationCategory.important;
  String _notificationType = 'broadcast'; // 'broadcast' or 'individual'
  late final TextEditingController _userIdController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _bodyController = TextEditingController();
    _userIdController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _userIdController.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final success = _notificationType == 'broadcast'
        ? await widget.controller.sendBroadcastNotification(
            _titleController.text,
            _bodyController.text,
            _selectedCategory,
          )
        : await widget.controller.sendNotificationToUser(
            _userIdController.text,
            _titleController.text,
            _bodyController.text,
            _selectedCategory,
          );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification sent successfully')),
      );
      _titleController.clear();
      _bodyController.clear();
      _userIdController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.controller.error ?? 'Failed to send notification',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Notifications')),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Notification type
                Text(
                  'Notification Type',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                RadioGroup<String>(
                  groupValue: _notificationType,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _notificationType = value);
                    }
                  },
                  child: const Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: Text('Broadcast'),
                          value: 'broadcast',
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: Text('Individual'),
                          value: 'individual',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // User ID (if individual)
                if (_notificationType == 'individual') ...[
                  Text(
                    'User ID',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _userIdController,
                    decoration: InputDecoration(
                      hintText: 'Enter user ID',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Title
                Text('Title', style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 8),
                TextField(
                  controller: _titleController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Enter notification title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Body
                Text('Message', style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 8),
                TextField(
                  controller: _bodyController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Enter notification message',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Category
                Text('Category', style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 8),
                DropdownButtonFormField<NotificationCategory>(
                  initialValue: _selectedCategory,
                  items: NotificationCategory.values
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category.name),
                        ),
                      )
                      .toList(),
                  onChanged: (category) {
                    if (category != null) {
                      setState(() => _selectedCategory = category);
                    }
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Send button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: widget.controller.isLoading
                        ? null
                        : _sendNotification,
                    icon: const Icon(Icons.send),
                    label: widget.controller.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Send Notification'),
                  ),
                ),

                // History section
                const SizedBox(height: 40),
                Text(
                  'Notification History',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (widget.controller.adminNotifications.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        'No notifications sent yet',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.controller.adminNotifications.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final notification =
                          widget.controller.adminNotifications[index];
                      return Card(
                        child: ListTile(
                          title: Text(notification.title),
                          subtitle: Text(notification.body),
                          trailing: Text(
                            notification.category.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
