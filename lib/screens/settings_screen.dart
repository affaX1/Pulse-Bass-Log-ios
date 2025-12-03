import 'dart:ui';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../widgets/activities_manager.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0a1f7a), Color(0xFF1657e6), Color(0xFF1f8bff)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            12,
            MediaQuery.of(context).padding.top + kToolbarHeight + 12,
            12,
            24,
          ),
          children: [
            _GlassCard(
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: '24h', label: Text('24h')),
                  ButtonSegment(value: '12h', label: Text('12h')),
                ],
                selected: {state.settings.timeFormat},
                onSelectionChanged: (v) async => await state.updateSettings(
                  (s) => s.copyWith(timeFormat: v.first),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _GlassCard(
              child: Column(
                children: [
                  _ReminderRow(
                    label: 'Morning',
                    time: state.settings.reminderMorning,
                    onPick: (time) async => await state.updateSettings(
                      (s) => s.copyWith(reminderMorning: time),
                    ),
                  ),
                  _ReminderRow(
                    label: 'Midday',
                    time: state.settings.reminderMidday,
                    onPick: (time) async => await state.updateSettings(
                      (s) => s.copyWith(reminderMidday: time),
                    ),
                  ),
                  _ReminderRow(
                    label: 'Evening',
                    time: state.settings.reminderEvening,
                    onPick: (time) async => await state.updateSettings(
                      (s) => s.copyWith(reminderEvening: time),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 16),
            _GlassCard(child: const ActivitiesManager()),
            const SizedBox(height: 12),
            _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Danger zone',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Remove all stored entries, activities, and settings.',
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () => _confirmRemoveAll(context, state),
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Remove all data'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStub(BuildContext context, String action) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$action is a stub for now.')));
  }

  Future<void> _confirmRemoveAll(
    BuildContext context,
    AppState state,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove all data?'),
        content: const Text(
          'This will delete all entries, activities, and settings from the device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await state.removeAllData();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All data has been removed.')),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white.withOpacity(0.06),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: DefaultTextStyle.merge(
            style: const TextStyle(color: Colors.white),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({
    required this.label,
    required this.time,
    required this.onPick,
  });
  final String label;
  final TimeOfDay? time;
  final ValueChanged<TimeOfDay?> onPick;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.alarm),
      title: Text('Reminder: $label'),
      subtitle: Text(time != null ? time!.format(context) : 'Off'),
      trailing: Switch(
        value: time != null,
        onChanged: (value) async {
          if (!value) {
            onPick(null);
            return;
          }
          final picked = await showTimePicker(
            context: context,
            initialTime: time ?? const TimeOfDay(hour: 9, minute: 0),
          );
          onPick(picked);
        },
      ),
    );
  }
}
