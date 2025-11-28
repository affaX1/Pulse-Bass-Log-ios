import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../utils.dart';
import '../widgets/chart_card.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final entries = state.entries;
    final moodSeries = entries
        .map((e) => ChartPoint(date: e.loggedFor, value: e.mood.toDouble()))
        .toList();
    final energySeries = entries
        .map((e) => ChartPoint(date: e.loggedFor, value: e.energy.toDouble()))
        .toList();
    final stressSeries = entries
        .map((e) => ChartPoint(date: e.loggedFor, value: e.stress.toDouble()))
        .toList();

    final weekdayAverages = <int, List<Entry>>{};
    for (final e in entries) {
      weekdayAverages.putIfAbsent(e.loggedFor.weekday, () => []).add(e);
    }

    final bestWeekday = weekdayAverages.entries.isEmpty
        ? null
        : weekdayAverages.entries
              .map((entry) {
                final avgMood =
                    entry.value.map((e) => e.mood).reduce((a, b) => a + b) /
                    entry.value.length;
                return MapEntry(entry.key, avgMood);
              })
              .reduce((a, b) => a.value >= b.value ? a : b);

    final averageMood = entries.isEmpty
        ? 0
        : entries.map((e) => e.mood).reduce((a, b) => a + b) / entries.length;
    return Scaffold(
      extendBodyBehindAppBar: true,
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
            MediaQuery.of(context).padding.top,
            12,
            24,
          ),
          children: [
            _GlassPanel(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _MetricBubble(
                    label: 'Avg mood',
                    value: averageMood.toStringAsFixed(1),
                    color: moodColor(averageMood.round()),
                  ),
                  _MetricBubble(
                    label: 'Entries',
                    value: '${entries.length}',
                    color: Colors.white,
                  ),
                  _MetricBubble(
                    label: 'Best day',
                    value: bestWeekday != null
                        ? weekdayName(bestWeekday.key)
                        : '—',
                    color: bestWeekday != null ? moodColor(5) : Colors.white70,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _GlassPanel(
              child: ChartCard(
                title: 'Mood over time',
                points: moodSeries,
                color: moodColor(4),
              ),
            ),
            const SizedBox(height: 12),
            _GlassPanel(
              child: ChartCard(
                title: 'Energy over time',
                points: energySeries,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 12),
            _GlassPanel(
              child: ChartCard(
                title: 'Stress over time',
                points: stressSeries,
                color: Colors.deepOrange,
              ),
            ),
            const SizedBox(height: 16),
            _GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick insights',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  if (bestWeekday != null)
                    Text(
                      'Best weekday for mood — ${weekdayName(bestWeekday.key)} (${bestWeekday.value.toStringAsFixed(1)}).',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    'Average mood: ${averageMood.toStringAsFixed(1)}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                  if (entries.isEmpty)
                    Text(
                      'Add entries to unlock more insights.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
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

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});
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

class _MetricBubble extends StatelessWidget {
  const _MetricBubble({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
