import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_nagpur/core/theme/theme.dart';
import 'package:smart_nagpur/core/widgets/states.dart';
import 'package:smart_nagpur/domain/domain.dart';
import 'package:smart_nagpur/state/app_controller.dart';

enum RequestFilter { all, active, resolved }

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({required this.controller, super.key});

  final AppController controller;

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  RequestFilter _filter = RequestFilter.all;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final complaints = switch (_filter) {
          RequestFilter.all => widget.controller.complaints.toList(),
          RequestFilter.active => widget.controller.activeComplaints,
          RequestFilter.resolved => widget.controller.resolvedComplaints,
        }..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('My Requests'),
                Text(
                  widget.controller.isDemoMode
                      ? 'Saved locally in demo mode'
                      : widget.controller.isOffline
                      ? 'Showing saved data while offline'
                      : 'Synced securely with Supabase',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                  child: SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<RequestFilter>(
                      segments: const [
                        ButtonSegment(
                          value: RequestFilter.all,
                          label: Text('All'),
                        ),
                        ButtonSegment(
                          value: RequestFilter.active,
                          label: Text('Active'),
                        ),
                        ButtonSegment(
                          value: RequestFilter.resolved,
                          label: Text('Resolved'),
                        ),
                      ],
                      selected: {_filter},
                      showSelectedIcon: false,
                      onSelectionChanged: (selection) =>
                          setState(() => _filter = selection.first),
                    ),
                  ),
                ),
                Expanded(
                  child: complaints.isEmpty
                      ? EmptyState(
                          icon: Icons.assignment_outlined,
                          title: 'No ${_filter.name} requests',
                          message: _filter == RequestFilter.all
                              ? 'Reports you submit will appear here.'
                              : 'Try another tab or report a civic problem.',
                          actionLabel: 'Report a Problem',
                          onAction: () => Navigator.pushNamed(
                            context,
                            '/complaints/create',
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: widget.controller.refreshCloudData,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                            itemCount: complaints.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) =>
                                _RequestCard(record: complaints[index]),
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.record});

  final ComplaintRecord record;

  @override
  Widget build(BuildContext context) {
    final accent = record.serviceType.color;
    return Semantics(
      button: true,
      label:
          '${record.issue}, ${record.serviceType.title}, status ${record.status.label}',
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: () => Navigator.pushNamed(
            context,
            '/requests/${record.id}',
            arguments: record.id,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: record.serviceType.softColor,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(record.serviceType.icon, color: accent),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              record.issue,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(record.serviceType.title),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 17,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              record.location.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _RequestStatus(status: record.status),
                          const Spacer(),
                          Text(
                            DateFormat('d MMM yyyy').format(record.createdAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RequestStatus extends StatelessWidget {
  const _RequestStatus({required this.status});

  final ComplaintStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ComplaintStatus.resolved => AppColors.success,
      ComplaintStatus.rejected => AppColors.error,
      ComplaintStatus.moreInformationRequired => AppColors.warning,
      _ => AppColors.info,
    };
    final icon = switch (status) {
      ComplaintStatus.resolved => Icons.check_circle_outline,
      ComplaintStatus.rejected => Icons.cancel_outlined,
      ComplaintStatus.moreInformationRequired => Icons.info_outline,
      _ => Icons.schedule,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
