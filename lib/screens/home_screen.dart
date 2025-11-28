import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../utils.dart';
import '../widgets/entry_card.dart';
import '../widgets/metric_card.dart';
import 'entry_editor_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final today = DateTime.now();
    final todayEntries = state.entries
        .where(
          (e) =>
              e.loggedFor.year == today.year &&
              e.loggedFor.month == today.month &&
              e.loggedFor.day == today.day,
        )
        .toList();
    final averageMood = todayEntries.isEmpty
        ? null
        : todayEntries.map((e) => e.mood).fold<int>(0, (sum, m) => sum + m) /
              todayEntries.length;

    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0a1f7a), Color(0xFF1657e6), Color(0xFF1f8bff)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              title: const Text('Pulse Blass Log'),
              centerTitle: false,
              floating: true,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.add_chart),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const EntryEditorScreen(),
                    ),
                  ),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.14),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _HeroCard(
                              dateLabel: 'Today, ${formatDate(today)}',
                              averageMood: averageMood,
                              onAdd: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const EntryEditorScreen(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                    _QuickLogRow(
                      onPick: (mood) async {
                        await state.quickLog(mood);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Quick log added.'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                            const SizedBox(height: 16),
                            _SummaryCards(entries: todayEntries),
                            const SizedBox(height: 20),
                            Text(
                              'Recent entries',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            ...state.entries
                                .take(4)
                                .map((entry) => EntryCard(entry: entry)),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.dateLabel,
    required this.averageMood,
    required this.onAdd,
  });
  final String dateLabel;
  final double? averageMood;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1f4fff), Color(0xFF5bb5ff)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: scheme.onPrimary),
                ),
                const SizedBox(height: 6),
                if (averageMood != null)
                  Text(
                    'Avg mood: ${averageMood!.toStringAsFixed(1)}',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: scheme.onPrimary),
                  )
                else
                  Text(
                    'No entries yet',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: scheme.onPrimary),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Tap + to add a detailed entry',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onPrimary.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          FilledButton.tonalIcon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add'),
            style: FilledButton.styleFrom(
              foregroundColor: scheme.onPrimary,
              backgroundColor: scheme.primary.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickLogRow extends StatelessWidget {
  const _QuickLogRow({required this.onPick});
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF1f4fff), Color(0xFF5bb5ff)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quick log',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'One tap entry',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (idx) {
                final mood = idx + 1;
                return _MoodChip(mood: mood, onTap: () => onPick(mood));
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodChip extends StatelessWidget {
  const _MoodChip({required this.mood, required this.onTap});
  final int mood;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: moodColor(mood).withOpacity(0.14),
              shape: BoxShape.circle,
              border: Border.all(color: moodColor(mood).withOpacity(0.4)),
            ),
            child: Text(
              moodEmojis[mood - 1],
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(height: 4),
          Text('$mood', style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.entries});
  final List<Entry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Add an entry to see today’s summary.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    double avg(List<int> items) =>
        items.reduce((a, b) => a + b) / max(1, items.length);

    final mood = avg(entries.map((e) => e.mood).toList());
    final energy = avg(entries.map((e) => e.energy).toList());
    final stress = avg(entries.map((e) => e.stress).toList());
    final hours = entries
        .where((e) => e.sleepHours != null)
        .map((e) => e.sleepHours!)
        .toList();

    return Row(
      children: [
        Expanded(
          child: MetricCard(
            label: 'Mood',
            value: mood.toStringAsFixed(1),
            color: moodColor(mood.round()),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: MetricCard(
            label: 'Energy',
            value: energy.toStringAsFixed(1),
            color: Colors.blueGrey,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: MetricCard(
            label: 'Stress',
            value: stress.toStringAsFixed(1),
            color: Colors.deepOrange,
          ),
        ),
        if (hours.isNotEmpty) ...[
          const SizedBox(width: 12),
          Expanded(
            child: MetricCard(
              label: 'Sleep',
              value: (hours.reduce((a, b) => a + b) / hours.length)
                  .toStringAsFixed(1),
              color: Colors.indigo,
            ),
          ),
        ],
      ],
    );
  }
}
