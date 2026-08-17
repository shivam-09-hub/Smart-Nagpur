import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_nagpur/core/theme/theme.dart';
import 'package:smart_nagpur/core/widgets/states.dart';
import 'package:smart_nagpur/domain/domain.dart';
import 'package:smart_nagpur/features/complaints/presentation/widgets/development_map.dart';
import 'package:smart_nagpur/state/app_controller.dart';

class RequestDetailScreen extends StatelessWidget {
  const RequestDetailScreen({
    required this.controller,
    required this.requestId,
    super.key,
  });

  final AppController controller;
  final String requestId;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final record = controller.complaintById(requestId);
        if (record == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Request Details')),
            body: EmptyState(
              icon: Icons.search_off,
              title: 'Request not found',
              message: 'This request is no longer available for this account.',
              actionLabel: 'View My Requests',
              onAction: () =>
                  Navigator.pushReplacementNamed(context, '/requests'),
            ),
          );
        }
        return _RequestDetail(record: record);
      },
    );
  }
}

class _RequestDetail extends StatelessWidget {
  const _RequestDetail({required this.record});

  final ComplaintRecord record;

  @override
  Widget build(BuildContext context) {
    final color = record.serviceType.color;
    return Scaffold(
      appBar: AppBar(title: const Text('Request Details')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: record.serviceType.softColor,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(record.serviceType.icon, color: color),
                      const SizedBox(width: 10),
                      Text(
                        record.serviceType.title,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    record.issue,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    record.id,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 14),
                  _StatusPill(status: record.status),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _ProcessingNotice(isDemo: record.isDemo),
            const SizedBox(height: 16),
            _InfoCard(
              title: 'Report information',
              children: [
                _InfoRow(label: 'Description', value: record.description),
                _InfoRow(
                  label: 'Submitted',
                  value: DateFormat(
                    'd MMM yyyy, h:mm a',
                  ).format(record.createdAt),
                ),
                _InfoRow(label: 'Contact', value: '+91 ${record.contactPhone}'),
                ...record.extraFields.entries.map(
                  (entry) => _InfoRow(label: entry.key, value: entry.value),
                ),
              ],
            ),
            if (record.photoPaths.isNotEmpty) ...[
              const SizedBox(height: 16),
              _InfoCard(
                title: 'Photos',
                children: [
                  SizedBox(
                    height: 180,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: record.photoPaths.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) => ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          File(record.photoPaths[index]),
                          width: 220,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 220,
                            color: Theme.of(context).colorScheme.errorContainer,
                            alignment: Alignment.center,
                            child: const Text('Photo unavailable'),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            _InfoCard(
              title: 'Problem location',
              children: [
                IgnorePointer(
                  child: DevelopmentMap(
                    location: record.location,
                    onChanged: (_) {},
                  ),
                ),
                const SizedBox(height: 12),
                _InfoRow(label: 'Address', value: record.location.address),
                _InfoRow(
                  label: 'Coordinates',
                  value: record.location.coordinates,
                ),
                _InfoRow(
                  label: 'Accuracy',
                  value: '±${record.location.accuracy.toStringAsFixed(0)} m',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoCard(
              title: 'Status timeline',
              children: [
                ..._timelineEntries(record).indexed.map(
                  (entry) => _TimelineItem(
                    title: entry.$2.$1,
                    complete: entry.$2.$2,
                    current: entry.$2.$3,
                    timestamp: entry.$1 == 0 ? record.createdAt : null,
                    isLast: entry.$1 == _timelineEntries(record).length - 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoCard(
              title: 'Latest update',
              children: [
                Text(
                  record.timeline.isEmpty
                      ? 'No updates yet.'
                      : record.timeline.last.message ??
                            record.timeline.last.title,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<(String, bool, bool)> _timelineEntries(ComplaintRecord record) {
    const labels = [
      'Submitted',
      'Under Review',
      'Assigned',
      'In Progress',
      'Resolved',
    ];
    final currentIndex = switch (record.status) {
      ComplaintStatus.submitted => 0,
      ComplaintStatus.underReview ||
      ComplaintStatus.moreInformationRequired => 1,
      ComplaintStatus.assigned => 2,
      ComplaintStatus.inProgress => 3,
      ComplaintStatus.resolved => 4,
      ComplaintStatus.rejected => 1,
    };
    return [
      for (var index = 0; index < labels.length; index++)
        (labels[index], index <= currentIndex, index == currentIndex),
    ];
  }
}

class _ProcessingNotice extends StatelessWidget {
  const _ProcessingNotice({required this.isDemo});

  final bool isDemo;

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
          Icon(
            isDemo ? Icons.science_outlined : Icons.cloud_outlined,
            color: AppColors.info,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isDemo
                  ? 'Demo status: these updates are local examples and do not represent municipal processing.'
                  : 'This request is stored in your private cloud account. Smart Nagpur is not connected to a municipal case-management system, so its status is not official municipal processing.',
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 3),
          Text(value),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final ComplaintStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status == ComplaintStatus.resolved
        ? AppColors.success
        : status == ComplaintStatus.rejected
        ? AppColors.error
        : AppColors.info;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          status.label,
          style: TextStyle(color: color, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.title,
    required this.complete,
    required this.current,
    required this.isLast,
    this.timestamp,
  });

  final String title;
  final bool complete;
  final bool current;
  final bool isLast;
  final DateTime? timestamp;

  @override
  Widget build(BuildContext context) {
    final color = complete ? AppColors.primary : AppColors.border;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: complete ? color : AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: complete
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : null,
                ),
                if (!isLast) Expanded(child: Container(width: 2, color: color)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: current ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                  if (timestamp != null)
                    Text(
                      DateFormat('d MMM yyyy, h:mm a').format(timestamp!),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
