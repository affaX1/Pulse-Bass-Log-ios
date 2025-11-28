import 'dart:ui';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../utils.dart';
import '../widgets/mood_selector.dart';

class EntryEditorScreen extends StatefulWidget {
  const EntryEditorScreen({super.key, this.existing});
  final Entry? existing;

  @override
  State<EntryEditorScreen> createState() => _EntryEditorScreenState();
}

class _EntryEditorScreenState extends State<EntryEditorScreen> {
  late int mood;
  late int energy;
  late int stress;
  double? sleepHours;
  int? sleepQuality;
  late DateTime loggedFor;
  late Set<String> activityIds;
  late TextEditingController noteController;
  late TextEditingController tagsController;
  late TextEditingController peopleController;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    mood = existing?.mood ?? 3;
    energy = existing?.energy ?? 3;
    stress = existing?.stress ?? 3;
    sleepHours = existing?.sleepHours;
    sleepQuality = existing?.sleepQuality;
    loggedFor = existing?.loggedFor ?? DateTime.now();
    activityIds = existing != null ? existing.activityIds.toSet() : {};
    noteController = TextEditingController(text: existing?.note ?? '');
    tagsController = TextEditingController(
      text: existing?.tags.join(', ') ?? '',
    );
    peopleController = TextEditingController(
      text: existing?.people.join(', ') ?? '',
    );
  }

  @override
  void dispose() {
    noteController.dispose();
    tagsController.dispose();
    peopleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.existing == null ? 'New entry' : 'Edit entry'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () async {
              final entry = Entry(
                id:
                    widget.existing?.id ??
                    DateTime.now().microsecondsSinceEpoch.toString(),
                createdAt: widget.existing?.createdAt ?? DateTime.now(),
                loggedFor: loggedFor,
                mood: mood,
                energy: energy,
                stress: stress,
                sleepHours: sleepHours,
                sleepQuality: sleepQuality,
                activityIds: activityIds.toList(),
                tags: _parseList(tagsController.text),
                people: _parseList(peopleController.text),
                note: noteController.text.isEmpty ? null : noteController.text,
              );
              await state.upsertEntry(entry);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
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
            16,
            MediaQuery.of(context).padding.top + kToolbarHeight + 24,
            16,
            24,
          ),
          children: [
            _GlassCard(
              child: MoodSelector(
                label: 'Mood',
                value: mood,
                onChanged: (v) => setState(() => mood = v),
              ),
            ),
            const SizedBox(height: 12),
            _GlassCard(
              child: MoodSelector(
                label: 'Energy',
                value: energy,
                onChanged: (v) => setState(() => energy = v),
              ),
            ),
            const SizedBox(height: 12),
            _GlassCard(
              child: MoodSelector(
                label: 'Stress',
                value: stress,
                onChanged: (v) => setState(() => stress = v),
              ),
            ),
            const SizedBox(height: 12),
            _GlassCard(
              child: _SleepRow(
                sleepHours: sleepHours,
                sleepQuality: sleepQuality,
                onHoursChanged: (v) => setState(() => sleepHours = v),
                onQualityChanged: (v) => setState(() => sleepQuality = v),
              ),
            ),
            const SizedBox(height: 12),
            _GlassCard(
              child: _DateRow(
                loggedFor: loggedFor,
                onPick: (date) => setState(() => loggedFor = date),
              ),
            ),
            const SizedBox(height: 12),
            _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Activities',
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: state.activities.where((a) => !a.isArchived).map((
                      activity,
                    ) {
                      final isSelected = activityIds.contains(activity.id);
                      return ChoiceChip(
                        label: Text(
                          activity.name,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withOpacity(0.8),
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            if (isSelected) {
                              activityIds.remove(activity.id);
                            } else {
                              activityIds.add(activity.id);
                            }
                          });
                        },
                        selectedColor: Colors.white.withOpacity(0.18),
                        backgroundColor: Colors.white.withOpacity(0.08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.12),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _GlassCard(
              child: _TextFieldRow(
                controller: peopleController,
                label: 'People/contacts (comma separated)',
              ),
            ),
            const SizedBox(height: 12),
            _GlassCard(
              child: _TextFieldRow(
                controller: tagsController,
                label: 'Tags/events (comma separated)',
              ),
            ),
            const SizedBox(height: 12),
            _GlassCard(
              child: _TextFieldRow(
                controller: noteController,
                label: 'Note',
                minLines: 3,
                maxLines: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _parseList(String text) {
    return text
        .split(',')
        .map((e) => e.trim())
        .where((element) => element.isNotEmpty)
        .toList();
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
          child: child,
        ),
      ),
    );
  }
}

class _SleepRow extends StatelessWidget {
  const _SleepRow({
    required this.sleepHours,
    required this.sleepQuality,
    required this.onHoursChanged,
    required this.onQualityChanged,
  });
  final double? sleepHours;
  final int? sleepQuality;
  final ValueChanged<double?> onHoursChanged;
  final ValueChanged<int?> onQualityChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Sleep hours',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.white),
            ),
            Text(
              sleepHours != null
                  ? '${sleepHours!.toStringAsFixed(1)}h'
                  : 'Not set',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {
                final next = (sleepHours ?? 0) - 0.5;
                onHoursChanged(next < 0 ? 0 : next);
              },
              icon: const Icon(
                Icons.remove_circle_outline,
                color: Colors.white70,
              ),
            ),
            IconButton(
              onPressed: () {
                onHoursChanged((sleepHours ?? 0) + 0.5);
              },
              icon: const Icon(Icons.add_circle_outline, color: Colors.white70),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Sleep quality',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: List.generate(
            5,
            (index) =>
                ButtonSegment(value: index + 1, label: Text('${index + 1}')),
          ),
          multiSelectionEnabled: false,
          emptySelectionAllowed: true,
          selected: sleepQuality != null ? {sleepQuality!} : {},
          onSelectionChanged: (value) =>
              onQualityChanged(value.isEmpty ? null : value.first),
        ),
      ],
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.loggedFor, required this.onPick});
  final DateTime loggedFor;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    final use24h = AppStateProvider.of(context).settings.timeFormat == '24h';
    return ListTile(
      leading: const Icon(Icons.calendar_today, color: Colors.white70),
      title: const Text('Logged date/time'),
      subtitle: Text(
        '${formatDate(loggedFor)} · ${formatTime(loggedFor, use24h: use24h)}',
      ),
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: loggedFor,
          firstDate: DateTime(loggedFor.year - 1),
          lastDate: DateTime(loggedFor.year + 1),
        );
        if (pickedDate != null) {
          final pickedTime = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(loggedFor),
          );
          if (pickedTime != null) {
            onPick(
              DateTime(
                pickedDate.year,
                pickedDate.month,
                pickedDate.day,
                pickedTime.hour,
                pickedTime.minute,
              ),
            );
          }
        }
      },
    );
  }
}

class _TextFieldRow extends StatelessWidget {
  const _TextFieldRow({
    required this.controller,
    required this.label,
    this.minLines = 1,
    this.maxLines = 1,
  });
  final TextEditingController controller;
  final String label;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.18)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
      ),
    );
  }
}
